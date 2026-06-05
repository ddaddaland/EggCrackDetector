// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Detection _$DetectionFromJson(Map<String, dynamic> json) => Detection(
  absoluteRect: Rect.fromJson(json['absoluteRect'] as Map<String, dynamic>),
  classIndex: (json['classIndex'] as num).toInt(),
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$DetectionToJson(Detection instance) => <String, dynamic>{
  'absoluteRect': instance.absoluteRect,
  'classIndex': instance.classIndex,
  'confidence': instance.confidence,
};
