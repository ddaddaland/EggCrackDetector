import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_common/detection/object_class.dart';
import 'package:fire_egg_detector/processor/processor.dart';
import 'package:flutter/material.dart';

class InferenceProcessorWindow extends StatefulWidget {
  final InferenceProcessor processor;

  const InferenceProcessorWindow(this.processor, {super.key});

  @override
  State<InferenceProcessorWindow> createState() => _InferenceProcessorWindowState();
}

class _InferenceProcessorWindowState extends State<InferenceProcessorWindow> {
  late final proc = widget.processor;
  final Map<String, Future<Size>> _imageSizeFutures = {};
  StreamSubscription? _stateSub;

  int? selectedImageIndex;

  Future<Size> _getImageSize(File file) {
    return _imageSizeFutures.putIfAbsent(file.path, () async {
      final bytes = await file.readAsBytes();
      final completer = Completer<Size>();
      ui.decodeImageFromList(bytes, (image) {
        completer.complete(Size(image.width.toDouble(), image.height.toDouble()));
      });
      return completer.future;
    });
  }

  @override
  void initState() {
    super.initState();
    _stateSub = proc.stateStream.listen((n) {
      if (n != null) {
        setState(() {
          selectedImageIndex = n;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stateSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close),
        ),
        title: Text('추론 #${proc.id.toString().padLeft(3, '0')} (${proc.model.name})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          spacing: 5,
          children: [
            // images
            SizedBox(
              width: 200,
              child: StreamBuilder(
                stream: proc.stateStream,
                builder: (context, _) {
                  final processing = proc.processing;
                  return Column(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LightBox(
                        onTap: processing ? null : () => proc.start(),
                        child: Builder(
                          builder: (context) {
                            if (processing) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 5,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  Text('처리 중 (${proc.currentImageIndex}/${proc.imageFilesCount})'),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 5,
                              children: [
                                Icon(Icons.play_arrow),
                                Text('처리 시작'),
                              ],
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: LightBox(
                          padding: EdgeInsets.all(5),
                          child: ListView.separated(
                            itemCount: proc.imageFiles.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 5),
                            itemBuilder: (context, index) {
                              final file = proc.imageFiles[index];
                              return LightBox(
                                height: 70,
                                onTap: () => setState(() => selectedImageIndex = index),
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  spacing: 4,
                                  children: [
                                    SizedBox(
                                      width: 55,
                                      child: Image.file(file),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file.path.split('\\').last,
                                            maxLines: 1,
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final busy = proc.currentImageIndex == index;
                                              if (busy) {
                                                return Row(
                                                  spacing: 5,
                                                  children: [
                                                    SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                    Text('처리 중...'),
                                                  ],
                                                );
                                              }

                                              if (!proc.results.containsKey(index)) {
                                                if (!processing) {
                                                  return Text('${file.lengthSync()}b');
                                                }

                                                return Text(
                                                  '처리 대기 중',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amberAccent,
                                                  ),
                                                );
                                              }

                                              final result = proc.results[index];
                                              if (result != null) {
                                                return Text(
                                                  '${result.length} 객체',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.greenAccent,
                                                  ),
                                                );
                                              }

                                              return Text('처리 실패');
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // view
            Expanded(
              child: LightBox(
                child: StreamBuilder(
                  stream: proc.stateStream,
                  builder: (context, _) {
                    if (selectedImageIndex == null || proc.imageFilesCount <= selectedImageIndex!) {
                      return const Center(
                        child: Text('이미지를 선택해주세요'),
                      );
                    }

                    final file = proc.imageFiles[selectedImageIndex!];
                    final result = proc.results[selectedImageIndex!];

                    return FutureBuilder<Size>(
                      future: _getImageSize(file),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        final imageSize = snapshot.data!;
                        return Center(
                          child: AspectRatio(
                            aspectRatio: imageSize.width / imageSize.height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  file,
                                  fit: BoxFit.fill,
                                ),
                                if (result != null && result.isNotEmpty)
                                  CustomPaint(
                                    painter: _DetectionOverlayPainter(
                                      detections: result,
                                      classes: proc.model.classes,
                                      sourceImageSize: imageSize,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final List<YoloObjectClass> classes;
  final Size sourceImageSize;

  const _DetectionOverlayPainter({
    required this.detections,
    required this.classes,
    required this.sourceImageSize,
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
            fontSize: 11,
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
