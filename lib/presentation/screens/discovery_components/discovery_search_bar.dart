import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/aether_glass.dart';
import '../../state/discovery_search_provider.dart';

class DiscoverySearchBar extends ConsumerWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallback onSearchTriggered;

  const DiscoverySearchBar({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.onSearchTriggered,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(discoverySearchProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        height: 56,
        child: AetherGlass(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (value) {
                    ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value);
                    Future.delayed(const Duration(milliseconds: 600), onSearchTriggered);
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: searchState.searchMode == SearchMode.spotifyImport
                        ? 'PASTE SPOTIFY PLAYLIST LINK...'
                        : 'SEARCH SONGS, ARTISTS...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                    icon: IconButton(
                      icon: Icon(
                        searchState.searchMode == SearchMode.spotifyImport
                            ? Icons.queue_music_rounded
                            : Icons.search_rounded,
                        color: searchState.searchMode == SearchMode.spotifyImport
                            ? Colors.lightGreenAccent
                            : Colors.white24,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        controller.clear();
                        ref.read(discoverySearchProvider.notifier).toggleSearchMode();
                      },
                      tooltip: 'Toggle Spotify Import Mode',
                    ),
                  ),
                ),
              ),
              if (searchState.searchMode == SearchMode.spotifyImport)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: searchState.downloadOnImport,
                      activeColor: Colors.lightGreenAccent,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(discoverySearchProvider.notifier).toggleDownloadOnImport(val);
                        }
                      },
                    ),
                    const Text('Download', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
