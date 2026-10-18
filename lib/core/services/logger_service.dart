import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'app_storage_paths.dart';
import 'log_buffer.dart';
import 'persistent_log.dart';

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

/// App logging. What goes where:
///
///  | method        | console (debug builds) | log file `kerlyss.log` | bug-report buffer |
///  |---------------|------------------------|------------------------|-------------------|
///  | `Log.t / d`   | yes                    | no                     | no                |
///  | `Log.i`       | yes                    | no                     | yes               |
///  | `Log.event`   | yes                    | YES (all builds)       | yes               |
///  | `Log.w / e / f` | yes                  | YES (all builds)       | yes               |
///
/// Rule of thumb: step-by-step chatter ("resolving song...", "cache hit") is `Log.d`.
/// `Log.event` is for the few things worth knowing later (app start, update steps).
/// `Log.w` = something failed but the app recovers, `Log.e` = a real problem.
class Log {
  static Logger? _logger;

  /// The persistent file. It starts lazily, so it also works before [init].
  static final PersistentLogFile _file = PersistentLogFile(directory: AppStoragePaths.appRootDirectory);

  // `flutter test` sets FLUTTER_TEST: tests must not write into the real app data folder.
  static final bool _underTest = Platform.environment.containsKey('FLUTTER_TEST');

  static void _persist(String level, dynamic message, dynamic error, StackTrace? stackTrace) {
    if (_underTest) return;
    _file.write(level, message.toString(), error: error, stackTrace: stackTrace);
  }

  // Release builds print nothing to the console: reuse ONE silent logger.
  static final Logger _silentLogger = Logger(level: Level.off, printer: _FlatLogPrinter(), output: ConsoleOutput());

  static Logger get _instance {
    if (kReleaseMode) return _silentLogger;
    return _logger ??= Logger(level: Level.debug, printer: _FlatLogPrinter(), output: ConsoleOutput());
  }

  static Future<void> init() async {
    // The old runtime log wrote everything (up to 500 KB of noise). It is replaced by kerlyss.log.
    try {
      final dir = await AppStoragePaths.appRootDirectory();
      final legacy = File('${dir.path}/kerlyss_runtime.log');
      if (await legacy.exists()) await legacy.delete();
    } catch (_) {}
  }

  /// Completes when every queued line is on disk. Call before the process exits.
  static Future<void> flush() => _file.flush();

  /// The newest [count] lines of `kerlyss.log` (it survives app restarts). Used by "Report a Problem".
  static Future<List<String>> recentFileLines(int count) =>
      _underTest ? Future.value(const <String>[]) : _file.tail(count);

  /// Verbose developer detail. Console only, in debug builds.
  static void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.t(message, error: error, stackTrace: stackTrace);
  }

  /// Step-by-step detail. Console only, in debug builds.
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Normal information. Console (debug) and the in-memory bug-report buffer; NOT the file.
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    LogBuffer.instance.add(Level.info, message, error, stackTrace);
    _instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// A key event worth keeping (app start, update steps...). Also written to the log file.
  /// Use sparingly: a few lines per session, never inside a loop.
  static void event(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    LogBuffer.instance.add(Level.info, message, error, stackTrace);
    _instance.i(message, error: error, stackTrace: stackTrace);
    _persist('INFO', message, error, stackTrace);
  }

  /// Something failed but the app recovers. Written to the log file.
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    LogBuffer.instance.add(Level.warning, message, error, stackTrace);
    _instance.w(message, error: error, stackTrace: stackTrace);
    _persist('WARN', message, error, stackTrace);
  }

  /// A real problem. Written to the log file.
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    LogBuffer.instance.add(Level.error, message, error, stackTrace);
    _instance.e(message, error: error, stackTrace: stackTrace);
    _persist('ERROR', message, error, stackTrace);
  }

  /// The app cannot continue. Written to the log file.
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    LogBuffer.instance.add(Level.fatal, message, error, stackTrace);
    _instance.f(message, error: error, stackTrace: stackTrace);
    _persist('FATAL', message, error, stackTrace);
  }
}
