import 'package:fire_egg_common/capture/result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'process.g.dart';

@JsonSerializable()
class CaptureProcess {
  final int totalImages;
  int processedImages;

  final int startTime;
  final bool hasError;
  CaptureProcessResult? result;

  CaptureProcess({
    this.processedImages = 0,
    required this.totalImages,
    required this.startTime,
    this.hasError = false,
    this.result,
  });

  // json
  factory CaptureProcess.fromJson(Map<String, dynamic> json) => _$CaptureProcessFromJson(json);

  Map<String, dynamic> toJson() => _$CaptureProcessToJson(this);
}
