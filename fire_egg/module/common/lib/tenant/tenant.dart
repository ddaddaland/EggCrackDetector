import 'package:fire_egg_common/tenant/profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tenant.g.dart';

@JsonSerializable()
class Tenant {
  final String id;
  TenantProfile profile;

  Tenant({
    required this.id,
    required this.profile,
  });

  // json

  factory Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);

  Map<String, dynamic> toJson() => _$TenantToJson(this);
}
