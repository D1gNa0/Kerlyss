import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/aether_glass.dart';
import '../common/aether_title_bar.dart';
import '../common/vercel_hover_button.dart';
import '../../core/services/toast_service.dart';
import '../state/app_settings_provider.dart';
import '../state/cloud_sync_provider.dart';
import '../state/downloaded_songs_provider.dart';
import '../state/library_provider.dart';
import '../state/playlist_provider.dart';
import '../theme/aether_colors.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  String _formatLastSynced(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('DISCONNECT CLOUD SYNC', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: const Text(
          'Disconnecting from Google Drive will stop automatic sync between your devices. Your local playlists and downloads will remain on this device.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(cloudSyncProvider.notifier).disconnect();
              if (context.mounted) {
                ToastService.show(context, 'Disconnected from Google Drive');
              }
            },
            child: const Text('DISCONNECT', style: TextStyle(color: AetherColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final syncState = ref.watch(cloudSyncProvider);
    final libraryState = ref.watch(libraryProvider);
    final playlistState = ref.watch(playlistProvider);
    final downloadedSongsAsync = ref.watch(downloadedSongsProvider);
    final downloadedCount = downloadedSongsAsync.value?.length ?? 0;
    final settings = ref.watch(appSettingsProvider);

    final isConnected = syncState.isConnected;
    final isSyncing = syncState.isSyncing;
    final userEmail = syncState.userEmail;
    final initialLetter = (userEmail != null && userEmail.isNotEmpty)
        ? userEmail[0].toUpperCase()
        : null;

    return Container(
      color: AetherColors.deepMatteBlack,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: isDesktop ? 40 : 0),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'PROFILE',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 12,
                        letterSpacing: 4,
                        color: Colors.white70,
                      ),
                ),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 1. User Profile Header Card ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isConnected
                                    ? [AetherColors.accentCyan.withValues(alpha: 0.3), Colors.lightGreenAccent.withValues(alpha: 0.2)]
                                    : [Colors.white12, Colors.white10],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isConnected
                                    ? AetherColors.accentCyan.withValues(alpha: 0.5)
                                    : Colors.white24,
                                width: 1.5,
                              ),
                              boxShadow: isConnected
                                  ? [
                                      BoxShadow(
                                        color: AetherColors.accentCyan.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: initialLetter != null
                                  ? Text(
                                      initialLetter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Icon(Icons.person_outline_rounded, size: 36, color: Colors.white54),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            userEmail ?? 'Local Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.lightGreenAccent.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isConnected
                                    ? Colors.lightGreenAccent.withValues(alpha: 0.3)
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isConnected ? Colors.lightGreenAccent : Colors.white38,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isConnected ? 'GOOGLE DRIVE SYNCED' : 'LOCAL STORAGE ONLY',
                                  style: TextStyle(
                                    color: isConnected ? Colors.lightGreenAccent : Colors.white54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- 2. Google Drive Cloud Sync Card ---
                    AetherGlass(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? AetherColors.accentCyan.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.cloud_sync_rounded,
                                  color: isConnected ? AetherColors.accentCyan : Colors.white54,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GOOGLE DRIVE CLOUD SYNC',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isConnected ? 'Connected & syncing' : 'Not connected',
                                      style: TextStyle(
                                        color: isConnected ? Colors.lightGreenAccent : AetherColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isConnected
                                ? 'Your playlists, favorites, and settings automatically synchronize bidirectionally with Google Drive across your mobile and desktop devices.'
                                : 'Connect your Google Drive account to backup your playlists and sync your library seamlessly across all your devices.',
                            style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11, height: 1.4),
                          ),
                          if (isConnected) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.history_rounded, size: 14, color: Colors.white38),
                                const SizedBox(width: 6),
                                Text(
                                  'Last synced: ${_formatLastSynced(syncState.lastSyncedAt)}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                          if (syncState.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AetherColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AetherColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AetherColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      syncState.errorMessage!,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (isConnected)
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: VercelHoverButton(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    accentColor: AetherColors.accentCyan,
                                    borderRadius: 12,
                                    onTap: isSyncing
                                        ? null
                                        : () async {
                                            ToastService.show(context, 'Syncing with Google Drive...');
                                            final ok = await ref.read(cloudSyncProvider.notifier).syncNow();
                                            if (context.mounted) {
                                              ToastService.show(context, ok ? 'Cloud sync complete!' : 'Cloud sync failed.');
                                            }
                                          },
                                    child: Center(
                                      child: isSyncing
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                                                SizedBox(width: 6),
                                                Text('SYNC NOW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AetherColors.error.withValues(alpha: 0.4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => _confirmDisconnect(context, ref),
                                    child: const Text('DISCONNECT', style: TextStyle(color: AetherColors.error, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: VercelHoverButton(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                accentColor: AetherColors.accentCyan,
                                borderRadius: 12,
                                onTap: isSyncing
                                    ? null
                                    : () async {
                                        ToastService.show(context, 'Connecting Google Drive...');
                                        final ok = await ref.read(cloudSyncProvider.notifier).connect();
                                        if (context.mounted) {
                                          ToastService.show(context, ok ? 'Connected to Google Drive!' : 'Sign-in cancelled or failed.');
                                        }
                                      },
                                child: Center(
                                  child: isSyncing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.login_rounded, color: Colors.white, size: 16),
                                            SizedBox(width: 8),
                                            Text('CONNECT GOOGLE DRIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- 3. Library & Storage Analytics Grid ---
                    const Text(
                      'LIBRARY STATS',
                      style: TextStyle(color: AetherColors.textSecondary, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.queue_music_rounded,
                            iconColor: AetherColors.accentCyan,
                            count: playlistState.playlists.length.toString(),
                            label: 'Playlists',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.favorite_rounded,
                            iconColor: AetherColors.error,
                            count: libraryState.favoriteSongs.length.toString(),
                            label: 'Favorites',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.download_done_rounded,
                            iconColor: Colors.lightGreenAccent,
                            count: downloadedCount.toString(),
                            label: 'Offline Tracks',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.library_music_rounded,
                            iconColor: Colors.purpleAccent,
                            count: libraryState.allSongs.length.toString(),
                            label: 'Total Tracks',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 4. App & Storage Info Card ---
                    AetherGlass(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.white38, size: 16),
                              SizedBox(width: 8),
                              Text('KERLYSS AUDIO', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Offline Mode', style: TextStyle(color: AetherColors.textSecondary, fontSize: 11)),
                              Text(settings.isOfflineMode ? 'Enabled' : 'Disabled', style: TextStyle(color: settings.isOfflineMode ? Colors.amberAccent : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('App Version', style: TextStyle(color: AetherColors.textSecondary, fontSize: 11)),
                              Text('v1.0.0 (Aether)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          if (isDesktop) const AetherTitleBar(),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return AetherGlass(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AetherColors.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
