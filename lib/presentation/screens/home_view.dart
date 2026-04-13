import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../state/link_resolver_provider.dart';
import '../common/aether_loading_pulse.dart';
import '../common/source_badge.dart';
import '../common/aether_link_bar.dart';
import '../state/library_provider.dart';
import 'settings_view.dart';
import 'profile_view.dart';
import 'playlists_view.dart';
import '../state/playlist_provider.dart';
import '../state/library_provider.dart';
import '../state/navigation_provider.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../state/downloaded_songs_provider.dart';



// ─── Category filter state ──────────────────────────────────────────────────
enum _LibraryCategory { allTracks, favorites, downloaded, folders }

final _libraryCategoryProvider = StateProvider<_LibraryCategory>(
  (ref) => _LibraryCategory.allTracks,
);

final _isDraggingProvider = StateProvider<bool>((ref) => false);



// ─── Stub marker — red background with label for unimplemented items ─────────
class _Stub extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  const _Stub({required this.label, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
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
      ),
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
      body: DropTarget(
        onDragEntered: (_) => ref.read(_isDraggingProvider.notifier).state = true,
        onDragExited: (_) => ref.read(_isDraggingProvider.notifier).state = false,
        onDragDone: (details) => _handleDrop(context, ref, details),
        child: CustomScrollView(
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
                    _CategoryChip(
                      label: 'DOWNLOADED',
                      isActive: selectedCategory == _LibraryCategory.downloaded,
                      onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.downloaded,
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

    final songs = category == _LibraryCategory.favorites
        ? libraryState.favoriteSongs
        : category == _LibraryCategory.downloaded
            ? libraryState.allSongs.where((s) => s.localPath != null).toList()
            : libraryState.allSongs;

    if (songs.isEmpty) {

      final message = category == _LibraryCategory.favorites
          ? 'NO FAVORITES YET'
          : category == _LibraryCategory.downloaded
              ? 'NO DOWNLOADED TRACKS'
              : 'LIBRARY EMPTY';

      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 10),
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
                        errorBuilder: (context, error, stackTrace) => Container(
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (song.localPath != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 16),
                      )
                    else if (song.sourceType == AudioSourceType.jamendo || song.sourceType == AudioSourceType.youtube)
                       IconButton(
                        icon: const Icon(Icons.download_rounded, color: Colors.white24, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download from Library coming soon! Use Search to download for now.')),
                          );
                        },
                        tooltip: 'Download track',
                      ),

                    Builder(
                      builder: (context) {
                        final isFav = ref.watch(libraryProvider.notifier).isSongFavorite(song.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                            color: isFav ? Colors.redAccent : Colors.white24, 
                            size: 18,
                          ),
                          onPressed: () {
                            ref.read(libraryProvider.notifier).toggleFavorite(song);
                          },
                        );
                      }
                    ),

                    PopupMenuButton<String>(

                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 20),
                      padding: EdgeInsets.zero,
                      color: AetherColors.ultraDarkGray,
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'add_to_playlist') {
                          _showAddToPlaylistDialog(context, ref, song);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'add_to_playlist',
                          child: Row(
                            children: [
                              Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                onTap: () {
                  final playlist = songs.map((s) => SongMetadata(
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
          childCount: songs.length,
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, SongEntity song) {
    final playlistState = ref.read(playlistProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('ADD TO PLAYLIST', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2)),
        content: playlistState.playlists.isEmpty
            ? const Text('No playlists found. Create one first!', style: TextStyle(color: Colors.white38, fontSize: 12))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlistState.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistState.playlists[index];
                    return ListTile(
                      title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      onTap: () {
                        ref.read(playlistProvider.notifier).addSongToPlaylist(playlist.id, song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}'), backgroundColor: Colors.white10),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Color(0x57FFFFFF))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDrop(BuildContext context, WidgetRef ref, DropDoneDetails details) async {
    final localDownloadLibrary = ref.read(localDownloadLibraryProvider);
    int importedCount = 0;
    
    for (final file in details.files) {
      try {
        await localDownloadLibrary.importFile(file.path);
        importedCount++;
      } catch (e) {
        // Silently fail for individual files
      }
    }

    if (importedCount > 0) {
      // Refresh library state
      ref.read(libraryProvider.notifier).loadLibrary();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importedCount file(s) to library'),
            backgroundColor: Colors.white10,
          ),
        );
      }
    }
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
