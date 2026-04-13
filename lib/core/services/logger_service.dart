import 'dart:io';
import 'package:logger/logger.dart';
import 'app_storage_paths.dart';

class _FlatLogPrinter extends LogPrinter {
  _FlatLogPrinter();

  @override
  List<String> log(LogEvent event) {
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

    final prefix = '$color$levelStr$reset';
    final lines = <String>['$color$levelStr: ${event.message}$reset'];

    if (event.error != null) {
      lines.add('$color$levelStr ERROR: ${event.error}$reset');
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
    try {
      final logDir = await AppStoragePaths.appRootDirectory();
      file = File('${logDir.path}/kerlyss_runtime.log');
      
      if (await file!.exists()) {
        await file!.writeAsString('\n--- NEW SESSION ---\n', mode: FileMode.append);
      }
    } catch (_) {}
  }

  @override
  void output(OutputEvent event) {
    if (file == null) return;
    
    try {
      // Strip ANSI color codes for file logging
      final ansiRegex = RegExp(r'\x1B\[[0-9;]*m');
      final text = event.lines.map((l) => l.replaceAll(ansiRegex, '')).join('\n') + '\n';
      file!.writeAsStringSync(text, mode: FileMode.append);
    } catch (_) {}
  }
}


class Log {
  static late Logger _logger;
  static late _FileSysLogOutput _fileOutput;

  static Future<void> init() async {
    _fileOutput = _FileSysLogOutput();
    await _fileOutput.init();

    _logger = Logger(
      printer: _FlatLogPrinter(),
      output: MultiOutput([
        ConsoleOutput(),
        _fileOutput,
      ]),
    );
    
    i('Kerlyss Logger Initialized.');
    i('Log file: ${_fileOutput.file?.path ?? "File logging unavailable"}');
  }

  /// Log a message at level [Level.trace].
  static void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.debug].
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.info].
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.warning].
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.error].
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.fatal].
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
