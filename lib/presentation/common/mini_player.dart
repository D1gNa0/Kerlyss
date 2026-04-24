import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import 'aether_glass.dart';
import '../theme/aether_colors.dart';
import '../screens/full_player_view.dart';
import '../screens/queue_view.dart';
import '../state/library_provider.dart';
import '../state/download_state_provider.dart';
import '../state/track_download_provider.dart';
import 'tap_bpm_dialog.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  SongEntity _toSongEntity(SongMetadata song) {
    return SongEntity(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album ?? 'Unknown Album',
      albumArtUrl: song.artworkUrl,
      duration: song.duration,
      sourceUrl: song.id,
      sourceType: song.source,
      bpm: song.bpm,
      dateAdded: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;
    final hasSong = currentSong.id.isNotEmpty;
    final library = ref.watch(libraryProvider);
    final downloadState = ref.watch(downloadStateProvider);

    final isFavorite = hasSong && library.favoriteSongs.any((s) => s.id == currentSong.id);
    final isDownloading = hasSong && downloadState.downloadingTrackIds.contains(currentSong.id);
    final downloadProgress = hasSong ? (downloadState.downloadProgress[currentSong.id] ?? 0.0) : 0.0;
    final isDownloaded = hasSong && (
      currentSong.source == AudioSourceType.local ||
      downloadState.alreadyDownloadedIds.contains(currentSong.id) ||
      library.allSongs.any((s) => s.id == currentSong.id && s.localPath != null)
    );

    return GestureDetector(
      onTap: () {
        if (!hasSong) return;
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const FullPlayerView(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AetherGlass(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Hero(
                      tag: hasSong ? 'album_art_${currentSong.id}' : 'player_idle',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 40,
                          height: 40,
                          color: Colors.white.withOpacity(0.05),
                          child: (hasSong && currentSong.artworkUrl != null)
                              ? Image.network(
                                  currentSong.artworkUrl!, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white24, size: 20),
                                )
                              : const Icon(Icons.music_note, color: Colors.white24, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSong ? currentSong.title.toUpperCase() : 'NO TRACK PLAYING',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: hasSong ? Colors.white : Colors.white24,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          GestureDetector(
                            onLongPress: () {
                              if (hasSong) {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Tap BPM',
                                  barrierColor: Colors.black87,
                                  pageBuilder: (context, anim, secondAnim) {
                                    return FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(
                                        scale: Tween(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                                        child: TapBpmDialog(song: _toSongEntity(currentSong)),
                                      ),
                                    );
                                  },
                                ).then((newBpm) {
                                  if (newBpm != null && newBpm is int) {
                                    // Manually update the state current song to reflect instantly without waiting for re-fetch
                                    final current = ref.read(audioProvider).currentSong;
                                    if (current.id == currentSong.id) {
                                      final updated = SongMetadata(
                                        id: current.id, title: current.title, artist: current.artist, 
                                        album: current.album, artworkUrl: current.artworkUrl, duration: current.duration, 
                                        source: current.source, bpm: newBpm
                                      );
                                      ref.read(audioProvider.notifier).state = ref.read(audioProvider).copyWith(currentSong: updated);
                                    }
                                  }
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hasSong ? currentSong.artist : 'Select a song to start',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 10,
                                      color: Colors.white38,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: currentSong.bpm != null 
                                          ? AetherColors.accentCyan.withOpacity(0.3) 
                                          : Colors.white.withOpacity(0.1)
                                    ),
                                  ),
                                  child: Text(
                                    currentSong.bpm != null ? '${currentSong.bpm} BPM' : 'TAP BPM',
                                    style: TextStyle(
                                      color: currentSong.bpm != null ? AetherColors.accentCyan : Colors.white24,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                      Tooltip(
                        message: isFavorite ? 'Unlike' : 'Like',
                        child: ExcludeFocus(
                          child: IconButton(
                            onPressed: hasSong
                                ? () => ref.read(libraryProvider.notifier).toggleFavorite(_toSongEntity(currentSong))
                                : null,
                            icon: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: hasSong
                                  ? (isFavorite ? Colors.redAccent : Colors.white54)
                                  : Colors.white12,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: isDownloaded ? 'Downloaded' : 'Download',
                        child: ExcludeFocus(
                          child: IconButton(
                            onPressed: (hasSong && !isDownloaded)
                                ? () => ref.read(trackDownloadServiceProvider).downloadTrack(_toSongEntity(currentSong))
                                : null,
                            icon: Icon(
                              isDownloaded ? Icons.check_circle_outline_rounded : Icons.download_rounded,
                              color: hasSong
                                  ? (isDownloaded ? Colors.greenAccent : Colors.white54)
                                  : Colors.white12,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Play/Pause',
                        child: ExcludeFocus(
                          child: IconButton(
                            onPressed: hasSong 
                                ? () => ref.read(audioProvider.notifier).togglePlay() 
                                : null,
                            icon: audioState.status == PlaybackStatus.loading || audioState.status == PlaybackStatus.buffering
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                                  )
                                : Icon(
                                    audioState.status == PlaybackStatus.playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: hasSong ? Colors.white : Colors.white12,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Up Next',
                        child: ExcludeFocus(
                          child: IconButton(
                            onPressed: hasSong ? () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: 'Queue',
                                barrierColor: Colors.black54,
                                pageBuilder: (context, anim, secondAnim) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: SlideTransition(
                                        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
                                        child: QueueView(onClose: () => Navigator.pop(context)),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } : null,
                            icon: Icon(Icons.queue_music_rounded, color: hasSong ? Colors.white54 : Colors.white12, size: 24),
                          ),
                        ),
                      ),
                    ],
                ),
              ),
              
              // Progress Bar (Spotify Style: Thin line at absolute bottom)
              if (hasSong)
                Positioned(
                  bottom: 0,
                  left: 20, // Align with clinical precision
                  right: 20,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                    child: LinearProgressIndicator(
                      value: currentSong.duration.inMilliseconds > 0
                          ? audioState.position.inMilliseconds / currentSong.duration.inMilliseconds
                          : 0.0,
                      minHeight: 2, // Hair-thin Spotify aesthetic
                      backgroundColor: Colors.white.withOpacity(0.03),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                ),

              if (hasSong && isDownloading && !isDownloaded)
                Positioned(
                  bottom: 4,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: downloadProgress.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.primaryAccent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
