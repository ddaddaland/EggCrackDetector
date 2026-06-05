import 'package:fire_egg_common/capture/result.dart';
import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_common/detection/object_class.dart';
import 'package:fire_egg_common/egg/egg.dart';
import 'package:fire_egg_common/episode/shot.dart';
import 'package:json_annotation/json_annotation.dart';

part 'episode.g.dart';

@JsonSerializable()
class Episode {
  final int index;
  final int createTime;
  final int imageSize;
  final List<Egg> eggs;
  final List<Shot> shots;
  final List<EpisodeDetection> detections;
  final List<YoloObjectClass> objectClasses;

  String? error;

  bool creating;
  bool inferred;
  EpisodeInferenceStatus? inferenceStatus;

  Episode({
    required this.createTime,
    required this.detections,
    required this.index,
    required this.eggs,
    required this.shots,
    required this.imageSize,
    required this.objectClasses,
    this.error,
    this.creating = false,
    this.inferred = false,
    this.inferenceStatus = null,
  });

  // json
  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
}

@JsonSerializable()
class EpisodeInferenceStatus {
  final int startTime;
  int? currentShotIndex;
  int? currentCameraIndex;

  EpisodeInferenceStatus({
    required this.startTime,
    this.currentCameraIndex,
    this.currentShotIndex,
  });

  // json
  factory EpisodeInferenceStatus.fromJson(Map<String, dynamic> json) => _$EpisodeInferenceStatusFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeInferenceStatusToJson(this);
}

@JsonSerializable()
class EpisodeDetection {
  final int shotIndex;
  final int cameraIndex;
  final Detection detection;

  EpisodeDetection({
    required this.shotIndex,
    required this.cameraIndex,
    required this.detection,
  });

  // json

  factory EpisodeDetection.fromJson(Map<String, dynamic> json) => _$EpisodeDetectionFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeDetectionToJson(this);
}
