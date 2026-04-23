import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/toast_service.dart';
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
import '../common/aether_song_tile.dart';
import '../state/audio_state.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:kerlyss/l10n/app_localizations.dart';
import '../common/aether_network_image.dart';
import '../state/downloaded_songs_provider.dart';
import '../state/track_download_provider.dart';



// ─── Category filter state ──────────────────────────────────────────────────
enum _LibraryCategory { allTracks, favorites, downloaded }

final _libraryCategoryProvider = StateProvider<_LibraryCategory>(
  (ref) => _LibraryCategory.allTracks,
);

final _isDraggingProvider = StateProvider<bool>((ref) => false);



// ─── Stub marker — red background with label for unimplemented items ─────────
class _ComingSoon extends StatelessWidget {
  final String label;
  final Widget child;
  const _ComingSoon({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: child),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'COMING SOON',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
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
    final l10n = AppLocalizations.of(context)!;

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
                child: ExcludeFocus(
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
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(l10n.appTitle, style: Theme.of(context).textTheme.displayMedium),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ExcludeFocus(
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
                      label: l10n.allTracks,
                      isActive: selectedCategory == _LibraryCategory.allTracks,
                      onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.allTracks,
                    ),
                    const SizedBox(width: 24),
                    _CategoryChip(
                      label: l10n.downloaded,
                      isActive: selectedCategory == _LibraryCategory.downloaded,
                      onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.downloaded,
                    ),
                    const SizedBox(width: 24),
                    _CategoryChip(
                      label: l10n.favorites,
                      isActive: selectedCategory == _LibraryCategory.favorites,
                      onTap: () => ref.read(_libraryCategoryProvider.notifier).state = _LibraryCategory.favorites,
                    ),
                    const SizedBox(width: 24),
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
    final l10n = AppLocalizations.of(context)!;
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
          ? l10n.noFavorites
          : category == _LibraryCategory.downloaded
              ? l10n.noDownloaded
              : l10n.libraryEmpty;

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
            return AetherSongTile(
              song: song,
              onDownload: () => ref.read(trackDownloadServiceProvider).downloadTrack(song),
              onTap: () {
                final playlist = songs.map((s) => SongMetadata.fromEntity(s)).toList();
                
                ref.read(audioProvider.notifier).playPlaylist(playlist, index);
              },
            );
          },
          childCount: songs.length,
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, SongEntity song) {
    final playlistState = ref.read(playlistProvider);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: Text(l10n.addToPlaylist.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2)),
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
                          ToastService.show(context, l10n.addedTo(playlist.name));
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
        Log.e('Failed to import file ${file.path}: $e');
      }
    }

    if (importedCount > 0) {
      // Refresh library state
      ref.read(libraryProvider.notifier).loadLibrary();
      
      if (context.mounted) {
        ToastService.show(context, 'Imported $importedCount file(s) to library');
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
    return ExcludeFocus(
      child: InkWell(
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
      ),
    );
  }
}
