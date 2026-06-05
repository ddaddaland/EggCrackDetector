import 'package:fire_egg_common/detector/message.dart';
import 'package:flutter/material.dart';

class DetectorMessageTile extends StatefulWidget {
  final DetectorMessage message;

  const DetectorMessageTile(this.message, {super.key});

  @override
  State<DetectorMessageTile> createState() => _DetectorMessageTileState();
}

class _DetectorMessageTileState extends State<DetectorMessageTile> {
  @override
  Widget build(BuildContext context) {
    final (typeColor, typeIcon) = _getTypeProp(widget.message.type);
    return InkWell(
      borderRadius: BorderRadius.circular(2),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 4,
        ),
        child: Row(
          spacing: 5,
          children: [
            Expanded(
              child: Row(
                spacing: 3,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(typeIcon, color: typeColor, size: 14),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.message.content}',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatTimestamp(widget.message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  static (Color, IconData) _getTypeProp(MessageType type) {
    return switch (type) {
      MessageType.error => (Colors.redAccent, Icons.error),
      MessageType.warning => (Colors.amber, Icons.warning),
      MessageType.info => (Colors.grey, Icons.info),
      MessageType.important => (Colors.greenAccent, Icons.check_circle),
    };
  }
}
