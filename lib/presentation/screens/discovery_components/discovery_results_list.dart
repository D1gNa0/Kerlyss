import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/song_entity.dart';
import '../../../domain/entities/audio_source_type.dart';
import '../../common/aether_glass.dart';
import '../../common/source_badge.dart';
import '../../state/audio_provider.dart';
import '../../state/audio_state.dart';
import '../../state/library_provider.dart';
import '../../theme/aether_colors.dart';

class DiscoveryResultsList extends ConsumerWidget {
  final List<SongEntity> results;
  final bool Function(String) isAlreadyDownloaded;
  final bool Function(String) isDownloading;
  final double Function(String) getProgress;
  final void Function(SongEntity) onDownloadJamendo;
  final void Function(SongEntity) onDownloadYoutube;
  final void Function(BuildContext, WidgetRef, SongEntity) onAddToPlaylist;

  const DiscoveryResultsList({
    super.key,
    required this.results,
    required this.isAlreadyDownloaded,
    required this.isDownloading,
    required this.getProgress,
    required this.onDownloadJamendo,
    required this.onDownloadYoutube,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = results[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AetherGlass(
                borderRadius: 16,
                padding: const EdgeInsets.all(4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: song.albumArtUrl != null && song.albumArtUrl!.isNotEmpty
                            ? Image.network(
                                song.albumArtUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFallbackArt(),
                              )
                            : _buildFallbackArt(),
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
                                fontSize: 15,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDownloading(song.id))
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: LinearProgressIndicator(
                              value: getProgress(song.id),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white30),
                              minHeight: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    song.sourceType == AudioSourceType.jamendo
                        ? '${song.artist}  •  Tap INSTALL to save'
                        : song.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (song.sourceType == AudioSourceType.jamendo ||
                          song.sourceType == AudioSourceType.youtube)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: isAlreadyDownloaded(song.id)
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Icon(Icons.check_circle_rounded,
                                        color: Colors.lightGreenAccent, size: 20),
                                  ),
                                )
                              : IconButton(
                                  onPressed: isDownloading(song.id)
                                      ? null
                                      : () {
                                          if (song.sourceType == AudioSourceType.jamendo) {
                                            onDownloadJamendo(song);
                                          } else if (song.sourceType == AudioSourceType.youtube) {
                                            onDownloadYoutube(song);
                                          }
                                        },
                                  icon: isDownloading(song.id)
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                                        )
                                      : const Icon(Icons.download_rounded, color: Colors.white30, size: 20),
                                  tooltip: 'Install to local library',
                                ),
                        ),
                      IconButton(
                        icon: Icon(
                          ref.read(libraryProvider.notifier).isSongFavorite(song.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: ref.read(libraryProvider.notifier).isSongFavorite(song.id)
                              ? Colors.redAccent
                              : Colors.white24,
                          size: 18,
                        ),
                        onPressed: () {
                          ref.read(libraryProvider.notifier).toggleFavorite(song);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 20),
                        padding: EdgeInsets.zero,
                        color: AetherColors.ultraDarkGray,
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'add_to_playlist') {
                            onAddToPlaylist(context, ref, song);
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

  Widget _buildFallbackArt() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white.withOpacity(0.05),
      child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 24),
    );
  }
}
