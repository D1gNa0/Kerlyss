import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_storage_paths.dart';
import 'log_buffer.dart';
import 'log_sanitizer.dart';

/// If the app crashes BEFORE the window appears, the user only sees "nothing happens".
/// This writes the error to `startup_error.log` and (on Windows) opens it in Notepad.
class StartupGuard {
  StartupGuard._();

  static Future<void> reportFatal(Object error, StackTrace stack) async {
    final text = StringBuffer()
      ..writeln('Kerlyss could not start.')
      ..writeln('Time: ${DateTime.now().toIso8601String()}')
      ..writeln('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln()
      ..writeln('Error: $error')
      ..writeln(stack.toString().split('\n').take(25).join('\n'))
      ..writeln()
      ..writeln('Recent log:')
      ..writeln(LogBuffer.instance.recent(60).join('\n'));
    final cleaned = LogSanitizer.sanitize(text.toString());

    String? path;
    try {
      Directory dir;
      try {
        dir = await AppStoragePaths.appRootDirectory();
      } catch (_) {
        dir = Directory.systemTemp;
      }
      final file = File('${dir.path}${Platform.pathSeparator}startup_error.log');
      await file.writeAsString(cleaned);
      path = file.path;
    } catch (_) {
      try {
        final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}kerlyss_startup_error.log');
        await file.writeAsString(cleaned);
        path = file.path;
      } catch (_) {}
    }

    if (!kIsWeb && Platform.isWindows && path != null) {
      try {
        await Process.start('notepad.exe', [path], mode: ProcessStartMode.detached);
      } catch (_) {}
    }
    exit(1);
  }
}
