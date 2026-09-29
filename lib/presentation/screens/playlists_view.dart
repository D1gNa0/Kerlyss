import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/vercel_hover_button.dart';
import '../../core/services/toast_service.dart';
import '../state/playlist_provider.dart';
import 'playlist_detail_view.dart';
import 'downloaded_songs_view.dart';
import '../state/navigation_provider.dart';
import '../state/track_download_provider.dart';
import '../state/library_provider.dart';
import '../state/download_state_provider.dart';
import '../../domain/entities/playlist_entity.dart';
import '../common/app_dialogs.dart';
import '../state/cloud_sync_provider.dart';

class PlaylistsView extends ConsumerStatefulWidget {
  const PlaylistsView({super.key});

  @override
  ConsumerState<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends ConsumerState<PlaylistsView> {
  PlaylistEntity? _selectedPlaylist;
  bool _showDownloads = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistProvider);

    ref.listen(navigationProvider, (previous, next) {
      if (next == 2) { 
        ref.read(playlistProvider.notifier).loadPlaylists();
        if (_selectedPlaylist != null) setState(() => _selectedPlaylist = null);
        if (_showDownloads) setState(() => _showDownloads = false);
      }
    });

    if (_showDownloads) {
      return DownloadedSongsView(
        onBack: () => setState(() => _showDownloads = false),
      );
    }

    final selectedPlaylist = _selectedPlaylist;
    if (selectedPlaylist != null) {
      return PlaylistDetailView(
        playlist: selectedPlaylist,
        onBack: () {
          setState(() => _selectedPlaylist = null);
          ref.read(playlistProvider.notifier).loadPlaylists();
        },
      );
    }

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.02),
              Colors.transparent,
            ],
          ),
        ),
        child: RefreshIndicator(
          color: AetherColors.accentCyan,
          backgroundColor: AetherColors.ultraDarkGray,
          onRefresh: () async {
            await ref.read(cloudSyncProvider.notifier).syncNow();
            await ref.read(playlistProvider.notifier).loadPlaylists();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            title: Text(
              'PLAYLISTS',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
            ),
            centerTitle: true,
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final syncState = ref.watch(cloudSyncProvider);
                  if (syncState.isSyncing) {
                    return const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AetherColors.accentCyan,
                          ),
                        ),
                      ),
                    );
                  }
                  if (syncState.isConnected) {
                    return AetherIconButton(
                      tooltip: syncState.lastSyncedAt != null
                          ? 'Google Drive Synced - Tap to sync now'
                          : 'Google Drive Connected - Tap to sync now',
                      icon: Icons.cloud_done_rounded,
                      color: AetherColors.accentCyan,
                      size: 18,
                      buttonSize: 36,
                      onPressed: () async {
                        ToastService.show(context, 'Syncing library with Google Drive...');
                        final ok = await ref.read(cloudSyncProvider.notifier).syncNow();
                        if (context.mounted) {
                          ToastService.show(context, ok ? 'Cloud sync complete!' : 'Cloud sync failed.');
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 4),
              AetherIconButton(
                tooltip: 'Downloads',
                icon: Icons.download_for_offline_rounded,
                color: Colors.white,
                size: 18,
                buttonSize: 36,
                onPressed: () => setState(() => _showDownloads = true),
              ),
              const SizedBox(width: 4),
              AetherIconButton(
                tooltip: 'Create Playlist',
                icon: Icons.add_rounded,
                color: Colors.white,
                size: 18,
                buttonSize: 36,
                onPressed: () => _showCreatePlaylistDialog(context, ref),
              ),
              const SizedBox(width: 12),
            ],
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white10)),
            )
          else if (state.playlists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.playlist_add_rounded, color: Colors.white12, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'NO PLAYLISTS YET',
                      style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10),
                    ),
                    const SizedBox(height: 24),
                    ExcludeFocus(
                      child: TextButton(
                        autofocus: false,
                        onPressed: () => _showCreatePlaylistDialog(context, ref),
                        child: const Text('CREATE YOUR FIRST', style: TextStyle(color: AetherColors.primaryAccent)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = state.playlists[index];
                    return _PlaylistTile(
                      playlist: playlist,
                      onSelect: () => setState(() => _selectedPlaylist = playlist),
                    );
                  },
                  childCount: state.playlists.length,
                ),
              ),
            ),
        ],
      ),
      ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    AppDialogs.promptText(
      context,
      title: 'NEW PLAYLIST',
      confirmLabel: 'CREATE',
      hintText: 'Playlist Name',
    ).then((value) {
      if (value != null && value.isNotEmpty) {
        ref.read(playlistProvider.notifier).createPlaylist(value);
      }
    });
  }
}

class _PlaylistTile extends ConsumerWidget {
  final PlaylistEntity playlist;
  final VoidCallback onSelect;
  const _PlaylistTile({required this.playlist, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadStateProvider);
    final libraryState = ref.watch(libraryProvider);
    
    // Check if fully downloaded
    bool allDownloaded = playlist.songIds.isNotEmpty;
    for (final id in playlist.songIds) {
      bool isDownloaded = downloadState.alreadyDownloadedIds.contains(id);
      if (!isDownloaded) {
        final songInLib = libraryState.allSongs.where((s) => s.id == id).firstOrNull;
        if (songInLib != null && songInLib.localPath != null) {
          isDownloaded = true;
        }
      }
      if (!isDownloaded) {
        allDownloaded = false;
        break;
      }
    }

    return VercelHoverButton(
      onTap: onSelect,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(
                  allDownloaded ? Icons.offline_pin_rounded : Icons.playlist_play_rounded, 
                  color: allDownloaded ? AetherColors.success : Colors.white70,
                  size: 28,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AetherIconButton(
                        tooltip: playlist.spotifySourceUrl != null
                            ? (playlist.isRealtimeSynced ? 'Spotify Live Sync Active' : 'Playlist Settings & Sync')
                            : 'Playlist Settings & Downloads',
                        icon: Icons.bolt_rounded,
                        color: (playlist.spotifySourceUrl != null && playlist.isRealtimeSynced)
                            ? Colors.lightGreenAccent
                            : Colors.white70,
                        size: 16,
                        buttonSize: 32,
                        onPressed: () => _showSyncSettings(context, ref, allDownloaded),
                      ),
                      if (playlist.spotifySourceUrl != null && playlist.isRealtimeSynced)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.lightGreenAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.lightGreenAccent.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  AetherIconButton(
                    tooltip: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    color: AetherColors.error,
                    size: 16,
                    buttonSize: 32,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            playlist.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${playlist.songIds.length} TRACKS',
                style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11, letterSpacing: 1),
              ),
              const Spacer(),
              if (allDownloaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AetherColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('DOWNLOADED', style: TextStyle(color: AetherColors.success, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSyncSettings(BuildContext context, WidgetRef ref, bool allDownloaded) {
    bool isSynced = playlist.isRealtimeSynced;
    bool autoDownload = playlist.autoDownloadNewTracks;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final downloadState = ref.watch(downloadStateProvider);
          final isBulkDownloading = downloadState.isBulkActive || downloadState.downloadingTrackIds.isNotEmpty;

          return AlertDialog(
            backgroundColor: AetherColors.ultraDarkGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            title: Text(
              playlist.spotifySourceUrl != null ? 'SPOTIFY & PLAYLIST SETTINGS' : 'PLAYLIST SETTINGS',
              style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width > 420 ? 380 : MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Auto-Download New Songs Toggle (Available for ALL playlists)
                    SwitchListTile(
                      value: autoDownload,
                      activeThumbColor: Colors.cyanAccent,
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.autorenew_rounded, color: Colors.cyanAccent, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Auto-Download New Songs', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      subtitle: const Text('Automatically download tracks added from any device or Spotify for offline playback', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      onChanged: (val) => setDialogState(() => autoDownload = val),
                    ),

                    // 2. Spotify Live Sync Toggle (Only if playlist has Spotify link)
                    if (playlist.spotifySourceUrl != null) ...[
                      const SizedBox(height: 4),
                      SwitchListTile(
                        value: isSynced,
                        activeThumbColor: Colors.lightGreenAccent,
                        contentPadding: EdgeInsets.zero,
                        title: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.lightGreenAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Spotify Live Sync', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        subtitle: const Text('Automatically fetch newly added tracks from Spotify when opening', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        onChanged: (val) => setDialogState(() => isSynced = val),
                      ),
                    ],

                    const Divider(color: Colors.white10, height: 24),

                    // 3. Action Button: Download / Stop / Remove Offline Tracks
                    if (isBulkDownloading)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amberAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.stop_rounded, color: Colors.amberAccent, size: 18),
                          label: const Text(
                            'STOP DOWNLOADING',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          onPressed: () {
                            ref.read(trackDownloadServiceProvider).cancelBulkDownload();
                            Navigator.pop(context);
                            if (context.mounted) {
                              ToastService.show(context, 'Stopping download. Downloaded songs kept.');
                            }
                          },
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: allDownloaded ? AetherColors.error.withValues(alpha: 0.5) : AetherColors.success.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            allDownloaded ? Icons.delete_sweep_rounded : Icons.download_for_offline_rounded,
                            color: allDownloaded ? AetherColors.error : AetherColors.success,
                            size: 18,
                          ),
                          label: Text(
                            allDownloaded ? 'REMOVE DOWNLOADED FILES' : 'DOWNLOAD ALL TRACKS NOW',
                            style: TextStyle(
                              color: allDownloaded ? AetherColors.error : AetherColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            final songs = await ref.read(playlistProvider.notifier).getPlaylistSongs(playlist.id!);
                            if (songs.isNotEmpty) {
                              if (allDownloaded) {
                                for (final song in songs) {
                                  await ref.read(trackDownloadServiceProvider).deleteDownloadedTrack(song);
                                }
                                if (context.mounted) ToastService.show(context, 'Removed downloads for ${playlist.name}');
                              } else {
                                ref.read(trackDownloadServiceProvider).downloadMultiple(songs);
                                if (context.mounted) ToastService.show(context, 'Downloading ${songs.length} tracks for ${playlist.name}...');
                              }
                            }
                          },
                        ),
                      ),

                    // 4. Action Button: Refresh / Quick Sync
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: playlist.spotifySourceUrl != null ? Colors.lightGreenAccent : AetherColors.accentCyan,
                          size: 18,
                        ),
                        label: Text(
                          'REFRESH',
                          style: TextStyle(
                            color: playlist.spotifySourceUrl != null ? Colors.lightGreenAccent : AetherColors.accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          ToastService.show(context, 'Syncing playlist...');
                          if (ref.read(cloudSyncProvider).isConnected) {
                            await ref.read(cloudSyncProvider.notifier).syncNow();
                          }
                          if (playlist.spotifySourceUrl != null && playlist.spotifySourceUrl!.isNotEmpty) {
                            await ref.read(playlistProvider.notifier).syncSpotifyPlaylist(playlist.id!, isManual: true);
                          }
                          await ref.read(playlistProvider.notifier).loadPlaylists();
                          if (context.mounted) {
                            ToastService.show(context, 'Playlist sync complete.');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(playlistProvider.notifier).updatePlaylistSyncSettings(
                        playlist.id!,
                        isRealtimeSynced: isSynced,
                        autoDownloadNewTracks: autoDownload,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('SAVE', style: TextStyle(color: AetherColors.primaryAccent)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    AppDialogs.confirm(
      context,
      title: 'DELETE PLAYLIST',
      content: 'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
      confirmLabel: 'DELETE',
    ).then((confirmed) {
      if (!confirmed) return;
      ref.read(playlistProvider.notifier).deletePlaylist(playlist.id!);
      if (context.mounted) {
        ToastService.show(context, 'Deleted ${playlist.name}');
      }
    });
  }
}
