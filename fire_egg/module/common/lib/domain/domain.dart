import 'package:json_annotation/json_annotation.dart';

import 'profile.dart';

part 'domain.g.dart';

@JsonSerializable()
class Domain {
  final String tenantId, id;
  final int createTime;

  DomainProfile profile;

  Domain({
    required this.tenantId,
    required this.id,
    required this.createTime,
    required this.profile,
  });

  // json

  factory Domain.fromJson(Map<String, dynamic> json) => _$DomainFromJson(json);

  Map<String, dynamic> toJson() => _$DomainToJson(this);
}
