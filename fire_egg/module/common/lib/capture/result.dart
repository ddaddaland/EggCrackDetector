import 'package:fire_egg_common/detection/detection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'result.g.dart';

@JsonSerializable()
class CaptureProcessResult {
  final int timestamp;
  final Map<int, List<Detection>> detectionsByImage;

  CaptureProcessResult({
    required this.timestamp,
    required this.detectionsByImage,
  });

  // json
  factory CaptureProcessResult.fromJson(Map<String, dynamic> json) => _$CaptureProcessResultFromJson(json);

  Map<String, dynamic> toJson() => _$CaptureProcessResultToJson(this);
}
