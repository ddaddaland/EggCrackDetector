import 'dart:async';

import 'package:fire_egg_common/lift/signal.dart';
import 'package:fire_egg_detector/lift/lift.dart';

class SampleLift extends AbstractLift {
  final Duration interval;
  Timer? _emitTimer;

  int _signalCount = 0;

  SampleLift({
    required this.interval,
  });

  @override
  bool get isListening => _emitTimer != null;

  @override
  String get description => 'sample lift that emits signal every ${interval.inSeconds} seconds';

  @override
  Future<bool> startListening() async {
    _emitTimer?.cancel();
    _emitTimer = Timer.periodic(interval, (timer) {
      _signalCount += 1;

      emitSignal(
        LiftSignal(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: _signalCount % shotCount == 0 ? LiftSignalType.eggsElevated : LiftSignalType.eggsRotated,
        ),
      );
    });
    return true;
  }

  @override
  Future<void> stopListening() async {
    _emitTimer?.cancel();
    _emitTimer = null;
  }

  @override
  int get shotCount => 2;
}
