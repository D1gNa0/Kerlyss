import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
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
            title: Text(
              'PLAYLISTS',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
            ),
            centerTitle: true,
            actions: [
              ExcludeFocus(
                child: TextButton.icon(
                  autofocus: false,
                  onPressed: () => setState(() => _showDownloads = true),
                  icon: const Icon(Icons.download_for_offline_rounded, color: AetherColors.accentCyan, size: 20),
                  label: const Text('DOWNLOADS', style: TextStyle(color: AetherColors.accentCyan, fontSize: 11, letterSpacing: 1)),
                ),
              ),
              ExcludeFocus(
                child: TextButton.icon(
                  autofocus: false,
                  onPressed: () => _showCreatePlaylistDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, color: AetherColors.primaryAccent, size: 20),
                  label: const Text('CREATE', style: TextStyle(color: AetherColors.primaryAccent, fontSize: 11, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = state.playlists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlaylistTile(
                        playlist: playlist,
                        onSelect: () => setState(() => _selectedPlaylist = playlist),
                      ),
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

    return ExcludeFocus(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.white.withValues(alpha: 0.03),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            allDownloaded ? Icons.offline_pin_rounded : Icons.playlist_play_rounded, 
            color: allDownloaded ? AetherColors.primaryAccent : Colors.white24
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                playlist.name,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            if (allDownloaded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AetherColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('DOWNLOADED', style: TextStyle(color: AetherColors.primaryAccent, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(
          '${playlist.songIds.length} TRACKS',
          style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11, letterSpacing: 1),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playlist.spotifySourceUrl != null || playlist.isRealtimeSynced)
              IconButton(
                icon: Icon(
                  Icons.bolt_rounded,
                  color: playlist.isRealtimeSynced ? Colors.amberAccent : Colors.white24,
                  size: 20,
                ),
                onPressed: () => _showSyncSettings(context, ref, allDownloaded),
                tooltip: 'Sync & Download Settings',
              ),
            IconButton(
              icon: Icon(
                allDownloaded ? Icons.check_circle_rounded : Icons.download_for_offline_rounded,
                color: allDownloaded ? Colors.greenAccent : Colors.white54,
                size: 20,
              ),
              onPressed: () async {
                if (allDownloaded) {
                  ToastService.show(context, '${playlist.name} is already downloaded.');
                } else {
                  final songs = await ref.read(playlistProvider.notifier).getPlaylistSongs(playlist.id!);
                  if (songs.isNotEmpty) {
                    await ref.read(trackDownloadServiceProvider).downloadMultiple(songs);
                    await ref.read(playlistProvider.notifier).updatePlaylistSyncSettings(
                      playlist.id!,
                      isRealtimeSynced: playlist.isRealtimeSynced,
                      autoDownloadNewTracks: true,
                    );
                    ToastService.show(context, 'Downloading ${songs.length} tracks for ${playlist.name}...');
                  }
                }
              },
              tooltip: allDownloaded ? 'Downloaded Offline' : 'Download All Tracks',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
              onPressed: () => _confirmDelete(context, ref),
              tooltip: 'Delete Playlist',
            ),
          ],
        ),
        onTap: onSelect,
      ),
    );
  }

  void _showSyncSettings(BuildContext context, WidgetRef ref, bool allDownloaded) {
    bool isSynced = playlist.isRealtimeSynced;
    bool autoDownload = playlist.autoDownloadNewTracks;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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

                  // 3. Action Button: Download / Remove Offline Tracks
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: allDownloaded ? Colors.redAccent.withValues(alpha: 0.5) : AetherColors.accentCyan.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(
                        allDownloaded ? Icons.delete_sweep_rounded : Icons.download_for_offline_rounded,
                        color: allDownloaded ? Colors.redAccent : AetherColors.accentCyan,
                        size: 18,
                      ),
                      label: Text(
                        allDownloaded ? 'REMOVE DOWNLOADED FILES' : 'DOWNLOAD ALL TRACKS NOW',
                        style: TextStyle(
                          color: allDownloaded ? Colors.redAccent : AetherColors.accentCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
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
              child: const Text('SAVE', style: TextStyle(color: Colors.lightGreenAccent)),
            ),
          ],
        ),
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
