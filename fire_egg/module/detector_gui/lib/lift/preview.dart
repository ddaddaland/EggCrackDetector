import 'dart:async';
import 'package:fire_egg_common/lift/signal.dart';
import 'package:fire_egg_detector/lift/lift.dart';
import 'package:flutter/material.dart';

class LiftPreview extends StatefulWidget {
  final AbstractLift lift;
  final bool pushLift;

  const LiftPreview({
    super.key,
    required this.lift,
    this.pushLift = false,
  });

  @override
  State<LiftPreview> createState() => _LiftPreviewState();
}

class _LiftPreviewState extends State<LiftPreview> {
  late final lift = widget.lift;

  bool startedListeningByThisWidget = false;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    if (!lift.isListening) {
      lift.startListening();
      startedListeningByThisWidget = true;
    }
  }

  @override
  void dispose() {
    if (startedListeningByThisWidget) {
      lift.stopListening();
    }
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      child: StreamBuilder(
        stream: Stream.periodic(Durations.short2),
        builder: (context, asyncSnapshot) {
          if (!lift.isListening) {
            return Icon(Icons.pause, size: 20);
          }

          final now = DateTime.now();
          final lastSignal = lift.lastSignal;
          final elapsed = lastSignal != null ? now.difference(DateTime.fromMillisecondsSinceEpoch(lastSignal.timestamp)) : null;
          final active = elapsed != null && elapsed < const Duration(milliseconds: 200);

          return InkWell(
            onLongPress: active ? null : (){
              lift.emitSignal(
                LiftSignal(
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  type: LiftSignalType.eggsRotated,
                ),
              );
            },
            onTap: active
                ? null
                : () {
                    lift.emitSignal(
                      LiftSignal(
                        timestamp: DateTime.now().millisecondsSinceEpoch,
                        type: LiftSignalType.eggsElevated,
                      ),
                    );
                  },
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.arrow_upward : Icons.arrow_downward,
                  color: active ? Colors.green : Colors.grey,
                  size: active ? 30 : 20,
                ),
                Text(
                  elapsed == null ? '-' : '  ${elapsed.inSeconds % 60}.${(elapsed.inMilliseconds % 1000) ~/ 100}s  ',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
