import 'dart:async';
import 'dart:io';

import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_server/data/sample.dart';
import 'package:fire_egg_server/rest/rest.dart';
import 'package:fire_egg_server/server/server.dart';

final logger = Logger('main');

void main(List<String> args) async {
  logger.info('hello world from fe server (yt)!');
  final _exitCompleter = Completer<int>();

  final server = FireEggServer(
    data: SampleDataProvider(),
  );
  final rest = FireEggServerRest(
    port: 13333,
    server: server,
  );
  rest.start();

  final sigIntSub = ProcessSignal.sigint.watch().listen((signal) async {
    logger.info('SIGINT ${signal} received, disposing app ...');

    await rest.stop();
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(0);
  });

  logger.info('started CLI, now waiting for command or SIGINT');
  final exitCode = await _exitCompleter.future;

  // 5. 자원 정리 (리스너 해제)
  await sigIntSub.cancel();
  logger.info('Relay CLI safely shut down with exit');
}
