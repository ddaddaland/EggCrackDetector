import 'package:json_annotation/json_annotation.dart';

part 'object_class.g.dart';

@JsonSerializable()
class YoloObjectClass {
  final String label;
  final int color;

  YoloObjectClass({
    required this.label,
    required this.color,
  });

  factory YoloObjectClass.fromJson(Map<String, dynamic> json) => _$YoloObjectClassFromJson(json);

  Map<String, dynamic> toJson() => _$YoloObjectClassToJson(this);
}
