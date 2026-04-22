import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import 'aether_glass.dart';
import '../theme/aether_colors.dart';
import '../screens/full_player_view.dart';
import '../screens/queue_view.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;
    final hasSong = currentSong.id.isNotEmpty;

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
                          Text(
                            hasSong ? currentSong.artist : 'Select a song to start',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                      Tooltip(
                        message: 'Play/Pause',
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
                      Tooltip(
                        message: 'Up Next',
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
            ],
          ),
        ),
      ),
    );
  }
}
