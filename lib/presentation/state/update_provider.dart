import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/services/app_updater.dart';
import '../../core/services/error_reporter.dart';
import '../../main.dart' show globalAudioHandler;

enum UpdatePhase { idle, checking, available, downloading, verifying, preparing, readyToInstall, error }

enum UpdateCheckResult { upToDate, available, failed }

class UpdateState {
  final UpdatePhase phase;
  final UpdateInfo? info;
  final double progress; // 0..1 while downloading
  final int receivedBytes;
  final int totalBytes;
  final String? message; // error text or a hint

  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.info,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.message,
  });

  bool get isBusy =>
      phase == UpdatePhase.checking ||
      phase == UpdatePhase.downloading ||
      phase == UpdatePhase.verifying ||
      phase == UpdatePhase.preparing;

  bool get showsBanner =>
      phase == UpdatePhase.downloading ||
      phase == UpdatePhase.verifying ||
      phase == UpdatePhase.preparing ||
      phase == UpdatePhase.readyToInstall ||
      phase == UpdatePhase.error;

  UpdateState copyWith({
    UpdatePhase? phase,
    UpdateInfo? info,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? message,
    bool clearMessage = false,
  }) {
    return UpdateState(
      phase: phase ?? this.phase,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final updateProvider = StateNotifierProvider<UpdateController, UpdateState>((ref) => UpdateController());

class UpdateController extends StateNotifier<UpdateState> {
  UpdateController({AppUpdater? updater})
      : _updater = updater ?? AppUpdater(),
        super(const UpdateState());

  final AppUpdater _updater;
  CancelToken? _cancelToken;
  Directory? _windowsSourceDir;
  File? _androidApk;

  /// Looks for a newer version. Never throws.
  Future<UpdateCheckResult> check() async {
    if (state.phase == UpdatePhase.readyToInstall || state.phase == UpdatePhase.available) {
      return UpdateCheckResult.available;
    }
    if (state.isBusy) return UpdateCheckResult.available;

    state = state.copyWith(phase: UpdatePhase.checking, clearMessage: true);
    try {
      final info = await _updater.fetchLatest();
      if (!mounted) return UpdateCheckResult.failed;
      if (info == null) {
        state = const UpdateState();
        return UpdateCheckResult.upToDate;
      }
      state = UpdateState(phase: UpdatePhase.available, info: info);
      return UpdateCheckResult.available;
    } catch (e) {
      debugPrint('Update check failed: $e');
      if (mounted) state = const UpdateState();
      return UpdateCheckResult.failed;
    }
  }

  /// Download -> verify -> (Windows: unpack) -> ready. On Android it then opens the installer.
  Future<void> startUpdate() async {
    final info = state.info;
    if (info == null || state.isBusy || !AppUpdater.supportsInAppUpdate) return;

    final token = _cancelToken = CancelToken();
    try {
      state = UpdateState(phase: UpdatePhase.downloading, info: info);

      await _updater.cleanUp();
      if (Platform.isWindows) await _updater.ensureInstallDirWritable();

      final expectedHash = await _updater.fetchExpectedHash(info.version);
      final workDir = await _updater.workDir();
      final target = File(p.join(workDir.path, AppUpdater.assetName));

      var lastPercent = -1;
      await _updater.download(
        target: target,
        cancelToken: token,
        onProgress: (received, total) {
          if (!mounted || total <= 0) return;
          final percent = (received * 100 ~/ total);
          if (percent == lastPercent) return; // avoid rebuilding the UI thousands of times
          lastPercent = percent;
          state = state.copyWith(progress: received / total, receivedBytes: received, totalBytes: total);
        },
      );

      if (!mounted) return;
      state = state.copyWith(phase: UpdatePhase.verifying);
      if (!await _updater.verifySha256(target, expectedHash)) {
        await _updater.cleanUp();
        throw const UpdateException('The downloaded file is corrupted or was changed. Please try again.');
      }

      if (Platform.isWindows) {
        if (!mounted) return;
        state = state.copyWith(phase: UpdatePhase.preparing);
        _windowsSourceDir = await _updater.extractWindowsZip(target, workDir);
      } else {
        _androidApk = target;
      }

      if (!mounted) return;
      state = state.copyWith(phase: UpdatePhase.readyToInstall, clearMessage: true);

      // Android: go straight to the system installer (one tap there).
      // Windows: wait for the user to press "Restart to update".
      if (Platform.isAndroid) await installNow();
    } on DioException catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) {
        state = UpdateState(phase: UpdatePhase.available, info: info);
      } else {
        _fail('Download failed. Check your connection and try again.');
      }
    } on UpdateException catch (e) {
      if (mounted) _fail(e.message);
    } catch (e) {
      debugPrint('Update failed: $e');
      ErrorReporter.instance.reportLethal(
        kind: 'updater-failed',
        userMessage: 'The in-app update failed unexpectedly.',
        error: e,
      );
      if (mounted) _fail('Update failed. Please try again.');
    }
  }

  void cancel() {
    _cancelToken?.cancel();
  }

  /// Windows: restart into the new version. Android: open the system installer.
  Future<void> installNow() async {
    if (state.phase != UpdatePhase.readyToInstall) return;
    try {
      if (Platform.isWindows) {
        final source = _windowsSourceDir;
        if (source == null) throw const UpdateException('Update files are missing. Please download again.');
        try {
          await globalAudioHandler.stop();
        } catch (_) {}
        await _updater.launchWindowsUpdater(source);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        exit(0);
      } else if (Platform.isAndroid) {
        final apk = _androidApk;
        if (apk == null || !await apk.exists()) {
          throw const UpdateException('Update file is missing. Please download again.');
        }
        final result = await _updater.installAndroid(apk);
        if (!mounted) return;
        state = result == AndroidInstallResult.needsPermission
            ? state.copyWith(message: 'Allow Kerlyss to install apps in the settings screen, then tap Install.')
            : state.copyWith(clearMessage: true);
      }
    } on UpdateException catch (e) {
      if (mounted) _fail(e.message);
    } catch (e) {
      debugPrint('Install failed: $e');
      if (mounted) _fail('Could not start the update. Please try again.');
    }
  }

  void dismissError() {
    final info = state.info;
    state = info == null ? const UpdateState() : UpdateState(phase: UpdatePhase.available, info: info);
  }

  void _fail(String message) {
    state = state.copyWith(phase: UpdatePhase.error, message: message);
  }
}
