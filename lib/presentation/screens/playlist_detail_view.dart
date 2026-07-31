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

  void _showSyncSettingsDialog(BuildContext context) {
    bool isSynced = widget.playlist.isRealtimeSynced;
    bool autoDownload = widget.playlist.autoDownloadNewTracks;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AetherColors.ultraDarkGray,
          title: const Text('SYNC SETTINGS', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: isSynced,
                activeColor: Colors.lightGreenAccent,
                title: const Text('Real-Time Sync', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Fetch new tracks on open', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onChanged: (val) => setDialogState(() => isSynced = val),
              ),
              SwitchListTile(
                value: autoDownload,
                activeColor: Colors.lightGreenAccent,
                title: const Text('Auto-Download', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Download new tracks offline', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onChanged: (val) => setDialogState(() => autoDownload = val),
              ),
            ],
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
        leading: ExcludeFocus(
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
          if (widget.playlist.spotifySourceUrl != null)
            ExcludeFocus(
              child: IconButton(
                icon: Icon(
                  Icons.bolt_rounded,
                  color: widget.playlist.isRealtimeSynced ? Colors.amberAccent : Colors.white24,
                  size: 20,
                ),
                onPressed: () => _showSyncSettingsDialog(context),
                tooltip: 'Sync Settings',
              ),
            ),
          if (allDownloaded)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
              child: Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
            )
          else if (_loadedSongs != null && _loadedSongs!.isNotEmpty)
            ExcludeFocus(
              child: IconButton(
                icon: const Icon(Icons.download_for_offline_rounded, color: AetherColors.primaryAccent, size: 20),
                onPressed: () => ref.read(trackDownloadServiceProvider).downloadMultiple(_loadedSongs!),
                tooltip: 'Download All',
              ),
            ),
          ExcludeFocus(
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white24, size: 18),
              onPressed: () => _showRenameDialog(context),
              tooltip: 'Rename Playlist',
            ),
          ),
          ExcludeFocus(
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
