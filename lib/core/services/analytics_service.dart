import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'app_storage_paths.dart';
import 'logger_service.dart';

/// Lightweight release-only app usage & retention tracker.
/// Guarded strictly by `kReleaseMode` to ensure dev testing runs are ignored.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;
  String? _installId;

  /// Tracks app launch event in release builds only.
  Future<void> logAppOpen() async {
    // Strictly ignore debug and profile builds during dev testing
    if (!kReleaseMode) {
      Log.i('AnalyticsService: Debug mode detected — skipping app_open telemetry');
      return;
    }

    try {
      if (!_initialized) {
        await _init();
      }

      final logFile = await _getAnalyticsLogFile();
      final logEntry = {
        'event': 'app_open',
        'install_id': _installId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'platform': Platform.operatingSystem,
      };

      await logFile.writeAsString(
        '${jsonEncode(logEntry)}\n',
        mode: FileMode.append,
        flush: true,
      );

      Log.i('AnalyticsService: Logged release app_open event (Install ID: $_installId)');
    } catch (e, stackTrace) {
      Log.e('AnalyticsService: Failed to log app_open event: $e', e, stackTrace);
    }
  }

  Future<void> _init() async {
    final storageDir = await AppStoragePaths.appRootDirectory();
    final idFile = File(p.join(storageDir.path, 'installation_id.txt'));

    if (await idFile.exists()) {
      _installId = (await idFile.readAsString()).trim();
    }

    if (_installId == null || _installId!.isEmpty) {
      _installId = _generateUuid();
      await idFile.writeAsString(_installId!);
    }

    _initialized = true;
  }

  Future<File> _getAnalyticsLogFile() async {
    final storageDir = await AppStoragePaths.appRootDirectory();
    return File(p.join(storageDir.path, 'analytics_events.jsonl'));
  }

  String _generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now % 1000000).toString().padLeft(6, '0');
    return 'krly_inst_${now}_$rand';
  }
}
