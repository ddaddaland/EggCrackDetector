import 'package:json_annotation/json_annotation.dart';

part 'signal.g.dart';

@JsonSerializable()
class LiftSignal {
  final int timestamp;
  final LiftSignalType type;

  LiftSignal({
    required this.type,
    required this.timestamp,
  });

  factory LiftSignal.fromJson(Map<String, dynamic> json) => _$LiftSignalFromJson(json);

  Map<String, dynamic> toJson() => _$LiftSignalToJson(this);
}

enum LiftSignalType {
  eggsElevated,
  eggsRotated,
}
