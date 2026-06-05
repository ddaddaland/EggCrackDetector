import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class DetectorMessage {
  final DateTime timestamp = DateTime.now();
  final MessageType type;
  final String content;

  DetectorMessage({
    required this.type,
    required this.content,
  });
}

enum MessageType {
  error,
  warning,
  info,
  important,
}
