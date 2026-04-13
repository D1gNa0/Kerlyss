import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/link_resolver_provider.dart';
import '../state/keyboard_shortcuts_provider.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';

class AetherLinkSearchBar extends ConsumerStatefulWidget {
  const AetherLinkSearchBar({super.key});

  @override
  ConsumerState<AetherLinkSearchBar> createState() => _AetherLinkSearchBarState();
}

class _AetherLinkSearchBarState extends ConsumerState<AetherLinkSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_syncShortcutSuppression);
  }

  void _syncShortcutSuppression() {
    if (!mounted) {
      return;
    }

    ref.read(keyboardShortcutsSuppressedProvider.notifier).state = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_syncShortcutSuppression);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: AetherGlass(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(linkResolverProvider.notifier).resolveLink(value);
              _controller.clear();
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'PASTE LINK TO IMPORT...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
              letterSpacing: 2,
            ),
            icon: Icon(Icons.link_rounded, color: Colors.white.withOpacity(0.5), size: 20),
          ),
        ),
      ),
    );
  }
}

class ResolutionPreviewCard extends ConsumerWidget {
  const ResolutionPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(linkResolverProvider);
    final song = state.resolvedSong;

    if (song == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 80,
      child: AetherGlass(
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song.artworkUrl!, 
                width: 56, 
                height: 56, 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 24),
                ),
              ),

            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(color: AetherColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Future: integrate with AudioProvider to play
                ref.read(linkResolverProvider.notifier).reset();
              },
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
            ),
            IconButton(
              onPressed: () => ref.read(linkResolverProvider.notifier).reset(),
              icon: const Icon(Icons.close_rounded, color: AetherColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
