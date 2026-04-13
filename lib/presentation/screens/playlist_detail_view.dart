import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../state/playlist_provider.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../../domain/entities/song_entity.dart';
import '../common/source_badge.dart';

class PlaylistDetailView extends ConsumerStatefulWidget {
  final dynamic playlist;
  const PlaylistDetailView({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends ConsumerState<PlaylistDetailView> {
  List<SongEntity>? _loadedSongs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await ref.read(playlistProvider.notifier).getPlaylistSongs(widget.playlist.id);
    if (mounted) {
      setState(() {
        _loadedSongs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherColors.deepMatteBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.playlist.name,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
            onPressed: () => _confirmDeletePlaylist(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white10))
          : _loadedSongs!.isEmpty
              ? _buildEmptyState()
              : _buildSongList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note_rounded, color: Colors.white10, size: 48),
          const SizedBox(height: 16),
          const Text(
            'NO SONGS IN THIS PLAYLIST',
            style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _loadedSongs!.length,
      itemBuilder: (context, index) {
        final song = _loadedSongs![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Colors.white.withOpacity(0.02),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song.albumArtUrl ?? 'https://picsum.photos/seed/placeholder/200/200',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 20),
                    ),
                  ),

                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: SourceBadge(source: song.sourceType),
                ),
              ],
            ),
            title: Text(
              song.title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: const TextStyle(color: AetherColors.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white12, size: 18),
              onPressed: () async {
                await ref.read(playlistProvider.notifier).removeSongFromPlaylist(widget.playlist.id, song.id);
                _loadSongs();
              },
            ),
            onTap: () {
              final playlist = _loadedSongs!.map((s) => SongMetadata(
                id: s.id,
                title: s.title,
                artist: s.artist,
                album: s.album,
                artworkUrl: s.albumArtUrl,
                duration: s.duration,
                source: s.sourceType,
              )).toList();
              
              ref.read(audioProvider.notifier).playPlaylist(playlist, index);
            },
          ),
        );
      },
    );
  }

  void _confirmDeletePlaylist(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('DELETE PLAYLIST?', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
        content: const Text('This will not delete the audio files.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistProvider.notifier).deletePlaylist(widget.playlist.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail view
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
