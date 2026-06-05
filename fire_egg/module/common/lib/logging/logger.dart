class Logger {
  final String prefix;

  // https://en.wikipedia.org/wiki/ANSI_escape_code
  Logger(String name, [int color = 15, int nestedLevel = 0])
    : prefix = '\x1B[38;5;${color}m\x1B[1m${repeat(' ', nestedLevel * 2)}${name.padLeft(11, ' ')}$grey$reset';

  void _print(String message, [int color = 252]) {
    print('$prefix \x1B[38;5;${color}m$message$reset');
  }

  void info(String message) {
    _print(message);
  }

  void warning(String message) {
    _print(message, 11);
  }

  void error(String message, [Object? e, StackTrace? stackTrace]) {
    _print(message, 160);
    if (e != null) {
      _print('  Error: ${e}', 160);
    }
    if (stackTrace != null) {
      _print('  StackTrace: ${stackTrace.toString()}', 160);
    }
  }

  void logFromShelf(String message, bool isError) {
    if (isError) {
      error(message);
    } else {
      info(message);
    }
  }

  static String repeat(String str, int times) => List.filled(times, str).join();

  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String grey = '\x1B[90m';
}
