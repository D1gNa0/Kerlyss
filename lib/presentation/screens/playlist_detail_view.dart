import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/aether_song_tile.dart';
import '../state/audio_state.dart';
import '../theme/aether_colors.dart';
import '../state/playlist_provider.dart';
import '../state/audio_provider.dart';
import '../state/library_provider.dart';
import '../state/track_download_provider.dart';
import '../state/download_state_provider.dart';
import '../../domain/entities/song_entity.dart';
import '../common/mini_player.dart';
import '../../domain/entities/playlist_entity.dart';
import '../common/app_dialogs.dart';
import '../../core/services/toast_service.dart';

class PlaylistDetailView extends ConsumerStatefulWidget {
  final PlaylistEntity playlist;
  final VoidCallback? onBack;
  const PlaylistDetailView({super.key, required this.playlist, this.onBack});

  @override
  ConsumerState<PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends ConsumerState<PlaylistDetailView> {
  List<SongEntity>? _loadedSongs;
  bool _isLoading = true;
  bool _isSyncing = false;
  late String _playlistName;

  @override
  void initState() {
    super.initState();
    _playlistName = widget.playlist.name;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    // Background live diffing for synced Spotify playlists
    ref.read(playlistProvider.notifier).syncSpotifyPlaylist(widget.playlist.id!).then((_) {
      if (mounted) _reloadSongsFromDb();
    });

    await _reloadSongsFromDb();
  }

  Future<void> _reloadSongsFromDb() async {
    final songs = await ref.read(playlistProvider.notifier).getPlaylistSongs(widget.playlist.id!);
    if (mounted) {
      // Sort: Newest First to match library sorting
      songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      setState(() {
        _loadedSongs = songs;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerManualSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    ToastService.show(context, 'Syncing with Spotify...');
    final hasNew = await ref.read(playlistProvider.notifier).syncSpotifyPlaylist(widget.playlist.id!, isManual: true);

    if (mounted) {
      await _reloadSongsFromDb();
      setState(() => _isSyncing = false);
      if (hasNew) {
        ToastService.show(context, 'Found and added new tracks!');
      } else {
        ToastService.show(context, 'Playlist is up to date.');
      }
    }
  }

  void _showSyncSettingsDialog(BuildContext context, PlaylistEntity currentPlaylist) {
    bool isSynced = currentPlaylist.isRealtimeSynced;
    bool autoDownload = currentPlaylist.autoDownloadNewTracks;

    int notDownloadedCount = 0;
    if (_loadedSongs != null) {
      final downloadState = ref.read(downloadStateProvider);
      final libraryState = ref.read(libraryProvider);
      for (final song in _loadedSongs!) {
        final songInLib = libraryState.allSongs.where((s) => s.id == song.id).firstOrNull;
        final hasLocalPath = songInLib != null ? songInLib.localPath != null : song.localPath != null;
        final isDownloaded = hasLocalPath || downloadState.alreadyDownloadedIds.contains(song.id);
        if (!isDownloaded) notDownloadedCount++;
      }
    }
    final allDownloaded = _loadedSongs != null && _loadedSongs!.isNotEmpty && notDownloadedCount == 0;

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

                  // 3. Action Button: Download / Stop / Remove Offline Tracks
                  if (ref.watch(downloadStateProvider).isBulkActive || ref.watch(downloadStateProvider).downloadingTrackIds.isNotEmpty)
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
                          if (mounted) ToastService.show(context, 'Stopping download. Downloaded songs kept.');
                        },
                      ),
                    )
                  else
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
                          final songs = _loadedSongs;
                          Navigator.pop(context);
                          if (songs != null && songs.isNotEmpty) {
                            if (allDownloaded) {
                              for (final song in songs) {
                                await ref.read(trackDownloadServiceProvider).deleteDownloadedTrack(song);
                              }
                              if (mounted) ToastService.show(context, 'Removed downloads for ${currentPlaylist.name}');
                            } else {
                              ref.read(trackDownloadServiceProvider).downloadMultiple(songs);
                              if (mounted) ToastService.show(context, 'Downloading ${songs.length} tracks...');
                            }
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 4. Action Button: Sync / Refresh Now
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent, size: 18),
                      label: const Text('SYNC / REFRESH NOW', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      onPressed: () {
                        Navigator.pop(context);
                        _triggerManualSync();
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
                      widget.playlist.id!,
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

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadStateProvider);
    final libraryState = ref.watch(libraryProvider);
    final playlistState = ref.watch(playlistProvider);
    
    final currentPlaylist = playlistState.playlists.firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => widget.playlist,
    );

    int notDownloadedCount = 0;
    if (_loadedSongs != null) {
      for (final song in _loadedSongs!) {
        final songInLib = libraryState.allSongs.where((s) => s.id == song.id).firstOrNull;
        final hasLocalPath = songInLib != null ? songInLib.localPath != null : song.localPath != null;
        final isDownloaded = hasLocalPath || downloadState.alreadyDownloadedIds.contains(song.id);
        if (!isDownloaded) notDownloadedCount++;
      }
    }
    
    final allDownloaded = _loadedSongs != null && _loadedSongs!.isNotEmpty && notDownloadedCount == 0;

    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      extendBody: true, // Allow body to flow under translucent elements
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        title: Text(
          _playlistName.toUpperCase(),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 14,
            letterSpacing: 4,
            color: Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (currentPlaylist.spotifySourceUrl != null) ...[
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
              onPressed: _isSyncing ? null : _triggerManualSync,
              tooltip: 'Sync / Refresh Now',
            ),
            IconButton(
              icon: Icon(
                Icons.bolt_rounded,
                color: currentPlaylist.isRealtimeSynced ? Colors.amberAccent : Colors.white24,
                size: 20,
              ),
              onPressed: () => _showSyncSettingsDialog(context, currentPlaylist),
              tooltip: 'Sync Settings',
            ),
          ],
          if (allDownloaded)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
              child: Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
            )
          else if (_loadedSongs != null && _loadedSongs!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_for_offline_rounded, color: AetherColors.primaryAccent, size: 20),
              onPressed: () => ref.read(trackDownloadServiceProvider).downloadMultiple(_loadedSongs!),
              tooltip: 'Download All',
            ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white24, size: 18),
            onPressed: () => _showRenameDialog(context),
            tooltip: 'Rename Playlist',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
              onPressed: () => _confirmDeletePlaylist(context),
              tooltip: 'Delete Playlist',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white10))
              : _loadedSongs!.isEmpty
                  ? _buildEmptyState()
                  : _buildSongList(),
          
          // Global Persistent Player (Bottom Anchored)
          if (widget.onBack == null)
            const Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: MiniPlayer(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_rounded, color: Colors.white10, size: 48),
          SizedBox(height: 16),
          Text(
            'NO SONGS IN THIS PLAYLIST',
            style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 140),
      itemCount: _loadedSongs!.length,
      itemBuilder: (context, index) {
        final song = _loadedSongs![index];
        return AetherSongTile(
          song: song,
          onDownload: () => ref.read(trackDownloadServiceProvider).downloadTrack(song),
          onRemove: () async {
            await ref.read(playlistProvider.notifier).removeSongFromPlaylist(widget.playlist.id!, song.id);
            _loadSongs();
          },
           onTap: () {
            final playlist = _loadedSongs!.map(SongMetadata.fromEntity).toList();
            
            ref.read(audioProvider.notifier).playPlaylist(playlist, index);
          },
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context) {
    AppDialogs.promptText(
      context,
      title: 'RENAME PLAYLIST',
      confirmLabel: 'RENAME',
      hintText: 'New Name',
      initialValue: widget.playlist.name,
    ).then((value) async {
      if (value == null || value.isEmpty) return;
      await ref.read(playlistProvider.notifier).renamePlaylist(widget.playlist.id!, value);
      if (!mounted) return;
      setState(() {
        _playlistName = value;
      });
    });
  }

  void _confirmDeletePlaylist(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'DELETE PLAYLIST',
      content: 'Are you sure you want to delete "${widget.playlist.name}"? This action cannot be undone.',
      confirmLabel: 'DELETE',
    ).then((confirmed) {
      if (!confirmed) return;
      ref.read(playlistProvider.notifier).deletePlaylist(widget.playlist.id!);
      if (context.mounted) {
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context);
        }
      }
    });
  }
}
