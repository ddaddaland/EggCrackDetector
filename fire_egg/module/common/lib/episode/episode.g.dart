// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
  createTime: (json['createTime'] as num).toInt(),
  detections: (json['detections'] as List<dynamic>)
      .map((e) => EpisodeDetection.fromJson(e as Map<String, dynamic>))
      .toList(),
  index: (json['index'] as num).toInt(),
  eggs: (json['eggs'] as List<dynamic>)
      .map((e) => Egg.fromJson(e as Map<String, dynamic>))
      .toList(),
  shots: (json['shots'] as List<dynamic>)
      .map((e) => Shot.fromJson(e as Map<String, dynamic>))
      .toList(),
  imageSize: (json['imageSize'] as num).toInt(),
  objectClasses: (json['objectClasses'] as List<dynamic>)
      .map((e) => YoloObjectClass.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'] as String?,
  creating: json['creating'] as bool? ?? false,
  inferred: json['inferred'] as bool? ?? false,
  inferenceStatus: json['inferenceStatus'] == null
      ? null
      : EpisodeInferenceStatus.fromJson(
          json['inferenceStatus'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
  'index': instance.index,
  'createTime': instance.createTime,
  'imageSize': instance.imageSize,
  'eggs': instance.eggs,
  'shots': instance.shots,
  'detections': instance.detections,
  'objectClasses': instance.objectClasses,
  'error': instance.error,
  'creating': instance.creating,
  'inferred': instance.inferred,
  'inferenceStatus': instance.inferenceStatus,
};

EpisodeInferenceStatus _$EpisodeInferenceStatusFromJson(
  Map<String, dynamic> json,
) => EpisodeInferenceStatus(
  startTime: (json['startTime'] as num).toInt(),
  currentCameraIndex: (json['currentCameraIndex'] as num?)?.toInt(),
  currentShotIndex: (json['currentShotIndex'] as num?)?.toInt(),
);

Map<String, dynamic> _$EpisodeInferenceStatusToJson(
  EpisodeInferenceStatus instance,
) => <String, dynamic>{
  'startTime': instance.startTime,
  'currentShotIndex': instance.currentShotIndex,
  'currentCameraIndex': instance.currentCameraIndex,
};

EpisodeDetection _$EpisodeDetectionFromJson(Map<String, dynamic> json) =>
    EpisodeDetection(
      shotIndex: (json['shotIndex'] as num).toInt(),
      cameraIndex: (json['cameraIndex'] as num).toInt(),
      detection: Detection.fromJson(json['detection'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EpisodeDetectionToJson(EpisodeDetection instance) =>
    <String, dynamic>{
      'shotIndex': instance.shotIndex,
      'cameraIndex': instance.cameraIndex,
      'detection': instance.detection,
    };
