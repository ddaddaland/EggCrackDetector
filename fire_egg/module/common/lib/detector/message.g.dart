// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetectorMessage _$DetectorMessageFromJson(Map<String, dynamic> json) =>
    DetectorMessage(
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      content: json['content'] as String,
    );

Map<String, dynamic> _$DetectorMessageToJson(DetectorMessage instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type]!,
      'content': instance.content,
    };

const _$MessageTypeEnumMap = {
  MessageType.error: 'error',
  MessageType.warning: 'warning',
  MessageType.info: 'info',
  MessageType.important: 'important',
};
