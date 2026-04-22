import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/song_entity.dart';
import '../../state/audio_provider.dart';
import '../../state/audio_state.dart';
import '../../state/download_state_provider.dart';
import '../../common/aether_song_tile.dart';

class DiscoveryResultsList extends ConsumerWidget {
  final List<SongEntity> results;
  final void Function(SongEntity) onDownload;
  final void Function(BuildContext, WidgetRef, SongEntity) onAddToPlaylist;

  const DiscoveryResultsList({
    super.key,
    required this.results,
    required this.onDownload,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadStateProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = results[index];
            return AetherSongTile(
              song: song,
              onDownload: () => onDownload(song),
              onTap: () {
                final playlist = results.map((s) => SongMetadata.fromEntity(s)).toList();
                ref.read(audioProvider.notifier).playPlaylist(playlist, index);
              },
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }
}

