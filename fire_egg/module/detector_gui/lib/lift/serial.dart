import 'dart:async';
import 'dart:typed_data';

import 'package:fire_egg_common/lift/signal.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_detector/lift/lift.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialLift extends AbstractLift {
  final String portName;
  final int baudRate;
  final int captureSignalByte;

  SerialLift({
    required this.portName,
    this.baudRate = 9600,
    this.captureSignalByte = 0x01,
  });

  late final logger = Logger('serial-lift-$portName');

  SerialPort? _serialPort;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;

  @override
  bool get isListening => _serialPort?.isOpen ?? false;

  @override
  String get description =>
      'serial lift on $portName @ ${baudRate}bps '
      '(signal=0x${captureSignalByte.toRadixString(16).padLeft(2, '0').toUpperCase()})';

  @override
  Future<bool> startListening() async {
    if (_serialPort?.isOpen ?? false) {
      logger.warning('serial lift $portName is already listening');
      return true;
    }

    try {
      logger.info('opening serial port $portName @ ${baudRate}bps ...');

      final serialPort = SerialPort(portName);
      if (!serialPort.openReadWrite()) {
        logger.error('failed to open serial port $portName');
        return false;
      }

      // final config = SerialPortConfig()
        // ..baudRate = baudRate
        // ..bits = 8
        // ..parity = SerialPortParity.none
        // ..stopBits = 1;

      // serialPort.config = config;

      final reader = SerialPortReader(serialPort);
      _serialPort = serialPort;
      _reader = reader;

      _sub = reader.stream.listen(
        _onData,
        onError: (e, stt) => logger.error('serial read error on $portName', e, stt),
        onDone: () => logger.warning('serial port $portName stream closed'),
      );

      logger.info('serial port $portName opened successfully');
      return true;
    } catch (e, stt) {
      logger.error('failed to open serial port $portName', e, stt);
      await stopListening();
      return false;
    }
  }

  void _onData(List<int> data) {

    final str = String.fromCharCodes(data);
    logger.info('data received from $portName: $str');

    if(str.contains('1')){
      emitSignal(
        LiftSignal(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: LiftSignalType.eggsElevated, // TODO,
        ),
      );
    }

    if(str.contains('2')){
      emitSignal(
        LiftSignal(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: LiftSignalType.eggsRotated, // TODO,
        ),
      );
    }

  }

  @override
  Future<void> stopListening() async {
    await _sub?.cancel();
    _sub = null;
    _reader = null;
    _serialPort?.close();
    _serialPort = null;
    logger.info('serial port $portName closed');
  }

  @override
  int get shotCount => 2;
}
