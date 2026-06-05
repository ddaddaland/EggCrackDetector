import 'dart:async';
import 'dart:typed_data';

import 'package:fire_egg_common/detection/object_class.dart';
import 'package:fire_egg_common/episode/episode.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_widgets/detection/overlay.dart';
import 'package:flutter/material.dart';

class EpisodeTile extends StatefulWidget {
  final Episode episode;
  final List<YoloObjectClass> modelClasses;
  final int imageSize;
  final Stream? stateStream;
  final void Function()? onTap;

  const EpisodeTile({
    super.key,
    this.onTap,
    this.stateStream,
    required this.modelClasses,
    required this.imageSize,
    required this.episode,
  });

  @override
  State<EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<EpisodeTile> {
  late final episode = widget.episode;

  StreamSubscription? stateSub;

  @override
  void initState() {
    super.initState();
    if (widget.stateStream != null) {
      stateSub = widget.stateStream!.listen((state) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = episode.inferred
        ? episode.error == null
              ? _ProcessState.done
              : _ProcessState.error
        : episode.inferenceStatus == null
        ? _ProcessState.waiting
        : _ProcessState.processing;
    final inference = episode.inferenceStatus;

    return LightBox(
      onTap: widget.onTap,
      child: Row(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (state.busy)
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: state.color,
                        ),
                      ),
                    Row(
                      spacing: 6,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${state.label}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: state.color,
                          ),
                        ),
                        Text(
                          '#${episode.index} / ${DateTime.fromMillisecondsSinceEpoch(episode.createTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(height: 0),

                if (state == _ProcessState.error)
                  Text(
                    '${episode.error}',
                    style: TextStyle(color: Colors.redAccent),
                  ),

                if (state == _ProcessState.done)
                  Row(
                    children: [
                      LightBox(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          spacing: 15,
                          children: [
                            ...episode.eggs.map((egg) {
                              return Column(
                                spacing: 2,
                                children: [
                                  Icon(
                                    Icons.egg,
                                    size: 32,
                                  ),
                                  Text(
                                    egg.cracks.isEmpty ? '정상란' : '크랙 ${egg.cracks.length}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: egg.cracks.isEmpty ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(
            child: Row(
              spacing: 5,
              children: [
                ...episode.shots.map((shot) {
                  return LightBox.label(
                    label: '샷 ${shot.index}',
                    icon: Icons.image,
                    trailing: inference != null && inference.currentShotIndex == shot.index
                        ? SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber,
                            ),
                          )
                        : null,
                    padding: EdgeInsets.all(6),
                    child: Row(
                      spacing: 5,
                      children: [
                        ...shot.images.map((image) {
                          final busy =
                              inference != null &&
                              inference.currentShotIndex == shot.index &&
                              inference.currentCameraIndex == image.cameraIndex;

                          final detections = episode.detections
                              .where((d) => d.shotIndex == shot.index && d.cameraIndex == image.cameraIndex)
                              .toList();

                          return SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  Uint8List.fromList(image.bytes),
                                  gaplessPlayback: true,
                                ),

                                if (busy)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: SizedBox.square(
                                          dimension: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                if (detections.isNotEmpty)
                                  DetectionOverlay(
                                    detections: detections.map((det) => det.detection).toList(),
                                    classes: widget.modelClasses,
                                    sourceImageSize: Size.square(widget.imageSize.toDouble()),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),

                // ...cap.images.map((image) {
                //   return SizedBox(
                //     width: 80,
                //     child: Stack(
                //       fit: StackFit.expand,
                //       children: [
                //         Image.memory(image.bytes),
                //         Positioned(
                //           right: 0,
                //           bottom: 0,
                //           child: Container(
                //             padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                //             color: Colors.black54,
                //             child: Text(
                //               '${image.bytesLength ~/ 1024}KB',
                //               style: TextStyle(color: Colors.white, fontSize: 10),
                //             ),
                //           ),
                //         ),
                //
                //         // processing
                //         if (process != null && process.result == null && process.processedImages == image.index)
                //           Positioned.fill(
                //             child: Container(
                //               color: Colors.black54,
                //               child: Center(
                //                 child: SizedBox.square(
                //                   dimension: 20,
                //                   child: CircularProgressIndicator(
                //                     strokeWidth: 3,
                //                     color: Colors.amber,
                //                   ),
                //                 ),
                //               ),
                //             ),
                //           ),
                //
                //         // processed
                //         if (process != null && process.processedImages > image.index && process.result == null)
                //           Positioned.fill(
                //             child: Container(
                //               color: Colors.black54,
                //               alignment: Alignment.center,
                //               child: Builder(
                //                 builder: (context) {
                //                   return Icon(Icons.check_circle, color: Colors.greenAccent, size: 20);
                //                 },
                //               ),
                //             ),
                //           ),
                //
                //         if (process != null && process.result != null)
                //           Builder(
                //             builder: (context) {
                //               final detections = result?.detectionsByImage[image.index];
                //               if (detections == null) {
                //                 return Icon(Icons.error, color: Colors.redAccent, size: 20);
                //               }
                //
                //               return DetectionOverlay(
                //                 detections: detections,
                //                 fontSize: 9,
                //                 classes: widget.modelClasses,
                //                 sourceImageSize: Size(widget.imageSize.toDouble(), widget.imageSize.toDouble()),
                //               );
                //             },
                //           ),
                //       ],
                //     ),
                //   );
                // }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProcessState {
  waiting(Colors.grey, false, '대기'),
  processing(Colors.amber, true, '추론 중'),
  done(Colors.greenAccent, false, '완료'),
  error(Colors.redAccent, false, '오류');

  final Color color;
  final bool busy;
  final String label;

  const _ProcessState(this.color, this.busy, this.label);
}
