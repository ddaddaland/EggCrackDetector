// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crack_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrackData _$CrackDataFromJson(Map<String, dynamic> json) => CrackData(
  shotIndex: (json['shotIndex'] as num).toInt(),
  box: Rect.fromJson(json['box'] as Map<String, dynamic>),
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$CrackDataToJson(CrackData instance) => <String, dynamic>{
  'box': instance.box,
  'confidence': instance.confidence,
  'shotIndex': instance.shotIndex,
};
