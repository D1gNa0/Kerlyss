import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'app_storage_paths.dart';

class _FlatLogPrinter extends LogPrinter {
  _FlatLogPrinter();

  @override
  List<String> log(LogEvent event) {
    if (kReleaseMode) return [];

    final color = switch (event.level) {
      Level.error || Level.fatal => '\x1b[31m', // Red
      Level.warning => '\x1b[33m',             // Yellow
      Level.info => '\x1b[36m',                // Cyan
      Level.debug => '\x1b[32m',               // Green
      _ => '',
    };
    const reset = '\x1b[0m';

    final levelStr = switch (event.level) {
      Level.trace => 'TRACE',
      Level.debug => 'DEBUG',
      Level.info => 'INFO',
      Level.warning => 'WARN',
      Level.error => 'ERROR',
      Level.fatal => 'FATAL',
      _ => 'LOG',
    };

    final messageStr = event.message.toString();
    final truncatedMessage = messageStr.length > 500 ? '${messageStr.substring(0, 500)}...' : messageStr;
    final lines = <String>['$color$levelStr: $truncatedMessage$reset'];

    if (event.error != null) {
      final errorStr = event.error.toString();
      final truncatedError = errorStr.length > 300 ? '${errorStr.substring(0, 300)}...' : errorStr;
      lines.add('$color$levelStr ERROR: $truncatedError$reset');
    }

    if (event.stackTrace != null) {
      lines.add('$color$levelStr STACKTRACE:\n${event.stackTrace}$reset');
    }

    return lines;
  }
}

class _FileSysLogOutput extends LogOutput {
  File? file;

  _FileSysLogOutput();

  Future<void> init() async {
    if (kReleaseMode) return;
    try {
      final logDir = await AppStoragePaths.appRootDirectory();
      file = File('${logDir.path}/kerlyss_runtime.log');
      
      if (await file!.exists()) {
        final length = await file!.length();
        if (length > 500 * 1024) {
          // Truncate log file if > 500KB to save disk space
          await file!.writeAsString('--- LOG TRUNCATED ---\n', mode: FileMode.write);
        } else {
          await file!.writeAsString('\n--- NEW SESSION ---\n', mode: FileMode.append);
        }
      }
    } catch (_) {}
  }

  @override
  void output(OutputEvent event) {
    if (kReleaseMode || file == null) return;
    
    try {
      final ansiRegex = RegExp(r'\x1B\[[0-9;]*m');
      final text = event.lines.map((l) => l.replaceAll(ansiRegex, '')).join('\n') + '\n';
      file!.writeAsString(text, mode: FileMode.append);
    } catch (_) {}
  }
}

class Log {
  static Logger? _logger;
  static _FileSysLogOutput? _fileOutput;

  static Logger get _instance {
    if (kReleaseMode) {
      return Logger(level: Level.off, printer: _FlatLogPrinter(), output: ConsoleOutput());
    }
    _logger ??= Logger(
      level: Level.info,
      printer: _FlatLogPrinter(),
      output: ConsoleOutput(),
    );
    return _logger!;
  }

  static Future<void> init() async {
    if (kReleaseMode) {
      _logger = Logger(level: Level.off, printer: _FlatLogPrinter(), output: ConsoleOutput());
      return;
    }

    _fileOutput = _FileSysLogOutput();
    await _fileOutput!.init();

    _logger = Logger(
      level: Level.info,
      printer: _FlatLogPrinter(),
      output: MultiOutput([
        ConsoleOutput(),
        _fileOutput!,
      ]),
    );
    
    i('Kerlyss Logger Initialized.');
  }

  /// Log a message at level [Level.trace].
  static void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.debug].
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.info].
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.warning].
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.error].
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.fatal].
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.f(message, error: error, stackTrace: stackTrace);
  }
}
