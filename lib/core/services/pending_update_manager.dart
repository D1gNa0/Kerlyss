import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import 'app_updater.dart';
import 'pending_update.dart';

/// Makes a downloaded update survive closing the app.
///
/// How it works (same idea as electron-updater's "install on quit" + "install on next launch"):
///  1. When a download is verified, [save] writes `pending_update.json`.
///  2. Windows, app is closed normally -> [applyOnQuit] starts the hidden updater script,
///     which waits for the app to exit, copies the new files, and does NOT restart the app.
///  3. Windows, app was killed / quit hook did not run -> [applyAtStartup] (first thing in
///     `main()`) sees the file, installs the update, and restarts the app.
///  4. Android cannot install silently, so on the next start the controller calls
///     [loadValid] and shows the "Install" button again.
///  5. [loadValid] throws away the file (and the downloaded files) when the update is
///     already installed or the files are gone.
class PendingUpdateManager {
  PendingUpdateManager({PendingUpdateStore? store, AppUpdater? updater})
      : _store = store ?? PendingUpdateStore(),
        _updater = updater ?? AppUpdater();

  static final PendingUpdateManager instance = PendingUpdateManager();

  final PendingUpdateStore _store;
  final AppUpdater _updater;

  Future<void> save(PendingUpdate update) => _store.save(update);

  /// The waiting update, or null. Cleans up when it is stale (already installed, or files missing).
  Future<PendingUpdate?> loadValid() async {
    final pending = await _store.load();
    if (pending == null) return null;

    final current = (await PackageInfo.fromPlatform()).version;
    if (!AppUpdater.isNewerVersion(pending.version, current)) {
      // Already installed (or older than what runs now): remove the leftovers.
      await discard();
      return null;
    }
    if (!_filesExist(pending)) {
      await discard();
      return null;
    }
    return pending;
  }

  /// Forget the waiting update and delete its downloaded files.
  Future<void> discard() async {
    await _store.clear();
    await _updater.cleanUp();
  }

  bool _filesExist(PendingUpdate pending) {
    if (Platform.isWindows) {
      final exeName = p.basename(Platform.resolvedExecutable);
      return File(p.join(pending.path, exeName)).existsSync();
    }
    return File(pending.path).existsSync();
  }

  /// Windows only. Call first thing in `main()`. If a verified update is waiting, this
  /// installs it and restarts the app (the process exits here). On any problem it just
  /// returns, and the app starts normally.
  Future<void> applyAtStartup() async {
    if (!Platform.isWindows) return;
    try {
      final pending = await loadValid();
      if (pending == null) return;

      if (pending.attempts >= PendingUpdate.maxStartupAttempts) {
        // It failed twice already. Stop trying; the user can download again from the app.
        debugPrint('Pending update ${pending.version}: giving up after ${pending.attempts} attempts.');
        await discard();
        return;
      }

      await _updater.ensureInstallDirWritable();

      // Count the attempt BEFORE starting, so a failing update cannot restart the app forever.
      await _store.save(pending.copyWithAttempts(pending.attempts + 1));
      await _updater.launchWindowsUpdater(Directory(pending.path), relaunch: true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
    } catch (e) {
      debugPrint('Applying pending update at startup failed: $e');
    }
  }

  /// Windows only. Call when the user closes the app. If a verified update is waiting, the
  /// hidden updater script installs it right after the app exits (no restart).
  /// Never throws.
  Future<void> applyOnQuit() async {
    if (!Platform.isWindows) return;
    try {
      final pending = await loadValid();
      if (pending == null) return;
      await _updater.ensureInstallDirWritable();
      await _updater.launchWindowsUpdater(Directory(pending.path), relaunch: false);
    } catch (e) {
      debugPrint('Applying pending update on quit failed: $e');
    }
  }
}
