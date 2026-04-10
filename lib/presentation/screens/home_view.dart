import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../state/link_resolver_provider.dart';
import '../common/aether_loading_pulse.dart';
import '../common/source_badge.dart';
import '../common/aether_link_bar.dart';
import '../../domain/entities/audio_source_type.dart';
import '../state/library_provider.dart';
import 'settings_view.dart';
import 'profile_view.dart';

// ─── Category filter state ──────────────────────────────────────────────────
enum _LibraryCategory { allTracks, playlists, favorites, folders }

final _libraryCategoryProvider = StateProvider<_LibraryCategory>(
  (ref) => _LibraryCategory.allTracks,
);

// ─── Stub marker — red background with label for unimplemented items ─────────
class _Stub extends StatelessWidget {
  final String label;
  final Widget child;
  const _Stub({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'STUB',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final selectedCategory = ref.watch(_libraryCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 100,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileView()),
                  );
                },
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: AetherColors.glassWhite,
                  child: const Icon(Icons.person_outline_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('KERLYSS', style: Theme.of(context).textTheme.displayMedium),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsView()),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined, size: 22, color: AetherColors.textSecondary),
                ),
              ),
            ],
          ),

          // Category Switcher
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'ALL TRACKS',
                    isActive: selectedCategory == _LibraryCategory.allTracks,
                    onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.allTracks,
                  ),
                  const SizedBox(width: 24),
                  // STUB: Playlists — not yet implemented
                  _Stub(
                    label: 'PLAYLISTS',
                    child: _CategoryChip(
                      label: 'PLAYLISTS',
                      isActive: selectedCategory == _LibraryCategory.playlists,
                      onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.playlists,
                    ),
                  ),
                  const SizedBox(width: 24),
                  _CategoryChip(
                    label: 'FAVORITES',
                    isActive: selectedCategory == _LibraryCategory.favorites,
                    onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.favorites,
                  ),
                  const SizedBox(width: 24),
                  // STUB: Folders — not yet implemented
                  _Stub(
                    label: 'FOLDERS',
                    child: _CategoryChip(
                      label: 'FOLDERS',
                      isActive: selectedCategory == _LibraryCategory.folders,
                      onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.folders,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Link Import / Loading pulse
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final resolverState = ref.watch(linkResolverProvider);
                if (resolverState.status == LinkResolverStatus.resolving) {
                  return SizedBox(
                    height: 200,
                    child: AetherLoadingPulse(
                      onCancel: () => ref.read(linkResolverProvider.notifier).cancel(),
                    ),
                  );
                } else if (resolverState.status == LinkResolverStatus.success) {
                  return ResolutionPreviewCard();
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),

          // Track List — filtered by selected category
          _buildTrackList(context, ref, libraryState, selectedCategory),

          const SliverToBoxAdapter(child: SizedBox(height: 180)),
        ],
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    WidgetRef ref,
    LibraryState libraryState,
    _LibraryCategory category,
  ) {
    if (libraryState.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Colors.white24),
          ),
        ),
      );
    }

    // PLAYLISTS and FOLDERS are stubs — show a message
    if (category == _LibraryCategory.playlists || category == _LibraryCategory.folders) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade700),
                  ),
                  child: Text(
                    '${category == _LibraryCategory.playlists ? "PLAYLISTS" : "FOLDERS"} — NOT YET IMPLEMENTED',
                    style: const TextStyle(color: Colors.redAccent, letterSpacing: 2, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For FAVORITES category, same data as ALL TRACKS (all saved songs are favorites)
    // TODO: When non-favorite tracks exist, filter here
    final songs = libraryState.favoriteSongs;

    if (songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_music_outlined, color: Colors.white10, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'LIBRARY EMPTY',
                  style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = songs[index];
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
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        song.albumArtUrl ?? 'https://picsum.photos/seed/placeholder/200/200',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                  onPressed: () {
                    ref.read(libraryProvider.notifier).toggleFavorite(song);
                  },
                ),
                onTap: () {
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
          childCount: songs.length,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Text(
          label,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 11,
                color: isActive ? Colors.white : AetherColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
