import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/song_entity.dart';
import '../../state/recommendations_provider.dart';
import 'discovery_results_list.dart'; // We can reuse AetherSongTile if we import the right part
import '../../common/aether_song_tile.dart';

import '../../state/audio_state.dart';
import '../../state/audio_provider.dart';

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
      ref.read(recommendationsProvider.notifier).fetchRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white24));
    }

    if (state.trendingSongs.isEmpty && state.similarSongs.isEmpty) {
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
          if (state.similarSongs.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'FOR YOU',
            subtitle: state.baseIdeaArtist != null ? 'Because you listen to ${state.baseIdeaArtist}' : 'Based on your library',
          ),
          const SizedBox(height: 16),
          _buildList(state.similarSongs),
          const SizedBox(height: 32),
        ],
        
        if (state.trendingSongs.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'TRENDING WORLDWIDE',
            subtitle: 'Top hits right now',
          ),
          const SizedBox(height: 16),
          _buildList(state.trendingSongs),
        ],
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
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
