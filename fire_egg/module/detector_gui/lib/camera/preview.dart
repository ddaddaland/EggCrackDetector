import 'package:fire_egg_detector/camera/camera.dart';
import 'package:fire_egg_detector/core.dart';
import 'package:flutter/material.dart';

class CameraPreview extends StatefulWidget {
  final AbstractCamera camera;
  final int imageSize;

  CameraPreview({
    super.key,
    required this.camera,
    required this.imageSize,
  });

  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  late final cam = widget.camera;

  bool busy = false;
  bool error = false;

  bool isCaptureStartedByThisWidget = false;

  @override
  void initState() {
    super.initState();
    if (!cam.isCapturing) {
      isCaptureStartedByThisWidget = true;
      busy = true;
      cam.startCapturing(width: widget.imageSize, height: widget.imageSize, fps: 2).then((success) {
        if (!mounted) {
          return;
        }
        setState(() {
          error = !success;
          busy = false;
        });
      });
    }
  }

  @override
  void dispose() {
    // 시작 화면 -> 실행 화면 전환 시에는 같은 카메라 인스턴스를 계속 사용하므로 중간 stop을 막는다.
    if (isCaptureStartedByThisWidget && !DetectorCore.started) {
      cam.stopCapturing();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Center(child: CircularProgressIndicator());
    }

    if (error) {
      return Center(child: Icon(Icons.error));
    }

    return StreamBuilder(
      stream: cam.imageStream,
      builder: (context, asyncSnapshot) {
        final lastImage = cam.lastImage;
        if (lastImage == null) {
          return Center(child: Icon(Icons.image_not_supported));
        }
        return Stack(
          children: [
            Image.memory(
              lastImage,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
            Positioned(
              bottom: 3,
              right: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  ' ${lastImage.length ~/ 1024} KB ',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
