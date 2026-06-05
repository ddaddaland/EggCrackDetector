// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Domain _$DomainFromJson(Map<String, dynamic> json) => Domain(
  tenantId: json['tenantId'] as String,
  id: json['id'] as String,
  createTime: (json['createTime'] as num).toInt(),
  profile: DomainProfile.fromJson(json['profile'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DomainToJson(Domain instance) => <String, dynamic>{
  'tenantId': instance.tenantId,
  'id': instance.id,
  'createTime': instance.createTime,
  'profile': instance.profile,
};
