// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiftSignal _$LiftSignalFromJson(Map<String, dynamic> json) => LiftSignal(
  type: $enumDecode(_$LiftSignalTypeEnumMap, json['type']),
  timestamp: (json['timestamp'] as num).toInt(),
);

Map<String, dynamic> _$LiftSignalToJson(LiftSignal instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'type': _$LiftSignalTypeEnumMap[instance.type]!,
    };

const _$LiftSignalTypeEnumMap = {
  LiftSignalType.eggsElevated: 'eggsElevated',
  LiftSignalType.eggsRotated: 'eggsRotated',
};
