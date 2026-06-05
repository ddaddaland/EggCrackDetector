import 'package:fire_egg_common/episode/episode.dart';
import 'package:fire_egg_detector/detector/detector.dart';
import 'package:fire_egg_detector_gui/camera/preview.dart';
import 'package:fire_egg_detector_gui/capture/tile.dart';
import 'package:fire_egg_detector_gui/capture/widget.dart';
import 'package:fire_egg_detector_gui/detector/message_tile.dart';
import 'package:fire_egg_detector_gui/lift/preview.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_detector_gui/screen/inference/screen.dart';
import 'package:fire_egg_detector_gui/screen/inference_history/screen.dart';
import 'package:fire_egg_detector_gui/screen/models/screen.dart';
import 'package:flutter/material.dart';

class DetectorWidget extends StatefulWidget {
  final DetectorInstance detector;

  const DetectorWidget({
    super.key,
    required this.detector,
  });

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget> {
  //
  late final det = widget.detector;

  // common
  bool messagesExpanded = true;

  void showEpisode(Episode episode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          children: [
            ...episode.detections.map(
              (det) => Column(
                children: [
                  Text('shot ${det.shotIndex} / cam ${det.cameraIndex}'),
                  Text(
                    'class ${det.detection.classIndex}, conf ${det.detection.confidence}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    det.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('검출기 ${det.id}'),
            Row(
              spacing: 5,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 22,
                ),
                Text(
                  '${det.serverOption.displayName}',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 10,
          children: [
            // main area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  SizedBox(
                    height: 120,
                    child: Row(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: LightBox.label(
                            label: '카메라 프리뷰',
                            padding: EdgeInsets.all(10),
                            icon: Icons.camera_alt,
                            child: Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 5,
                                children: [
                                  ...det.cameras.map(
                                    (cam) => CameraPreview(
                                      camera: cam,
                                      imageSize: det.imageSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        LightBox.label(
                          width: 110,
                          label: '리프트',
                          padding: EdgeInsets.all(10),
                          icon: Icons.vertical_align_top,
                          child: Expanded(
                            child: Center(
                              child: LiftPreview(
                                lift: det.lift,
                                pushLift: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LightBox.label(
                      padding: EdgeInsets.all(10),
                      label: '에피소드',
                      icon: Icons.image,
                      child: Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: StreamBuilder(
                            stream: det.episodeStream,
                            builder: (context, _) {
                              final episodes = det.episodes;
                              final episodeCount = episodes.length;

                              if (episodeCount == 0) {
                                return Center(
                                  child: Text('아직 에피소드가 없습니다.'),
                                );
                              }

                              return ListView.separated(
                                itemCount: episodeCount,
                                separatorBuilder: (context, index) => SizedBox(height: 5),
                                itemBuilder: (context, index) {
                                  final episode = episodes[episodeCount - 1 - index];
                                  return EpisodeTile(
                                    key: ValueKey(episode.index),
                                    modelClasses: det.model.classes,
                                    imageSize: det.imageSize,
                                    episode: episode,
                                    stateStream: det.episodeStream,
                                    onTap: () => showEpisode(episode),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // logs
            AnimatedContainer(
              duration: Durations.short4,
              curve: Curves.easeOutQuart,
              height: messagesExpanded ? 250 : 120,
              child: LightBox(
                padding: EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: StreamBuilder(
                        stream: det.messageStream,
                        builder: (context, _) {
                          return ListView.separated(
                            reverse: true,
                            itemCount: det.messages.length,
                            separatorBuilder: (context, index) => SizedBox(height: 0),
                            itemBuilder: (context, index) {
                              final msg = det.messages[det.messages.length - 1 - index];
                              return DetectorMessageTile(msg);
                            },
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(''),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                messagesExpanded = !messagesExpanded;
                              });
                            },
                            icon: Icon(messagesExpanded ? Icons.expand_more : Icons.expand_less),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
