import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class _FileSysLogOutput extends LogOutput {
  File? file;

  _FileSysLogOutput();

  Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}/kerlyss_runtime.log');
      
      // Print boundary for cold start
      if (await file!.exists()) {
        await file!.writeAsString('\n--- NEW SESSION BOOT ---\n', mode: FileMode.append);
      }
    } catch (e) {
      // If we can't create the file, we fail silently to not break boot
    }
  }

  @override
  void output(OutputEvent event) {
    if (file == null) return;
    
    try {
      final text = event.lines.join('\n') + '\n';
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
      printer: PrettyPrinter(
        methodCount: 2, 
        errorMethodCount: 8, 
        lineLength: 120, 
        colors: true, 
        printEmojis: true, 
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
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
