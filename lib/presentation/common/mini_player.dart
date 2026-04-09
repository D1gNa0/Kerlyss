import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import 'aether_glass.dart';
import '../theme/aether_colors.dart';
import '../screens/full_player_view.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;

    if (currentSong.id.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: AetherGlass(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Hero(
                tag: 'album_art_${currentSong.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: AetherColors.ultraDarkGray,
                    child: currentSong.artworkUrl != null
                        ? Image.network(currentSong.artworkUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.music_note, color: AetherColors.textSecondary, size: 20),
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
                      currentSong.title.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentSong.artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.read(audioProvider.notifier).togglePlay(),
                icon: Icon(
                  audioState.status == PlaybackStatus.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
