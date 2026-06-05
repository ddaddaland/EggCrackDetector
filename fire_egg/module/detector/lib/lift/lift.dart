import 'dart:async';

import 'package:fire_egg_common/lift/signal.dart';
import 'package:meta/meta.dart';

abstract class AbstractLift {
  final _signalStreamController = StreamController<LiftSignal>.broadcast();
  late final signalStream = _signalStreamController.stream;

  int get shotCount;

  String get description;

  LiftSignal? _lastSignal;

  LiftSignal? get lastSignal => _lastSignal;

  bool get isListening;

  Future<bool> startListening();
  Future<void> stopListening();


  void emitSignal(LiftSignal signal) {
    _lastSignal = signal;
    _signalStreamController.add(signal);
  }
}
