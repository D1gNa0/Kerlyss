import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/song_entity.dart';
import '../../state/recommendations_provider.dart';
import '../../common/aether_song_tile.dart';
import '../../common/vercel_hover_button.dart';

import '../../state/audio_state.dart';
import '../../state/audio_provider.dart';
import '../../state/library_provider.dart';
import '../../state/download_state_provider.dart';
import '../../theme/aether_colors.dart';
import '../../../core/services/toast_service.dart';

class DiscoveryRecommendationsView extends ConsumerStatefulWidget {
  final Function(SongEntity) onDownload;
  final Function(BuildContext, WidgetRef, SongEntity) onAddToPlaylist;

  const DiscoveryRecommendationsView({
    super.key,
    required this.onDownload,
    required this.onAddToPlaylist,
  });

  @override
  ConsumerState<DiscoveryRecommendationsView> createState() => _DiscoveryRecommendationsViewState();
}

class _DiscoveryRecommendationsViewState extends ConsumerState<DiscoveryRecommendationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(recommendationsProvider).similarSongs.isEmpty) {
        ref.read(recommendationsProvider.notifier).fetchRecommendations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsProvider);
    final library = ref.watch(libraryProvider);
    final downloadState = ref.watch(downloadStateProvider);

    final favoriteIds = library.favoriteSongs.map((s) => s.id).toSet();
    final downloadedIds = downloadState.alreadyDownloadedIds;
    final localDownloadedIds = library.allSongs
      .where((s) => s.localPath != null)
      .map((s) => s.id)
      .toSet();
    final excludedIds = {
      ...favoriteIds,
      ...downloadedIds,
      ...localDownloadedIds,
    };

    final filteredTrending = state.trendingSongs
      .where((song) => !excludedIds.contains(song.id))
        .toList();

    final filteredSimilar = state.similarSongs
      .where((song) => !excludedIds.contains(song.id))
        .toList();

    final visibleReasons = <String, String>{
      for (final song in filteredSimilar)
        song.id: state.similarReasons[song.id] ?? 'ARTIST MATCH',
    };
    final hasPersonalizedReason = visibleReasons.values.any((r) => r != 'TRENDING FALLBACK');

    final hasLibrary = library.allSongs.isNotEmpty;

    String subtitle;
    switch (state.mode) {
      case RecommendationMode.currentTrack:
        final active = ref.watch(audioProvider).currentSong;
        subtitle = active.title.isNotEmpty
            ? 'Similar to "${active.title}" by ${active.artist}'
            : 'Similar to currently playing song';
        break;
      case RecommendationMode.currentArtist:
        final active = ref.watch(audioProvider).currentSong;
        subtitle = active.artist.isNotEmpty
            ? 'Radio feed for ${active.artist}'
            : 'Radio feed for current artist';
        break;
      case RecommendationMode.auto:
      default:
        subtitle = state.baseIdeaArtist != null
            ? 'Because you listen to ${state.baseIdeaArtist}'
            : (hasLibrary
                ? (hasPersonalizedReason
                    ? 'Based on your library'
                    : 'Fallback picks while we learn your taste')
                : 'Like songs to unlock this section');
        break;
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white24));
    }

    if (filteredTrending.isEmpty && filteredSimilar.isEmpty && !hasLibrary) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined, color: Colors.white10, size: 48),
            const SizedBox(height: 16),
            const Text(
              'START YOUR SEARCH',
              style: TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            title: 'FOR YOU',
            subtitle: subtitle,
            onRefresh: () => ref.read(recommendationsProvider.notifier).refresh(),
            onTune: () => _showTuningSheet(context, ref),
          ),
          const SizedBox(height: 16),
          if (filteredSimilar.isNotEmpty)
            _buildList(filteredSimilar)
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'NO PERSONALIZED PICKS YET',
                style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.2),
              ),
            ),
          if (filteredSimilar.isNotEmpty && filteredSimilar.length < 4)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'LOW CONFIDENCE RECOMMENDATIONS',
                style: TextStyle(color: Colors.amber, fontSize: 10, letterSpacing: 1.2),
              ),
            ),
          const SizedBox(height: 32),
        
        if (filteredTrending.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'TRENDING WORLDWIDE',
            subtitle: 'Top hits right now',
          ),
          const SizedBox(height: 16),
          _buildList(filteredTrending),
        ],
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onRefresh,
    VoidCallback? onTune,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            if (onTune != null)
              AetherIconButton(
                tooltip: 'Tune recommendation seed',
                icon: Icons.tune_rounded,
                size: 16,
                buttonSize: 34,
                color: AetherColors.accentCyan,
                onPressed: onTune,
              ),
            if (onRefresh != null) ...[
              const SizedBox(width: 4),
              AetherIconButton(
                tooltip: 'Refresh recommendations',
                icon: Icons.refresh_rounded,
                size: 16,
                buttonSize: 34,
                color: Colors.white70,
                onPressed: onRefresh,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showTuningSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(recommendationsProvider);
    final activeSong = ref.read(audioProvider).currentSong;

    showModalBottomSheet(
      context: context,
      backgroundColor: AetherColors.ultraDarkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: AetherColors.accentCyan, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'RECOMMENDATION SEED',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModeTile(
                  context,
                  ref,
                  mode: RecommendationMode.auto,
                  title: 'Auto Mix',
                  subtitle: 'Balances favorite artists, library history, and active playback',
                  isSelected: state.mode == RecommendationMode.auto,
                  onTap: () {
                    ref.read(recommendationsProvider.notifier).resetToAuto();
                    Navigator.pop(context);
                  },
                ),
                _buildModeTile(
                  context,
                  ref,
                  mode: RecommendationMode.currentTrack,
                  title: 'Currently Playing Song',
                  subtitle: activeSong.title.isNotEmpty
                      ? '"${activeSong.title}" by ${activeSong.artist}'
                      : 'Play a song to generate recommendations matching its style',
                  isSelected: state.mode == RecommendationMode.currentTrack,
                  onTap: activeSong.title.isNotEmpty
                      ? () {
                          ref.read(recommendationsProvider.notifier).setMode(RecommendationMode.currentTrack);
                          Navigator.pop(context);
                        }
                      : null,
                ),
                _buildModeTile(
                  context,
                  ref,
                  mode: RecommendationMode.currentArtist,
                  title: 'Currently Playing Artist',
                  subtitle: activeSong.artist.isNotEmpty
                      ? 'Radio feed for ${activeSong.artist}'
                      : 'Play a song to generate a radio feed for its artist',
                  isSelected: state.mode == RecommendationMode.currentArtist,
                  onTap: activeSong.artist.isNotEmpty
                      ? () {
                          ref.read(recommendationsProvider.notifier).setMode(RecommendationMode.currentArtist);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeTile(
    BuildContext context,
    WidgetRef ref, {
    required RecommendationMode mode,
    required String title,
    required String subtitle,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AetherColors.accentCyan.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AetherColors.accentCyan.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AetherColors.accentCyan, size: 18) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildList(List<SongEntity> songs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: songs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return AetherSongTile(
          song: song,
          showDownloadStatus: true,
          onDownload: () => widget.onDownload(song),
          onTap: () {
            final playlist = songs.map((s) => SongMetadata.fromEntity(s)).toList();
            ref.read(audioProvider.notifier).playPlaylist(playlist, index);
          },
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.white38),
            color: AetherColors.ultraDarkGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'dislike_song') {
                ref.read(recommendationsProvider.notifier).dislikeSong(song);
                ToastService.show(context, 'Removed "${song.title}" from recommendations');
              } else if (value == 'dislike_artist') {
                ref.read(recommendationsProvider.notifier).dislikeArtist(song.artist);
                ToastService.show(context, 'Muted recommendations for ${song.artist}');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'dislike_song',
                child: Row(
                  children: [
                    const Icon(Icons.hide_source_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Not interested in song', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'dislike_artist',
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('Don\'t recommend ${song.artist}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
