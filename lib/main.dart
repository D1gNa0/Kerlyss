import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'core/services/logger_service.dart';
import 'presentation/theme/aether_theme.dart';
import 'presentation/common/ambient_light_canvas.dart';
import 'data/datasources/local/isar_database_service.dart';
import 'data/repositories/repository_providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kerlyss/l10n/app_localizations.dart';
import 'presentation/screens/main_shell_view.dart';
import 'package:audio_service/audio_service.dart';
import 'core/services/kerlyss_audio_handler.dart';

class AetherHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  }
}

late final KerlyssAudioHandler globalAudioHandler;

void main() async {
  HttpOverrides.global = AetherHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AudioService for background playback
  globalAudioHandler = await AudioService.init<KerlyssAudioHandler>(
    builder: () => KerlyssAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.unexpectedd0.kerlyss.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Android: Enable edge-to-edge transparent UI
  if (!kIsWeb && Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env is optional in local setups; fall back to env vars or dart-define.
  }

  await Log.init();

  final isarService = IsarDatabaseService();
  await isarService.init();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        isarDatabaseServiceProvider.overrideWithValue(isarService),
      ],
      child: const KerlyssApp(),
    ),
  );
}


class KerlyssApp extends StatelessWidget {
  const KerlyssApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kerlyss',
      debugShowCheckedModeBanner: false,
      theme: AetherTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      home: const AmbientLightCanvas(
        child: MainShellView(),
      ),
    );
  }
}
