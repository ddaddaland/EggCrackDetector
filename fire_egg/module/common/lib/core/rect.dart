import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

part 'rect.g.dart';

@JsonSerializable()
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  //

  factory Rect.fromLTRB(double left, double top, double right, double bottom) {
    return Rect(left: left, top: top, right: right, bottom: bottom);
  }

  factory Rect.fromLTWH(double left, double top, double width, double height) {
    return Rect(
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
    );
  }

  double centerX() => (left + right) / 2;

  double centerY() => (top + bottom) / 2;

  double centerDistanceTo(Rect other) {
    final dx = centerX() - other.centerX();
    final dy = centerY() - other.centerY();
    return sqrt(dx * dx + dy * dy);
  }

  // json

  factory Rect.fromJson(Map<String, dynamic> json) => _$RectFromJson(json);

  Map<String, dynamic> toJson() => _$RectToJson(this);
}
