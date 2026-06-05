import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_common/detection/object_class.dart';
import 'package:flutter/material.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  final List<YoloObjectClass> classes;
  final Size sourceImageSize;
  final double fontSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.classes,
    required this.sourceImageSize,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetectionOverlayPainter(
        fontSize: fontSize,
        detections: detections,
        classes: classes,
        sourceImageSize: sourceImageSize,
      ),
    );
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final List<YoloObjectClass> classes;
  final Size sourceImageSize;
  final double fontSize;

  const _DetectionOverlayPainter({
    required this.detections,
    required this.classes,
    required this.sourceImageSize,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / sourceImageSize.width;
    final scaleY = size.height / sourceImageSize.height;

    for (final detection in detections) {
      final rawRect = detection.absoluteRect;
      final rect = Rect.fromLTRB(
        rawRect.left * scaleX,
        rawRect.top * scaleY,
        rawRect.right * scaleX,
        rawRect.bottom * scaleY,
      );

      if (rect.width <= 0 || rect.height <= 0) {
        continue;
      }

      final cls = detection.classIndex >= 0 && detection.classIndex < classes.length
          ? classes[detection.classIndex]
          : YoloObjectClass(label: 'unknown(${detection.classIndex})', color: 0xFFEEEEEE);

      final color = cls.color;
      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color(cls.color);
      canvas.drawRect(rect, boxPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${cls.label} ${(detection.confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop = (rect.top - textPainter.height - 6).clamp(
        0.0,
        size.height - textPainter.height - 4,
      );
      final labelLeft = rect.left.clamp(0.0, size.width - textPainter.width - 8);
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(labelLeft, labelTop, textPainter.width + 8, textPainter.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        labelRect,
        Paint()..color = Color(cls.color).withAlpha(200),
      );
      textPainter.paint(canvas, Offset(labelLeft + 4, labelTop + 2));
    }
  }

  Color _colorForClassIndex(int classIndex) {
    final hue = (classIndex * 57) % 360;
    return HSVColor.fromAHSV(1, hue.toDouble(), 0.8, 1).toColor();
  }

  @override
  bool shouldRepaint(covariant _DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.classes != classes || oldDelegate.sourceImageSize != sourceImageSize;
  }
}
