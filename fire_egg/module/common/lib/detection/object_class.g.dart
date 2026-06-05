// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YoloObjectClass _$YoloObjectClassFromJson(Map<String, dynamic> json) =>
    YoloObjectClass(
      label: json['label'] as String,
      color: (json['color'] as num).toInt(),
    );

Map<String, dynamic> _$YoloObjectClassToJson(YoloObjectClass instance) =>
    <String, dynamic>{'label': instance.label, 'color': instance.color};
