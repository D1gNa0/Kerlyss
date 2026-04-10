import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../common/aether_source_bottom_sheet.dart';
import '../common/source_badge.dart';
import '../state/discovery_search_provider.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../state/library_provider.dart';

class DiscoveryView extends ConsumerWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(discoverySearchProvider);
    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header & Search Input
          SliverAppBar(
            expandedHeight: 100,
            backgroundColor: Colors.transparent,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'DISCOVER',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 14,
                      letterSpacing: 8,
                      color: Colors.white38,
                    ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const AetherSourceBottomSheet(),
                  );
                },
                icon: const Icon(Icons.add_link_rounded, color: Colors.white54, size: 22),
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Search Input
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                height: 56, // Bound the infinite height of AetherGlass
                child: AetherGlass(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    onChanged: (value) => 
                        ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'SEARCH SONGS, ARTISTS...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                      icon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Result Body
          if (searchState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white24)),
            )
          else if (searchState.results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = searchState.results[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: Colors.white.withOpacity(0.02),
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.albumArtUrl ?? 'https://picsum.photos/seed/placeholder/200/200',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SourceBadge(source: song.sourceType),
                          ],
                        ),
                        title: Text(
                          song.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            ref.read(libraryProvider.notifier).isSongFavorite(song.id) 
                                ? Icons.favorite_rounded 
                                : Icons.favorite_border_rounded,
                            color: ref.read(libraryProvider.notifier).isSongFavorite(song.id) 
                                ? Colors.redAccent 
                                : Colors.white24,
                            size: 20,
                          ),
                          onPressed: () {
                            ref.read(libraryProvider.notifier).toggleFavorite(song);
                          },
                        ),
                        onTap: () {
                          // Pass actual song data to player
                          ref.read(audioProvider.notifier).playSong(
                                SongMetadata(
                                  id: song.id,
                                  title: song.title,
                                  artist: song.artist,
                                  album: song.album,
                                  artworkUrl: song.albumArtUrl,
                                  duration: song.duration,
                                  source: song.sourceType,
                                ), 
                                song.sourceUrl,
                              );
                        },
                      ),
                    );
                  },
                  childCount: searchState.results.length,
                ),
              ),
            )
          else if (searchState.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'SEARCH FAILED',
                        style: const TextStyle(color: Colors.redAccent, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, color: Colors.white10, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      searchState.query.isEmpty ? 'START YOUR SEARCH' : 'NO RESULTS FOUND',
                      style: const TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
