import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/theme/aether_theme.dart';
import 'data/datasources/local/isar_database_service.dart';
import 'data/repositories/repository_providers.dart';
import 'presentation/screens/main_shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isarService = IsarDatabaseService();
  await isarService.init();

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
      home: const MainShellView(),
    );
  }
}
