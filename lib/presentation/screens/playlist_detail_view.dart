import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/aether_song_tile.dart';
import '../common/mini_player.dart';
import '../common/vercel_hover_button.dart';
import '../state/navigation_provider.dart';
import '../state/audio_state.dart';
import '../theme/aether_colors.dart';
import '../state/app_settings_provider.dart';
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
                child: const Text('SAVE', style: TextStyle(color: AetherColors.primaryAccent)),
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
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: AetherIconButton(
              tooltip: 'Back',
              icon: Icons.arrow_back_ios_new_rounded,
              size: 16,
              buttonSize: 36,
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
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
        actions: const [],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white10))
              : _loadedSongs!.isEmpty
                  ? _buildEmptyState(isOffline: ref.watch(appSettingsProvider).isOfflineMode)
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

  Widget _buildEmptyState({bool isOffline = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isOffline ? Icons.wifi_off_rounded : Icons.music_note_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text(
            isOffline ? 'OFFLINE MODE: NO DOWNLOADED SONGS IN PLAYLIST' : 'NO SONGS IN THIS PLAYLIST',
            style: const TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          if (isOffline) ...[
            const SizedBox(height: 8),
            const Text(
              'Turn off Offline Mode in Settings to view online tracks.',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongList() {
    final currentPlaylist = ref.watch(playlistProvider).playlists.where((p) => p.id == widget.playlist.id).firstOrNull ?? widget.playlist;

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 140),
      children: [
        // Rich Hero Editorial Header
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PLAYLIST',
                      style: TextStyle(color: AetherColors.textSecondary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPlaylist.name,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${_loadedSongs!.length} TRACKS',
                          style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1),
                        ),
                        if (currentPlaylist.isRealtimeSynced) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('AUTO SYNC', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        VercelHoverButton(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          borderRadius: 20,
                          onTap: _loadedSongs!.isNotEmpty
                              ? () => ref.read(audioProvider.notifier).playPlaylist(_loadedSongs!.map(SongMetadata.fromEntity).toList(), 0)
                              : null,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('PLAY ALL', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (currentPlaylist.spotifySourceUrl != null)
                                  AetherIconButton(
                                    tooltip: 'Sync / Refresh Now',
                                    icon: Icons.refresh_rounded,
                                    size: 16,
                                    buttonSize: 34,
                                    onPressed: _isSyncing ? null : _triggerManualSync,
                                  ),
                                AetherIconButton(
                                  tooltip: 'Sync & Download Settings',
                                  icon: Icons.bolt_rounded,
                                  color: currentPlaylist.isRealtimeSynced ? AetherColors.primaryAccent : Colors.white70,
                                  size: 16,
                                  buttonSize: 34,
                                  onPressed: () => _showSyncSettingsDialog(context, currentPlaylist),
                                ),
                                AetherIconButton(
                                  tooltip: 'Rename Playlist',
                                  icon: Icons.edit_rounded,
                                  size: 16,
                                  buttonSize: 34,
                                  onPressed: () => _showRenameDialog(context),
                                ),
                                AetherIconButton(
                                  tooltip: 'Delete Playlist',
                                  icon: Icons.delete_outline_rounded,
                                  color: AetherColors.error,
                                  size: 16,
                                  buttonSize: 34,
                                  onPressed: () => _confirmDeletePlaylist(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section Header
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'TRACKLIST',
            style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
        ),

        // Song Tiles
        ..._loadedSongs!.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          return AetherSongTile(
            song: song,
            onDownload: () => ref.read(trackDownloadServiceProvider).downloadTrack(song),
            onTap: () => ref.read(audioProvider.notifier).playPlaylist(_loadedSongs!.map(SongMetadata.fromEntity).toList(), index),
            onRemove: () async {
              await ref.read(playlistProvider.notifier).removeSongFromPlaylist(widget.playlist.id!, song.id);
              _reloadSongsFromDb();
            },
          );
        }),
      ],
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
