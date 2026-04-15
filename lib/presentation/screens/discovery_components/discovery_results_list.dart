import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/song_entity.dart';
import '../../../domain/entities/audio_source_type.dart';
import '../../common/aether_glass.dart';
import '../../common/source_badge.dart';
import '../../state/audio_provider.dart';
import '../../state/audio_state.dart';
import '../../state/library_provider.dart';
import '../../state/download_state_provider.dart';
import '../../theme/aether_colors.dart';

class DiscoveryResultsList extends ConsumerWidget {
  final List<SongEntity> results;
  final void Function(SongEntity) onDownloadJamendo;
  final void Function(SongEntity) onDownloadYoutube;
  final void Function(BuildContext, WidgetRef, SongEntity) onAddToPlaylist;

  const DiscoveryResultsList({
    super.key,
    required this.results,
    required this.onDownloadJamendo,
    required this.onDownloadYoutube,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadStateProvider);
    final libraryState = ref.watch(libraryProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = results[index];
            final isDownloading = downloadState.downloadingTrackIds.contains(song.id);
            final isAlreadyDownloaded = downloadState.alreadyDownloadedIds.contains(song.id);
            final progress = downloadState.downloadProgress[song.id] ?? 0.0;
            final isFavorite = libraryState.favoriteSongs.any((s) => s.id == song.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AetherGlass(
                height: 60,
                borderRadius: 12,
                padding: const EdgeInsets.all(2),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  dense: true,
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.albumArtUrl != null && song.albumArtUrl!.isNotEmpty
                            ? Image.network(
                                song.albumArtUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFallbackArt(44),
                              )
                            : _buildFallbackArt(44),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SourceBadge(source: song.sourceType),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          song.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDownloading)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: SizedBox(
                            width: 12,
                            height: 2,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white30),
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (song.sourceType == AudioSourceType.youtube)
                        Padding(
                          padding: const EdgeInsets.only(right: 2.0),
                          child: isAlreadyDownloaded
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Icon(Icons.check_circle_rounded,
                                        color: Colors.lightGreenAccent, size: 18),
                                  ),
                                )
                              : IconButton(
                                  onPressed: isDownloading
                                      ? null
                                      : () {
                                          if (song.sourceType == AudioSourceType.jamendo) {
                                            onDownloadJamendo(song);
                                          } else if (song.sourceType == AudioSourceType.youtube) {
                                            onDownloadYoutube(song);
                                          }
                                        },
                                  icon: isDownloading
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                                        )
                                      : const Icon(Icons.download_rounded, color: Colors.white30, size: 18),
                                  tooltip: 'Install to local library',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                        ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : Colors.white24,
                          size: 16,
                        ),
                        onPressed: () {
                          ref.read(libraryProvider.notifier).toggleFavorite(song);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AetherColors.ultraDarkGray,
                        offset: const Offset(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (value) {
                          if (value == 'add_to_playlist') {
                            onAddToPlaylist(context, ref, song);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add_to_playlist',
                            height: 32,
                            child: Row(
                              children: [
                                Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 16),
                                SizedBox(width: 8),
                                Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    final playlist = results.map((s) => SongMetadata(
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
              ),
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildFallbackArt(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white.withOpacity(0.05),
      child: Icon(Icons.music_note_rounded, color: Colors.white24, size: size / 2),
    );
  }
}
