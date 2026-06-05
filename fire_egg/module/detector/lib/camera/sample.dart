import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:fire_egg_detector/camera/camera.dart';

class SampleCamera extends AbstractCamera {
  final int imageSize;
  final List<Future<Uint8List> Function()> providers;
  late final providersCount = providers.length;

  Timer? _timer;

  SampleCamera({
    required this.imageSize,
    required this.providers,
  });

  @override
  bool get isCapturing => _timer != null;

  @override
  Future<bool> startCapturing({required int width, required int height, required int fps}) async {
    if (width != imageSize || height != imageSize) {
      return false;
    }

    _timer?.cancel();
    _timer = null;

    await Future.delayed(Duration(seconds: 1));

    final Map<int, Uint8List> cache = {};
    for (final provider in providers) {
      final index = providers.indexOf(provider);
      if (!cache.containsKey(index)) {
        cache[index] = await provider();
      }
    }

    _timer = Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (timer) {
      final bytes = cache[Random().nextInt(providersCount)]!;
      setLastImage(bytes);
    });
    beginCaptureSession(); // 새 세션 시작
    return true;
  }

  @override
  Future<void> stopCapturing() async {
    _timer?.cancel();
    _timer = null;
  }
}
