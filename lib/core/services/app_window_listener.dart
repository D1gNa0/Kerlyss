import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'youtube_proxy_server.dart';
import 'logger_service.dart';
import '../../main.dart';

class AppWindowListener extends WindowListener {
  static bool _isExiting = false;

  @override
  void onWindowClose() async {
    if (_isExiting) return;
    _isExiting = true;

    Log.i('AppWindowListener: Window close event intercepted. Instantly closing window...');

    // 1. Instantly hide window from screen so user sees 0 delay
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        windowManager.hide();
      } catch (_) {}
    }

    // 2. Perform parallel unawaited resource cleanup
    YoutubeProxyServer.stop().catchError((e) => Log.e('AppWindowListener: Error stopping proxy', e));
    globalAudioHandler.stop().catchError((e) => Log.e('AppWindowListener: Error stopping handler', e));

    // 3. Hard exit process within 150ms
    Future.delayed(const Duration(milliseconds: 150), () {
      exit(0);
    });
  }
}
