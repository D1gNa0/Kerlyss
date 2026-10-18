import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_storage_paths.dart';
import 'logger_service.dart';

/// A fully downloaded and verified update that is waiting to be installed.
/// It is written to disk (see [PendingUpdateStore]) so the update is not lost when the
/// app is closed: Windows installs it on quit or on the next start, Android offers the
/// "Install" button again on the next start.
class PendingUpdate {
  const PendingUpdate({
    required this.version,
    required this.path,
    required this.sha256,
    this.notes = '',
    this.isBeta = false,
    this.tag,
    this.attempts = 0,
  });

  /// How many times the next-start check may try to install this update before giving up
  /// (stops an endless restart loop if the copy keeps failing).
  static const int maxStartupAttempts = 2;

  final String version;

  /// Windows: the folder that holds the unpacked new app (contains the .exe).
  /// Android: the downloaded APK file.
  final String path;

  /// SHA-256 of the downloaded asset (checked again before an Android install).
  final String sha256;
  final String notes;
  final bool isBeta;
  final String? tag;

  /// Startup install attempts so far.
  final int attempts;

  PendingUpdate copyWithAttempts(int value) => PendingUpdate(
        version: version,
        path: path,
        sha256: sha256,
        notes: notes,
        isBeta: isBeta,
        tag: tag,
        attempts: value,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'path': path,
        'sha256': sha256,
        'notes': notes,
        'channel': isBeta ? 'beta' : 'stable',
        'tag': tag,
        'attempts': attempts,
      };

  /// Returns null when [text] is not a valid pending-update file (never throws).
  static PendingUpdate? tryParse(String text) {
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return null;
      final version = data['version'];
      final path = data['path'];
      if (version is! String || version.trim().isEmpty) return null;
      if (path is! String || path.trim().isEmpty) return null;
      final sha = data['sha256'];
      final notes = data['notes'];
      final tag = data['tag'];
      final attempts = data['attempts'];
      return PendingUpdate(
        version: version.trim(),
        path: path,
        sha256: sha is String ? sha : '',
        notes: notes is String ? notes : '',
        isBeta: data['channel'] == 'beta',
        tag: tag is String && tag.isNotEmpty ? tag : null,
        attempts: attempts is int ? attempts : 0,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Reads and writes `pending_update.json` in the app data folder.
class PendingUpdateStore {
  /// [directory] is only for tests; the app uses its normal data folder.
  PendingUpdateStore({Directory? directory}) : _directory = directory;

  static const String fileName = 'pending_update.json';

  final Directory? _directory;

  Future<File> file() async {
    final dir = _directory ?? await AppStoragePaths.appRootDirectory();
    return File(p.join(dir.path, fileName));
  }

  /// Returns true when the file was written. Never throws.
  Future<bool> save(PendingUpdate update) async {
    try {
      final f = await file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(update.toJson()), flush: true);
      return true;
    } catch (e) {
      // Not fatal: the normal "Restart to update" button still works without the file.
      Log.w('Update: could not save ${PendingUpdateStore.fileName}', e);
      return false;
    }
  }

  Future<PendingUpdate?> load() async {
    try {
      final f = await file();
      if (!await f.exists()) return null;
      return PendingUpdate.tryParse(await f.readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final f = await file();
      if (await f.exists()) await f.delete();
    } catch (_) {
      // A leftover file is checked again (and removed) on the next start.
    }
  }
}
