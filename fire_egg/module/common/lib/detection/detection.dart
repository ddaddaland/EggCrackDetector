import 'package:fire_egg_common/core/rect.dart';
import 'package:json_annotation/json_annotation.dart';

part 'detection.g.dart';

@JsonSerializable()
class Detection {
  final Rect absoluteRect;
  final int classIndex;
  final double confidence;

  Detection({
    required this.absoluteRect,
    required this.classIndex,
    required this.confidence,
  });



  factory Detection.fromJson(Map<String, dynamic> json) => _$DetectionFromJson(json);

  Map<String, dynamic> toJson() => _$DetectionToJson(this);
}
