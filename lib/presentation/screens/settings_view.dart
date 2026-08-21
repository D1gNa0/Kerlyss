import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../state/app_settings_provider.dart';
import '../state/audio_provider.dart';
import '../../core/services/app_storage_paths.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/update_service.dart';
import 'package:path/path.dart' as p;
import '../state/downloaded_songs_provider.dart';
import '../../data/datasources/local/isar_database_service.dart';
import '../../data/repositories/repository_providers.dart';
import 'settings_components/equalizer_dialog.dart';

final defaultDownloadsDirProvider = FutureProvider<Directory>((ref) async {
  return AppStoragePaths.downloadsDirectory();
});

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;
    final downloadsDirAsync = ref.watch(defaultDownloadsDirProvider);
    final settings = ref.watch(appSettingsProvider);
    final String displayPath = settings.customDownloadsPath ??
        downloadsDirAsync.when(
          data: (dir) => dir.path,
          loading: () => 'Loading...',
          error: (_, __) => 'Error loading folder',
        );

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 12,
                letterSpacing: 4,
              ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
        children: [
          if (!kIsWeb && Platform.isWindows) ...[
            const _SettingsSection(
              title: 'PLAYBACK CONTROLS',
              children: [
                _ShortcutTile(label: 'Play / Pause', value: 'Space'),
                _ShortcutTile(label: 'Seek Forward 5s', value: '→ Arrow'),
                _ShortcutTile(label: 'Seek Backward 5s', value: '← Arrow'),
                _ShortcutTile(label: 'Next track', value: 'Ctrl + →'),
                _ShortcutTile(label: 'Previous track', value: 'Ctrl + ←'),
              ],
            ),
            const SizedBox(height: 28),
          ],
          _SettingsSection(
            title: 'NETWORK & OFFLINE',
            children: [
              _SwitchTile(
                label: 'Offline Mode',
                subtitle: 'Show downloaded tracks only & disable online network calls',
                icon: Icons.wifi_off_rounded,
                value: settings.isOfflineMode,
                onChanged: (val) => ref.read(appSettingsProvider.notifier).setOfflineMode(val),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SettingsSection(
            title: 'AUDIO FX & EQUALIZER',
            children: [
              _EqPresetTile(),
            ],
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 28),
            _SettingsSection(
              title: 'APPLICATION',
              children: [
                if (Platform.isWindows || Platform.isMacOS)
                  _SettingsTile(
                    label: 'Window Style', 
                    value: 'Shadow Glass',
                    onTap: () {},
                  ),
                _SettingsTile(
                  label: 'Downloads Folder',
                  value: displayPath,
                  icon: Icons.folder_open_rounded,
                  onTap: () => _pickDirectoryAndChange(context, ref, displayPath),
                  trailingAction: settings.customDownloadsPath != null
                      ? TextButton.icon(
                          onPressed: () => _resetDownloadsDirectoryToDefault(context, ref, displayPath),
                          icon: const Icon(Icons.restart_alt_rounded, size: 14, color: AetherColors.primaryAccent),
                          label: const Text(
                            'RESET',
                            style: TextStyle(
                              color: AetherColors.primaryAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsTile(
                label: 'Support the Developer',
                value: 'Buy me a coffee ☕',
                icon: Icons.favorite_rounded,
                onTap: () => _openUrl('https://www.patreon.com/D1gNa0/posts/support-kerlyss-165742156'),
              ),
              _SettingsTile(
                label: 'Official Website',
                value: 'd1gna0.github.io/Kerlyss',
                icon: Icons.language_rounded,
                onTap: () => _openUrl('https://d1gna0.github.io/Kerlyss/'),
              ),
              _SettingsTile(
                label: 'Developer Instagram',
                value: '@melihkerema',
                icon: Icons.camera_alt_rounded,
                onTap: () => _openUrl('https://www.instagram.com/melihkerema/'),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  return _SettingsTile(
                    label: 'Version', 
                    value: version,
                    icon: Icons.info_outline_rounded,
                    onTap: () {},
                  );
                },
              ),
              _SettingsTile(
                label: 'Check for Updates',
                value: 'Tap to check',
                icon: Icons.system_update_rounded,
                onTap: () => UpdateService().checkForUpdates(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch URL $urlString: $e');
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AetherGlass(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? trailingAction;

  const _SettingsTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final isLongText = value.length > 18;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (isLongText) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!isLongText) ...[
              Text(
                value,
                style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 6),
            ],
            if (trailingAction != null) ...[
              trailingAction!,
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EqPresetTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const EqualizerDialog(),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Equalizer & Audio FX',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              settings.equalizerEnabled ? settings.eqPreset : 'Disabled',
              style: const TextStyle(color: AetherColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String label;
  final String value;

  const _ShortcutTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              value, 
              style: const TextStyle(
                color: AetherColors.accentCyan, 
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _pickDirectoryAndChange(BuildContext context, WidgetRef ref, String currentPath) async {
  try {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && result.isNotEmpty && result != currentPath) {
      await _handleFolderChange(
        context: context,
        ref: ref,
        currentPath: currentPath,
        targetPath: result,
        isReset: false,
      );
    }
  } catch (e) {
    Log.e('Failed to select directory', e);
  }
}

Future<void> _resetDownloadsDirectoryToDefault(BuildContext context, WidgetRef ref, String currentPath) async {
  try {
    AppStoragePaths.customDownloadsPath = null;
    final defaultDir = await AppStoragePaths.downloadsDirectory();
    final defaultPath = defaultDir.path;

    final settings = ref.read(appSettingsProvider);
    AppStoragePaths.customDownloadsPath = settings.customDownloadsPath;

    if (currentPath == defaultPath) {
      await ref.read(appSettingsProvider.notifier).setCustomDownloadsPath(null);
      ref.invalidate(defaultDownloadsDirProvider);
      return;
    }

    await _handleFolderChange(
      context: context,
      ref: ref,
      currentPath: currentPath,
      targetPath: defaultPath,
      isReset: true,
    );
  } catch (e) {
    Log.e('Failed to reset downloads directory', e);
  }
}

Future<void> _handleFolderChange({
  required BuildContext context,
  required WidgetRef ref,
  required String currentPath,
  required String targetPath,
  required bool isReset,
}) async {
  final currentDir = Directory(currentPath);
  final targetDir = Directory(targetPath);

  List<File> audioFiles = [];
  if (await currentDir.exists()) {
    final audioExtensions = {'.mp3', '.m4a', '.flac', '.opus', '.wav', '.aac', '.ogg', '.webm', '.mp4'};
    try {
      audioFiles = await currentDir
          .list(recursive: false)
          .where((e) => e is File && (audioExtensions.contains(p.extension(e.path).toLowerCase()) || p.basename(e.path).startsWith('jamendo_') || p.basename(e.path).startsWith('youtube_')))
          .cast<File>()
          .toList();
    } catch (e) {
      Log.e('Failed to scan current download folder for audio files', e);
    }
  }

  bool shouldMoveFiles = false;
  if (audioFiles.isNotEmpty) {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'MOVE EXISTING DOWNLOADS?',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        content: Text(
          'Do you want to move your ${audioFiles.length} downloaded track(s) from:\n"${currentDir.path}"\n\nto your new folder?\n"${targetDir.path}"',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEEP IN OLD FOLDER', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AetherColors.primaryAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('MOVE FILES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    shouldMoveFiles = result ?? false;
  }

  if (shouldMoveFiles && audioFiles.isNotEmpty) {
    try {
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final pathMap = <String, String>{};
      for (final file in audioFiles) {
        final destPath = p.join(targetDir.path, p.basename(file.path));
        try {
          await file.rename(destPath);
        } catch (_) {
          await file.copy(destPath);
          await file.delete();
        }
        pathMap[file.path] = destPath;
      }

      await ref.read(isarDatabaseServiceProvider).updateMovedFilePaths(pathMap);
      Log.i('Successfully moved ${audioFiles.length} files to $targetPath');
    } catch (e) {
      Log.e('Error moving files to new downloads directory: $e');
    }
  } else if (!shouldMoveFiles && audioFiles.isNotEmpty) {
    // Unlink old directory paths in Isar so the app strictly targets the new downloads folder
    try {
      await ref.read(isarDatabaseServiceProvider).clearLocalPathsInDirectory(currentPath);
      Log.i('Unlinked old local paths in Isar DB for $currentPath');
    } catch (e) {
      Log.e('Error clearing old local paths in Isar DB: $e');
    }
  }

  await ref.read(appSettingsProvider.notifier).setCustomDownloadsPath(isReset ? null : targetPath);
  ref.invalidate(defaultDownloadsDirProvider);
  ref.invalidate(downloadedSongsProvider);
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: value ? AetherColors.accentCyan : Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AetherColors.accentCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

