import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
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
import '../common/vercel_hover_button.dart';

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
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Center(
                child: AetherIconButton(
                  tooltip: 'Home',
                  icon: Icons.grid_view_rounded,
                  size: 18,
                  buttonSize: 36,
                  onPressed: () => ref.read(navigationProvider.notifier).setIndex(0),
                ),
              ),
            ),
            title: Text(
              'PLAYLISTS',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
            ),
            centerTitle: true,
            actions: [
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
                  AetherIconButton(
                    tooltip: 'Sync Settings',
                    icon: Icons.bolt_rounded,
                    color: playlist.isRealtimeSynced ? AetherColors.primaryAccent : Colors.white54,
                    size: 16,
                    buttonSize: 32,
                    onPressed: () => _showSyncSettings(context, ref, allDownloaded),
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
            title: const Text('SYNC & DOWNLOAD SETTINGS', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: MediaQuery.of(context).size.width > 420 ? 380 : MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Real-Time Sync Toggle
                    SwitchListTile(
                      value: isSynced,
                      activeColor: Colors.lightGreenAccent,
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Real-Time Sync', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      subtitle: const Text('Automatically fetch new tracks when opening', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      onChanged: (val) => setDialogState(() => isSynced = val),
                    ),

                    // 2. Auto-Download New Tracks Toggle
                    SwitchListTile(
                      value: autoDownload,
                      activeColor: Colors.cyanAccent,
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
                      subtitle: const Text('Automatically download newly added songs when synced', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      onChanged: (val) => setDialogState(() => autoDownload = val),
                    ),

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
