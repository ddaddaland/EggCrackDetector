import 'package:json_annotation/json_annotation.dart';
import 'crack_data.dart';

part 'egg.g.dart';

@JsonSerializable()
class Egg {
  final int index;
  final List<CrackData> cracks;

  Egg({
    required this.index,
    required this.cracks,
  });

  factory Egg.fromJson(Map<String, dynamic> json) => _$EggFromJson(json);

  Map<String, dynamic> toJson() => _$EggToJson(this);
}
