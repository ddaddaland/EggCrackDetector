import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fire_egg_common/core/rect.dart';
import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path/path.dart' as p;

/// UI isolate와 분리된 장수명 워커 isolate를 관리한다.
class OnnxInferenceWorker {
  final Logger logger;
  final int imageSize;

  Isolate? _isolate;
  ReceivePort? _receivePort;
  StreamSubscription? _receiveSubscription;
  SendPort? _commandPort;

  final Map<int, Completer<List<Detection>>> _pending = {};
  int _nextRequestId = 0;

  Completer<void>? _readyCompleter;
  Completer<void>? _initializedCompleter;
  Completer<void>? _disposeCompleter;

  OnnxInferenceWorker({
    required this.logger,
    required this.imageSize,
  });

  bool get isRunning => _isolate != null && _commandPort != null;

  Future<void> start({required Uint8List modelBytes}) async {
    if (_isolate != null) {
      return;
    }

    _receivePort = ReceivePort();
    _receiveSubscription = _receivePort!.listen(_onWorkerMessage);
    _readyCompleter = Completer<void>();
    _initializedCompleter = Completer<void>();

    final transferableModel = TransferableTypedData.fromList([modelBytes]);
    _isolate = await Isolate.spawn(
      _onnxWorkerMain,
      [
        _receivePort!.sendPort,
        transferableModel,
        imageSize,
      ],
      debugName: 'fire_egg_onnx_worker',
    );

    await _readyCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('ONNX 워커 포트 연결 시간이 초과되었습니다.');
      },
    );

    await _initializedCompleter!.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('ONNX 워커 모델 초기화 시간이 초과되었습니다.');
      },
    );
  }

  Future<List<Detection>> infer({
    required Uint8List frameBytes,
    required double confidenceThreshold,
  }) async {
    final commandPort = _commandPort;
    if (commandPort == null) {
      throw StateError('ONNX 워커가 초기화되지 않았습니다.');
    }

    final requestId = ++_nextRequestId;
    final completer = Completer<List<Detection>>();
    _pending[requestId] = completer;

    commandPort.send({
      'type': 'infer',
      'id': requestId,
      'threshold': confidenceThreshold,
      'frame': TransferableTypedData.fromList([frameBytes]),
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(requestId);
        throw TimeoutException('추론 응답 시간 초과(id=$requestId)');
      },
    );
  }

  Future<void> dispose() async {
    final isolate = _isolate;
    if (isolate == null) {
      return;
    }

    _disposeCompleter = Completer<void>();
    _commandPort?.send({'type': 'dispose'});

    try {
      await _disposeCompleter!.future.timeout(const Duration(milliseconds: 800));
    } catch (_) {
      // 워커 응답이 없어도 강제 종료로 정리한다.
    }

    for (final entry in _pending.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(StateError('ONNX 워커가 종료되었습니다.'));
      }
    }
    _pending.clear();

    await _receiveSubscription?.cancel();
    _receiveSubscription = null;
    _receivePort?.close();
    _receivePort = null;

    isolate.kill(priority: Isolate.immediate);
    _isolate = null;
    _commandPort = null;
    _readyCompleter = null;
    _initializedCompleter = null;
    _disposeCompleter = null;
  }

  void _onWorkerMessage(dynamic raw) {
    if (raw is! Map) {
      return;
    }

    final type = raw['type'];
    if (type == 'ready') {
      final sendPort = raw['port'];
      if (sendPort is SendPort) {
        _commandPort = sendPort;
        _readyCompleter?.complete();
      }
      return;
    }

    if (type == 'initialized') {
      if (_initializedCompleter != null && !_initializedCompleter!.isCompleted) {
        _initializedCompleter!.complete();
      }
      return;
    }

    if (type == 'result') {
      final requestId = raw['id'];
      if (requestId is! int) {
        return;
      }

      final completer = _pending.remove(requestId);
      if (completer == null || completer.isCompleted) {
        return;
      }

      final detectionsRaw = raw['detections'];
      completer.complete(_decodeDetections(detectionsRaw));
      return;
    }

    if (type == 'error') {
      final requestId = raw['id'];
      final errorMessage = raw['error']?.toString() ?? '알 수 없는 워커 오류';
      final stackTrace = raw['stackTrace']?.toString();

      if (requestId is int) {
        final completer = _pending.remove(requestId);
        if (completer != null && !completer.isCompleted) {
          completer.completeError(StateError(errorMessage), stackTrace == null ? null : StackTrace.fromString(stackTrace));
        }
      } else {
        logger.error('워커 오류: $errorMessage');
      }
      return;
    }

    if (type == 'fatal') {
      final errorMessage = raw['error']?.toString() ?? '워커 초기화 실패';
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.completeError(StateError(errorMessage));
      }
      if (_initializedCompleter != null && !_initializedCompleter!.isCompleted) {
        _initializedCompleter!.completeError(StateError(errorMessage));
      }
      return;
    }

    if (type == 'log') {
      final message = raw['message']?.toString();
      if (message != null && message.isNotEmpty) {
        logger.info('[onnx-worker] $message');
      }
      return;
    }

    if (type == 'disposed') {
      _disposeCompleter?.complete();
    }
  }

  List<Detection> _decodeDetections(dynamic raw) {
    if (raw is! TransferableTypedData) {
      return const <Detection>[];
    }

    final payload = raw.materialize().asFloat32List();
    if (payload.isEmpty) {
      return const <Detection>[];
    }

    // [left, top, right, bottom, classIndex, confidence]를 반복 저장한다.
    const stride = 6;
    final count = payload.length ~/ stride;
    final results = <Detection>[];
    for (int i = 0; i < count; i++) {
      final offset = i * stride;
      final left = payload[offset];
      final top = payload[offset + 1];
      final right = payload[offset + 2];
      final bottom = payload[offset + 3];
      final classIndex = payload[offset + 4].toInt();
      final confidence = payload[offset + 5].toDouble();

      results.add(
        Detection(
          absoluteRect: Rect.fromLTRB(left, top, right, bottom),
          classIndex: classIndex,
          confidence: confidence,
        ),
      );
    }

    return results;
  }
}

Future<void> _onnxWorkerMain(List<dynamic> initArgs) async {
  final mainSendPort = initArgs[0] as SendPort;
  final modelData = initArgs[1] as TransferableTypedData;
  final imageSize = initArgs[2] as int;

  final commandReceivePort = ReceivePort();
  mainSendPort.send({
    'type': 'ready',
    'port': commandReceivePort.sendPort,
  });

  OrtSession? session;
  OrtSessionOptions? sessionOptions;

  try {
    _OrtRuntimeLoader.ensureLoaded();
    OrtEnv.instance.init();

    sessionOptions = OrtSessionOptions();
    final modelBytes = modelData.materialize().asUint8List();
    session = OrtSession.fromBuffer(modelBytes, sessionOptions);

    mainSendPort.send({'type': 'initialized'});
  } catch (e, stt) {
    mainSendPort.send({
      'type': 'fatal',
      'error': '워커 모델 초기화 실패: $e',
      'stackTrace': '$stt',
    });
    session?.release();
    sessionOptions?.release();
    commandReceivePort.close();
    return;
  }

  await for (final raw in commandReceivePort) {
    if (raw is! Map) {
      continue;
    }

    final type = raw['type'];

    if (type == 'infer') {
      final requestId = raw['id'] as int;
      final threshold = (raw['threshold'] as num).toDouble();
      final frameData = raw['frame'] as TransferableTypedData;

      try {
        final frameBytes = frameData.materialize().asUint8List();
        final detections = await _runInference(
          session: session,
          bytes: frameBytes,
          imageSize: imageSize,
          confidenceThreshold: threshold,
        );

        mainSendPort.send({
          'type': 'result',
          'id': requestId,
          'detections': detections,
        });
      } catch (e, stt) {
        mainSendPort.send({
          'type': 'error',
          'id': requestId,
          'error': '추론 실패: $e',
          'stackTrace': '$stt',
        });
      }
      continue;
    }

    if (type == 'dispose') {
      session.release();
      sessionOptions.release();
      commandReceivePort.close();
      mainSendPort.send({'type': 'disposed'});
      break;
    }
  }
}

Future<TransferableTypedData> _runInference({
  required OrtSession session,
  required Uint8List bytes,
  required int imageSize,
  required double confidenceThreshold,
}) async {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw StateError('이미지 디코딩에 실패했습니다.');
  }

  final w = imageSize;
  final h = imageSize;
  final input = Float32List(3 * w * h);

  // 카메라가 비정사각 프레임을 반환할 수 있으므로 중앙 정사각 영역을 기준으로 샘플링한다.
  final cropSide = math.min(image.width, image.height);
  final cropLeft = (image.width - cropSide) ~/ 2;
  final cropTop = (image.height - cropSide) ~/ 2;

  for (int y = 0; y < h; y++) {
    final srcY = cropTop + ((y * cropSide) ~/ h);
    for (int x = 0; x < w; x++) {
      final srcX = cropLeft + ((x * cropSide) ~/ w);
      final p = image.getPixel(srcX, srcY);
      input[y * w + x] = p.r / 255.0;
      input[w * h + y * w + x] = p.g / 255.0;
      input[2 * w * h + y * w + x] = p.b / 255.0;
    }
  }

  final inputTensor = await OrtValueTensor.createTensorWithDataList(input, [1, 3, w, h]);

  final runOptions = OrtRunOptions();

  try {
    final outputs = await session.run(runOptions, {
      'images': inputTensor,
    });

    try {
      final rawOutput = outputs[0]?.value;
      if (rawOutput is! List || rawOutput.isEmpty) {
        return TransferableTypedData.fromList([Float32List(0)]);
      }

      final matrix = rawOutput[0];
      if (matrix is! List) {
        return TransferableTypedData.fromList([Float32List(0)]);
      }

      return _parseYoloV8(
        matrix,
        image.width,
        image.height,
        imageSize,
        confidenceThreshold,
      );
    } finally {
      for (final output in outputs) {
        output?.release();
      }
    }
  } finally {
    runOptions.release();
    inputTensor.release();
  }
}

TransferableTypedData _parseYoloV8(
  List<dynamic> data,
  int imgW,
  int imgH,
  int modelImageSize,
  double confidenceThreshold,
) {
  if (data.length < 5) {
    return TransferableTypedData.fromList([Float32List(0)]);
  }

  final typed = data.map((row) => (row as List).map((v) => (v as num).toDouble()).toList(growable: false)).toList(growable: false);

  final buffer = <double>[];
  final numClasses = typed.length - 4;
  final numPredictions = typed[0].length;

  for (int i = 0; i < numPredictions; i++) {
    double maxScore = 0.0;
    int classId = -1;

    for (int c = 0; c < numClasses; c++) {
      final score = typed[c + 4][i];
      if (score > maxScore) {
        maxScore = score;
        classId = c;
      }
    }

    if (maxScore <= confidenceThreshold) {
      continue;
    }

    final cx = typed[0][i];
    final cy = typed[1][i];
    final w = typed[2][i];
    final h = typed[3][i];

    final x = (cx - w / 2) * (imgW / modelImageSize);
    final y = (cy - h / 2) * (imgH / modelImageSize);
    final width = w * (imgW / modelImageSize);
    final height = h * (imgH / modelImageSize);

    buffer.add(x);
    buffer.add(y);
    buffer.add(x + width);
    buffer.add(y + height);
    buffer.add(classId.toDouble());
    buffer.add(maxScore);
  }

  return TransferableTypedData.fromList([Float32List.fromList(buffer)]);
}

class _OrtRuntimeLoader {
  static bool _loaded = false;

  static void ensureLoaded() {
    if (_loaded || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return;
    }

    final tried = <String>[];
    final errors = <String>[];

    for (final candidate in _candidateLibraryPaths()) {
      if (!File(candidate).existsSync()) {
        tried.add(candidate);
        errors.add('$candidate -> 파일이 존재하지 않음');
        continue;
      }

      if (!_isLibraryArchitectureCompatible(candidate)) {
        tried.add(candidate);
        errors.add(
          '$candidate -> 아키텍처 불일치\n'
          '  시스템 아키텍처: ${_linuxMachine()}\n'
          '  라이브러리 정보: ${_fileCommandOutput(candidate)}\n'
          '  조치: Jetson(aarch64)용 libonnxruntime.so 를 사용해야 합니다.',
        );
        continue;
      }

      try {
        DynamicLibrary.open(candidate);
        _loaded = true;
        return;
      } catch (e) {
        tried.add(candidate);
        final archInfo = Platform.isLinux ? '\n  시스템 아키텍처: ${_linuxMachine()}\n  라이브러리 정보: ${_fileCommandOutput(candidate)}' : '';
        errors.add('$candidate -> $e$archInfo');
      }
    }

    final systemArch = Platform.isLinux ? _linuxMachine() : Platform.operatingSystem;

    throw ArgumentError(
      'ONNX Runtime 동적 라이브러리 로드 실패.\n'
      '현재 시스템 아키텍처: $systemArch\n'
      '시도한 경로:\n- ${tried.join('\n- ')}\n\n'
      '해결 가이드:\n'
      '1) Linux/Jetson: libonnxruntime.so.1.15.1(또는 libonnxruntime.so)를 앱의 bundle/lib에 배치\n'
      '2) 필요 시 FIRE_EGG_ORT_LIB 환경 변수에 절대 경로 지정\n'
      '3) Jetson은 aarch64 빌드 라이브러리를 사용(amd64 파일 사용 불가)\n'
      '4) 실행 전에 LD_LIBRARY_PATH에 라이브러리 경로 추가\n\n'
      '최근 오류:\n- ${errors.take(3).join('\n- ')}',
    );
  }

  static List<String> _candidateLibraryPaths() {
    final names = Platform.isWindows ? const ['onnxruntime.dll'] : const ['libonnxruntime.so.1.15.1', 'libonnxruntime.so'];

    final candidates = <String>[];

    final envPath = Platform.environment['FIRE_EGG_ORT_LIB'];
    if (envPath != null && envPath.trim().isNotEmpty) {
      candidates.add(envPath.trim());
    }

    final exeDir = p.dirname(Platform.resolvedExecutable);
    for (final n in names) {
      candidates.add(p.join(exeDir, 'lib', n));
    }

    final cwd = Directory.current.path;
    for (final n in names) {
      candidates.add(p.join(cwd, 'build', 'linux', 'x64', 'debug', 'bundle', 'lib', n));
      candidates.add(p.join(cwd, 'build', 'linux', 'arm64', 'debug', 'bundle', 'lib', n));
      candidates.add(p.join(cwd, 'build', 'linux', 'x64', 'release', 'bundle', 'lib', n));
      candidates.add(p.join(cwd, 'build', 'linux', 'arm64', 'release', 'bundle', 'lib', n));
      candidates.add(p.join(cwd, 'build', 'windows', 'x64', 'runner', 'Debug', n));
      candidates.add(n);
    }

    if (Platform.isLinux) {
      for (final n in names) {
        candidates.add('/usr/lib/aarch64-linux-gnu/$n');
        candidates.add('/usr/local/lib/$n');
        candidates.add('/opt/onnxruntime/lib/$n');
      }
    }

    return candidates;
  }

  static String _linuxMachine() {
    if (!Platform.isLinux) {
      return Platform.operatingSystem;
    }

    try {
      final result = Process.runSync('uname', ['-m']);
      final stdout = result.stdout.toString().trim();
      if (stdout.isNotEmpty) {
        return stdout;
      }
    } catch (_) {
      // 진단용 보조 정보이므로 실패해도 무시한다.
    }

    return 'unknown';
  }

  static String _fileCommandOutput(String path) {
    if (!Platform.isLinux) {
      return 'file 명령은 Linux에서만 확인합니다.';
    }

    try {
      final result = Process.runSync('file', [path]);
      final stdout = result.stdout.toString().trim();
      if (stdout.isNotEmpty) {
        return stdout;
      }
    } catch (e) {
      return 'file 명령 실행 실패: $e';
    }

    return 'file 명령 출력 없음';
  }

  static bool _isLibraryArchitectureCompatible(String path) {
    if (!Platform.isLinux) {
      return true;
    }

    final output = _fileCommandOutput(path).toLowerCase();
    final machine = _linuxMachine().toLowerCase();

    if (machine.contains('aarch64') || machine.contains('arm64')) {
      if (output.contains('x86-64') || output.contains('intel 80386') || output.contains('x86')) {
        return false;
      }
    }

    if (machine.contains('x86_64') || machine.contains('amd64')) {
      if (output.contains('aarch64') || output.contains('arm64')) {
        return false;
      }
    }

    return true;
  }
}
