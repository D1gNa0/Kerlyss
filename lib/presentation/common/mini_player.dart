import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import 'aether_glass.dart';
import 'glow_edge_container.dart';
import 'vercel_hover_button.dart';
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

    final isFavorite = hasSong && library.favoriteSongIds.contains(currentSong.id);
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
                          color: Colors.white.withValues(alpha: 0.05),
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
                                  color: hasSong ? AetherColors.textPrimary : AetherColors.textSecondary,
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
                                    final current = ref.read(audioProvider).currentSong;
                                    if (current.id == currentSong.id) {
                                      ref.read(audioProvider.notifier).updateCurrentSongBpm(newBpm);
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
                                      color: AetherColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (currentSong.bpm != null)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: AetherColors.primaryAccent.withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: AetherColors.primaryAccent.withValues(alpha: 0.4)
                                      ),
                                    ),
                                    child: Text(
                                      '${currentSong.bpm} BPM',
                                      style: const TextStyle(
                                        color: AetherColors.primaryAccent,
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
                      AetherIconButton(
                        tooltip: isFavorite ? 'Unlike' : 'Like',
                        icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: hasSong ? (isFavorite ? AetherColors.error : Colors.white70) : Colors.white24,
                        onPressed: hasSong
                            ? () => ref.read(libraryProvider.notifier).toggleFavorite(_toSongEntity(currentSong))
                            : null,
                      ),
                      const SizedBox(width: 4),
                      AetherIconButton(
                        tooltip: isDownloading ? 'Downloading...' : (isDownloaded ? 'Downloaded' : 'Download'),
                        icon: isDownloaded ? Icons.check_circle_outline_rounded : Icons.download_rounded,
                        color: hasSong ? (isDownloaded ? AetherColors.success : Colors.white70) : Colors.white24,
                        onPressed: (hasSong && !isDownloaded && !isDownloading)
                            ? () => ref.read(trackDownloadServiceProvider).downloadTrack(_toSongEntity(currentSong))
                            : null,
                      ),
                      const SizedBox(width: 4),
                      AetherIconButton(
                        tooltip: 'Play/Pause',
                        icon: audioState.status == PlaybackStatus.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 24,
                        buttonSize: 44,
                        color: hasSong ? Colors.white : Colors.white24,
                        onPressed: hasSong ? () => ref.read(audioProvider.notifier).togglePlay() : null,
                      ),
                      const SizedBox(width: 4),
                      AetherIconButton(
                        tooltip: 'Up Next',
                        icon: Icons.queue_music_rounded,
                        color: hasSong ? Colors.white70 : Colors.white24,
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
                      ),
                    ],
                ),
              ),
              
              // Top Hairline Progress Bar (Warm Khaki Accent)
              if (hasSong)
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    child: LinearProgressIndicator(
                      value: currentSong.duration.inMilliseconds > 0
                          ? audioState.position.inMilliseconds / currentSong.duration.inMilliseconds
                          : 0.0,
                      minHeight: 2,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                      valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.secondaryAccent),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
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
