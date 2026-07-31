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

class _DiscoveryRecommendationsViewState extends ConsumerState<DiscoveryRecommendationsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationsProvider.notifier).fetchRecommendations();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(recommendationsProvider.notifier).fetchRecommendations();
    }
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
            subtitle: state.baseIdeaArtist != null
                ? 'Because you listen to ${state.baseIdeaArtist}'
              : (hasLibrary
                ? (hasPersonalizedReason
                  ? 'Based on your library'
                  : 'Fallback picks while we learn your taste')
                : 'Like songs to unlock this section'),
            onRefresh: () => ref.read(recommendationsProvider.notifier).refresh(),
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
            if (onRefresh != null)
              AetherIconButton(
                tooltip: 'Refresh recommendations',
                icon: Icons.refresh_rounded,
                size: 16,
                buttonSize: 34,
                color: Colors.white70,
                onPressed: onRefresh,
              ),
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
        );
      },
    );
  }
}
