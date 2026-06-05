// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptureProcessResult _$CaptureProcessResultFromJson(
  Map<String, dynamic> json,
) => CaptureProcessResult(
  timestamp: (json['timestamp'] as num).toInt(),
  detectionsByImage: (json['detectionsByImage'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      int.parse(k),
      (e as List<dynamic>)
          .map((e) => Detection.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  ),
);

Map<String, dynamic> _$CaptureProcessResultToJson(
  CaptureProcessResult instance,
) => <String, dynamic>{
  'timestamp': instance.timestamp,
  'detectionsByImage': instance.detectionsByImage.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
};
