import 'dart:typed_data';

class CameraImageList {
  final int timestamp;
  final List<CameraImage> images;

  CameraImageList({
    required this.timestamp,
    required this.images,
  });
}

class CameraImage {
  final int cameraIndex;
  final Uint8List bytes;
  final int bytesLength;

  CameraImage({
    required this.cameraIndex,
    required this.bytes,
    required this.bytesLength,
  });
}
