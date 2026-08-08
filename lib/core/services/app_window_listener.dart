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

    Log.i('AppWindowListener: Window close event intercepted. Cleaning up resources before process exit...');

    // Emergency hard fallback: Ensure exit(0) triggers within 1.5s even if async cleanup hangs
    Future.delayed(const Duration(milliseconds: 1500), () {
      exit(0);
    });

    try {
      await YoutubeProxyServer.stop();
    } catch (e) {
      Log.e('AppWindowListener: Error stopping YoutubeProxyServer', e);
    }

    try {
      await globalAudioHandler.stop();
    } catch (e) {
      Log.e('AppWindowListener: Error stopping AudioHandler', e);
    }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await windowManager.destroy();
      } catch (e) {
        Log.e('AppWindowListener: Error destroying windowManager', e);
      }
    }

    exit(0);
  }
}
