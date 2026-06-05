import 'package:fire_egg_common/domain/domain.dart';
import 'package:fire_egg_common/episode/domain_episode.dart';
import 'package:fire_egg_common/server/connector.dart';
import 'package:fire_egg_common/tenant/tenant.dart';
import 'package:fire_egg_common/util/response.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_widgets/detection/overlay.dart';
import 'package:flutter/material.dart';

class DomainWidget extends StatefulWidget {
  final Tenant tenant;
  final Domain domain;
  final ServerConnector connector;

  const DomainWidget({
    super.key,
    required this.tenant,
    required this.domain,
    required this.connector,
  });

  @override
  State<DomainWidget> createState() => _DomainWidgetState();
}

class _DomainWidgetState extends State<DomainWidget> {
  late final tenant = widget.tenant;
  late final domain = widget.domain;
  late final connector = widget.connector;

  bool busy = false;

  List<DomainEpisode>? episodes;

  void loadEpisodes() async {
    setState(() {
      busy = true;
    });

    final response = await connector.get('/domain/${domain.id}');
    final json = response.bodyJsonIfOk();

    if (json == null) {
      setState(() {
        busy = false;
      });
      return;
    }

    setState(() {
      episodes = (json['episodes'] as List).map((e) => DomainEpisode.fromJson(e)).toList();
      busy = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadEpisodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 7,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.domain),
            Text(domain.profile.name),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadEpisodes,
            icon: Icon(Icons.refresh),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Builder(
          builder: (context) {
            if (busy) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            final episodes = this.episodes;
            if (episodes == null) {
              return Center(child: Icon(Icons.error));
            }

            if (episodes.isEmpty) {
              return Center(child: Text('empty'));
            }

            return ListView.separated(
              itemCount: episodes.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return LightBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('#${episode.index} / ${DateTime.fromMillisecondsSinceEpoch(episode.createTime)}\n검출기 ${episode.detectorId}'),
                      Divider(),
                      LightBox(
                        child: Builder(
                          builder: (context) {
                            if (episode.error != null) {
                              return Center(
                                child: Row(
                                  spacing: 10,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.redAccent, size: 20),
                                    Text(
                                      '${episode.error}',
                                      style: TextStyle(color: Colors.redAccent),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
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
                            );
                          },
                        ),
                      ),
                      Divider(),
                      Builder(
                        builder: (context) {
                          // final cap = episode.captureResult;
                          // if (cap == null) {
                          //   return LightBox(
                          //     child: Center(child: Text('결과 없음')),
                          //   );
                          // }

                          return SizedBox(
                            child: Row(
                              spacing: 6,
                              children: [
                                ...episode.shots.map((shot) {
                                  return LightBox.label(
                                    label: '샷 ${shot.index}',
                                    icon: Icons.image,
                                    child: Row(
                                      children: [
                                        ...shot.images.map((image) {
                                          final detections = episode.detections
                                              .where((det) => det.shotIndex == shot.index && det.cameraIndex == image.cameraIndex)
                                              .toList();

                                          return SizedBox(
                                            height: 150,
                                            width: 150,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.network(
                                                  connector
                                                      .url(
                                                        '/domain/${domain.id}/episode/${episode.index}/shot/${shot.index}/cam/${image.cameraIndex}',
                                                      )
                                                      .toString(),
                                                  fit: BoxFit.cover,
                                                  headers: connector.headers,
                                                ),
                                                if (detections.isNotEmpty)
                                                  DetectionOverlay(
                                                    detections: detections.map((det) => det.detection).toList(),
                                                    classes: episode.objectClasses,
                                                    sourceImageSize: Size.square(episode.imageSize.toDouble()),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
