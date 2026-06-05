import 'dart:typed_data';

import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_detector/model/onnx_worker.dart';

/*
 * OnnxYoloModel은 UI isolate에서 직접 추론하지 않고,
 * 장수명(worker) isolate로 프레임을 전달해 백그라운드 추론을 수행한다.
 *
 * - load(): 모델 바이트를 읽고 워커 isolate를 1회 생성
 * - detect(): 프레임을 워커로 전달하고 결과 Future를 반환
 * - unLoad(): 워커 및 네이티브 리소스를 정리
 */

class OnnxYoloModel extends AbstractYoloModel {
  final logger = Logger('onnx', 33);
  final Future<Uint8List> Function() modelLoader;

  OnnxYoloModel({
    super.imageSize,
    required super.parentModel,
    required super.classes,
    required super.name,
    required super.description,
    required this.modelLoader,
  });

  OnnxInferenceWorker? _worker;

  @override
  bool get isLoaded => _worker?.isRunning ?? false;

  @override
  bool get isCloud => false;

  @override
  Future<bool> load() async {
    if (isLoaded) {
      return true;
    }

    final nextWorker = OnnxInferenceWorker(
      logger: logger,
      imageSize: imageSize,
    );

    try {
      final modelBytes = await modelLoader();
      await nextWorker.start(modelBytes: modelBytes);
      _worker = nextWorker;
      return true;
    } catch (e, stt) {
      logger.error('ONNX 워커 초기화 실패', e, stt);
      await nextWorker.dispose();
      _worker = null;
      return false;
    }
  }

  @override
  Future<void> unLoad() async {
    final worker = _worker;
    _worker = null;
    await worker?.dispose();
  }

  @override
  Future<List<Detection>> detect(Uint8List bytes, InferenceOption option) async {
    final worker = _worker;
    if (worker == null) {
      throw Exception('model not loaded yet');
    }

    return worker.infer(
      frameBytes: bytes,
      confidenceThreshold: option.confidenceThreshold,
    );
  }
}
