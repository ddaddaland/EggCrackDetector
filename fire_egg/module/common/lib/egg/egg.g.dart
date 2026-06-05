// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'egg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Egg _$EggFromJson(Map<String, dynamic> json) => Egg(
  index: (json['index'] as num).toInt(),
  cracks: (json['cracks'] as List<dynamic>)
      .map((e) => CrackData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EggToJson(Egg instance) => <String, dynamic>{
  'index': instance.index,
  'cracks': instance.cracks,
};
