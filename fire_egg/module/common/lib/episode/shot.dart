import 'dart:typed_data';

import 'package:fire_egg_common/detection/detection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shot.g.dart';

@JsonSerializable()
class Shot {
  final int index;
  final int timestamp;
  final List<ShotImage> images;

  Shot({
    required this.images,
    required this.timestamp,
    required this.index,
  });

  factory Shot.fromJson(Map<String, dynamic> json) => _$ShotFromJson(json);

  Map<String, dynamic> toJson() => _$ShotToJson(this);
}

@JsonSerializable()
class ShotImage {
  final int cameraIndex;
  final List<int> bytes;

  ShotImage({
    required this.cameraIndex,
    required this.bytes,
  });

  factory ShotImage.fromJson(Map<String, dynamic> json) => _$ShotImageFromJson(json);

  Map<String, dynamic> toJson() => _$ShotImageToJson(this);
}
