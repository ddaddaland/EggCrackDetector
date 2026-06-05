import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_detector/camera/camera.dart';

class UsbCamera extends AbstractCamera {
  late final logger = Logger('usbcam-$deviceName');
  final String deviceName;
  final int quality;

  UsbCamera({
    required this.deviceName,
    required this.quality,
  });

  Process? _process;
  StreamSubscription? _processSubscription;
  StreamSubscription? _stderrSubscription;
  final List<int> _buffer = [];

  @override
  bool get isCapturing => _process != null;

  @override
  Future<bool> startCapturing({required int width, required int height, required int fps}) async {
    logger.info('starting image stream from camera ${deviceName} with resolution ${width}x${height} at ${fps}fps and quality ${quality}');

    if (_process != null) {
      logger.warning('camera ${deviceName} is already streaming');
      return false; // 이미 스트림이 시작된 경우
    }

    if (!await File(deviceName).exists()) {
      logger.error('camera device ${deviceName} does not exist');
      return false;
    }

    try {
      logger.info('starting process ...');
      final options = [
        '-f',
        'v4l2',
        '-video_size',
        '1280x960',
        '-framerate',
        '5',
        '-input_format',
        'mjpeg',
        '-i',
        '${deviceName}',
        '-vf',
        'crop=960:960:(in_w-960)/2:0,scale=1280:1280',
        '-f',
        'image2pipe',
        '-vcodec',
        'mjpeg',
        '-q:v',
        '${quality}',
        '-',
      ];
      logger.info('starting camera process with options: ${options.join(' ')}');
      final process = await Process.start('ffmpeg', options);
      _process = process;
      logger.info('camera process started with PID ${process.pid}');

      _stderrSubscription = process.stderr.listen((data) {
        logger.error('camera process ${deviceName} stderr: ${String.fromCharCodes(data)}');
      });

      _processSubscription = process.stdout.listen((data) {
        logger.info('received ${data.length} bytes from camera process ${deviceName}');
        _buffer.addAll(data);
        while (true) {
          final jpgEndIndex = _findJpgEnd(_buffer);
          if (jpgEndIndex == -1) {
            break; // JPEG 종료 마커를 찾지 못한 경우, 더 많은 데이터를 기다림
          }
          logger.info('found JPEG end marker at index $jpgEndIndex for camera ${deviceName}');
          final jpgData = _buffer.sublist(0, jpgEndIndex);
          _buffer.removeRange(0, jpgEndIndex); // 처리된 데이터 제거

          setLastImage(Uint8List.fromList(jpgData));
        }
      });

      unawaited(
        process.exitCode.then((code) async {
          logger.warning('camera process ${deviceName} exited with code $code');
          if (!identical(_process, process)) {
            return;
          }

          await _processSubscription?.cancel();
          await _stderrSubscription?.cancel();
          _processSubscription = null;
          _stderrSubscription = null;
          _process = null;
          _buffer.clear();
        }),
      );

      const startupTimeout = Duration(milliseconds: 350);
      const startupSentinel = -9999;
      final startupCode = await process.exitCode.timeout(
        startupTimeout,
        onTimeout: () => startupSentinel,
      );
      if (startupCode != startupSentinel) {
        logger.error('camera process ${deviceName} terminated during startup with code $startupCode');
        return false;
      }
    } catch (e, stt) {
      logger.error('failed to start image stream from camera ${deviceName}', e, stt);
      await stopCapturing();
      return false;
    }

    return true;
  }

  @override
  Future<void> stopCapturing() {
    _processSubscription?.cancel();
    _stderrSubscription?.cancel();
    _process?.kill();
    _processSubscription = null;
    _stderrSubscription = null;
    _process = null;
    _buffer.clear();
    return Future.value();
  }

  static int _findJpgEnd(List<int> buffer) {
    for (int i = 0; i < buffer.length - 1; i++) {
      if (buffer[i] == 0xFF && buffer[i + 1] == 0xD9) {
        return i + 2; // JPEG 종료 마커 위치 반환
      }
    }
    return -1; // JPEG 종료 마커를 찾지 못한 경우
  }
}
