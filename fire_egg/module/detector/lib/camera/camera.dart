import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract class AbstractCamera {
  final _imageStreamController = StreamController<Uint8List>.broadcast();
  late final imageStream = _imageStreamController.stream;

  Uint8List? _lastImage;

  Uint8List? get lastImage => _lastImage;

  bool get isCapturing;

  /// 캡처 세션 ID.
  /// [startCapturing]이 새 세션을 성공적으로 시작할 때마다 [beginCaptureSession]을 통해 증가한다.
  /// [CameraPreview] 등 일시적 뷰어가 자신이 시작한 세션과 현재 세션 ID를 비교해
  /// dispose 시 카메라를 잘못 종료하는 것을 방지하는 데 사용한다.
  int _captureSessionId = 0;
  int get captureSessionId => _captureSessionId;

  //
  Future<bool> startCapturing({required int width, required int height, required int fps});

  Future<void> stopCapturing();

  /// 구현체가 새 캡처 세션을 시작할 때 호출한다.
  /// 반환값은 새 세션 ID이다.
  @protected
  int beginCaptureSession() => ++_captureSessionId;

  @protected
  void setLastImage(Uint8List bytes) {
    _lastImage = bytes;
    _imageStreamController.add(bytes);
  }
}
