import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class DomainProfile {
  String name;
  String location;

  DomainProfile({
    required this.name,
    required this.location,
  });

  // json

  factory DomainProfile.fromJson(Map<String, dynamic> json) => _$DomainProfileFromJson(json);

  Map<String, dynamic> toJson() => _$DomainProfileToJson(this);
}
