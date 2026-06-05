import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class TenantProfile {

  String name;

  TenantProfile({
    required this.name,
  });


  // json

  factory TenantProfile.fromJson(Map<String, dynamic> json) => _$TenantProfileFromJson(json);

  Map<String, dynamic> toJson() => _$TenantProfileToJson(this);


}
