// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptureProcess _$CaptureProcessFromJson(Map<String, dynamic> json) =>
    CaptureProcess(
      processedImages: (json['processedImages'] as num?)?.toInt() ?? 0,
      totalImages: (json['totalImages'] as num).toInt(),
      startTime: (json['startTime'] as num).toInt(),
      hasError: json['hasError'] as bool? ?? false,
      result: json['result'] == null
          ? null
          : CaptureProcessResult.fromJson(
              json['result'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CaptureProcessToJson(CaptureProcess instance) =>
    <String, dynamic>{
      'totalImages': instance.totalImages,
      'processedImages': instance.processedImages,
      'startTime': instance.startTime,
      'hasError': instance.hasError,
      'result': instance.result,
    };
