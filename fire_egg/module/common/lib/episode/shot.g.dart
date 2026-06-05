// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shot _$ShotFromJson(Map<String, dynamic> json) => Shot(
  images: (json['images'] as List<dynamic>)
      .map((e) => ShotImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  timestamp: (json['timestamp'] as num).toInt(),
  index: (json['index'] as num).toInt(),
);

Map<String, dynamic> _$ShotToJson(Shot instance) => <String, dynamic>{
  'index': instance.index,
  'timestamp': instance.timestamp,
  'images': instance.images,
};

ShotImage _$ShotImageFromJson(Map<String, dynamic> json) => ShotImage(
  cameraIndex: (json['cameraIndex'] as num).toInt(),
  bytes: (json['bytes'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$ShotImageToJson(ShotImage instance) => <String, dynamic>{
  'cameraIndex': instance.cameraIndex,
  'bytes': instance.bytes,
};
