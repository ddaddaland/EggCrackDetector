import 'package:fire_egg_common/episode/episode.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class DomainEpisode extends Episode {
  final String domainId;
  final String detectorId;

  DomainEpisode({
    required this.detectorId,
    required this.domainId,
    required super.objectClasses,
    required super.index,
    required super.eggs,
    required super.shots,
    required super.imageSize,
    required super.createTime,
    required super.creating,
    required super.inferred,
    required super.inferenceStatus,
    required super.detections,
    required super.error,
  });

  // json

  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'domainId': domainId,
    'detectorId': detectorId,
  };

  factory DomainEpisode.fromJson(Map<String, dynamic> json) {
    final ep = Episode.fromJson(json);
    return DomainEpisode(
      detectorId: json['detectorId'] as String,
      domainId: json['domainId'] as String,
      objectClasses: ep.objectClasses,
      index: ep.index,
      eggs: ep.eggs,
      shots: ep.shots,
      imageSize: ep.imageSize,
      createTime: ep.createTime,
      creating: ep.creating,
      inferred: ep.inferred,
      inferenceStatus: ep.inferenceStatus,
      detections: ep.detections,
      error: ep.error,
    );
  }
}
