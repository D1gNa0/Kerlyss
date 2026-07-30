import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/audio_provider.dart';
import '../theme/aether_colors.dart';

class QueueView extends ConsumerWidget {
  final VoidCallback onClose;
  const QueueView({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final playlist = audioState.playlist;

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: AetherColors.deepMatteBlack,
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'UP NEXT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          
          // Queue List
          Expanded(
            child: playlist.isEmpty
                ? const Center(
                    child: Text('QUEUE IS EMPTY', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5)),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: playlist.length,
                    onReorder: (oldIndex, newIndex) {
                      ref.read(audioProvider.notifier).reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      final isPlaying = index == audioState.currentIndex;
                      
                      return ListTile(
                        key: ValueKey('${song.id}_$index'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        tileColor: isPlaying ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                        onTap: () {
                          ref.read(audioProvider.notifier).playPlaylist(playlist, index);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: song.artworkUrl != null
                              ? Image.network(song.artworkUrl!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.music_note, color: Colors.white24))
                              : Container(width: 40, height: 40, color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white24, size: 20)),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isPlaying ? AetherColors.primaryAccent : Colors.white,
                            fontSize: 13,
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPlaying)
                              const Icon(Icons.equalizer_rounded, color: AetherColors.primaryAccent, size: 16),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 16),
                              onPressed: () {
                                ref.read(audioProvider.notifier).removeFromQueue(index);
                              },
                              tooltip: 'Remove',
                            ),
                            const Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 16),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
