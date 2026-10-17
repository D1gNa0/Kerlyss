import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'pending_update_manager.dart';
import 'youtube_proxy_server.dart';
import 'logger_service.dart';
import '../../main.dart';

class AppWindowListener extends WindowListener {
  static bool _isExiting = false;

  @override
  void onWindowClose() async {
    if (_isExiting) return;
    _isExiting = true;

    Log.d('AppWindowListener: Window close event intercepted. Instantly closing window...');

    // 1. Instantly hide window from screen so user sees 0 delay
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        windowManager.hide();
      } catch (_) {}
    }

    // 2. Perform parallel unawaited resource cleanup
    YoutubeProxyServer.stop().catchError((e) => Log.e('AppWindowListener: Error stopping proxy', e));
    globalAudioHandler.stop().catchError((e) => Log.e('AppWindowListener: Error stopping handler', e));

    // 3. If an update was downloaded and is waiting, let the hidden updater script install it
    // right after we exit ("install on quit"). The window is already hidden, so the user
    // sees nothing. Capped at 3 seconds so closing can never hang.
    try {
      await PendingUpdateManager.instance.applyOnQuit().timeout(const Duration(seconds: 3));
    } catch (e) {
      Log.e('AppWindowListener: Error preparing update on quit', e);
    }

    // Make sure the last log lines (for example the update step) reach the disk.
    await Log.flush().timeout(const Duration(seconds: 1), onTimeout: () {});

    // 4. Hard exit process within 150ms
    Future.delayed(const Duration(milliseconds: 150), () {
      exit(0);
    });
  }
}
