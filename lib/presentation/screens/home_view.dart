import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/toast_service.dart';
import '../state/audio_provider.dart';
import '../state/audio_state.dart';
import '../state/link_resolver_provider.dart';
import '../common/aether_loading_pulse.dart';
import '../common/aether_glass.dart';
import '../common/vercel_hover_button.dart';
import '../common/aether_link_bar.dart';
import '../state/library_provider.dart';
import 'profile_view.dart';
import 'settings_view.dart';
import '../common/aether_song_tile.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:kerlyss/l10n/app_localizations.dart';
import '../state/downloaded_songs_provider.dart';
import '../state/track_download_provider.dart';



// ─── Category filter state ──────────────────────────────────────────────────
enum _LibraryCategory { allTracks, favorites, downloaded }

final _libraryCategoryProvider = StateProvider<_LibraryCategory>(
  (ref) => _LibraryCategory.allTracks,
);

final _isDraggingProvider = StateProvider<bool>((ref) => false);






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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: isActive ? Colors.white : AetherColors.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isActive ? 20 : 0,
            decoration: BoxDecoration(
              color: isActive ? AetherColors.primaryAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
