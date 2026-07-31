import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../state/library_provider.dart';
import '../state/playlist_provider.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';
import 'vercel_hover_button.dart';
import 'aether_network_image.dart';
import '../state/download_state_provider.dart';
import '../state/track_download_provider.dart';
import '../state/audio_state.dart';
import '../state/audio_provider.dart';
import 'source_badge.dart';
import 'fix_track_match_dialog.dart';
import '../../core/services/toast_service.dart';

class AetherSongTile extends ConsumerWidget {
  final SongEntity song;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onDownload;
  final Widget? trailing;
  final bool showAlbum;
  final bool showDownloadStatus;

  const AetherSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onRemove,
    this.onDownload,
    this.trailing,
    this.showAlbum = false,
    this.showDownloadStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(libraryProvider.notifier).isSongFavorite(song.id);
    final libraryState = ref.watch(libraryProvider);
    final downloadState = ref.watch(downloadStateProvider);
    
    final isDownloading = downloadState.downloadingTrackIds.contains(song.id);
    final downloadProgress = downloadState.downloadProgress[song.id] ?? 0.0;
    
    // Get fresh song state from library if available
    final songInLib = libraryState.allSongs.where((s) => s.id == song.id).firstOrNull;
    final hasLocalPath = songInLib != null ? songInLib.localPath != null : song.localPath != null;

    // Check if downloaded: either by localPath or download state
    final isDownloaded = hasLocalPath || downloadState.alreadyDownloadedIds.contains(song.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: VercelHoverButton(
        onTap: onTap,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                AetherNetworkImage(
                  url: song.albumArtUrl ?? 'https://picsum.photos/seed/placeholder/200/200',
                  width: 44,
                  height: 44,
                  borderRadius: 10,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: SourceBadge(source: song.sourceType),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showAlbum ? '${song.artist} • ${song.album}' : song.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AetherColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ?? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Download Indicator / Button
                if (showDownloadStatus) 
                  if (isDownloaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.check_circle_outline_rounded, color: AetherColors.success, size: 16),
                    )
                  else if (onDownload != null)
                    AetherIconButton(
                      tooltip: 'Download song',
                      icon: Icons.download_rounded,
                      color: Colors.white70,
                      size: 18,
                      buttonSize: 36,
                      onPressed: isDownloading ? null : onDownload,
                    ),

                // Heart/Favorite Toggle (Tier 1: Crimson Red)
                AetherIconButton(
                  tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                  icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AetherColors.error : Colors.white70,
                  size: 18,
                  buttonSize: 36,
                  onPressed: () => ref.read(libraryProvider.notifier).toggleFavorite(song),
                ),

                // More Options
                _buildMoreMenu(context, ref, isDownloaded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, bool isDownloaded) {
    return PopupMenuButton<String>(
      tooltip: 'Show menu',
      child: const AetherIconButton(
        tooltip: 'Show menu',
        icon: Icons.more_vert_rounded,
        size: 18,
        buttonSize: 36,
        color: Colors.white70,
      ),
      padding: EdgeInsets.zero,
      color: AetherColors.ultraDarkGray,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'add_to_playlist') {
          _showAddToPlaylistDialog(context, ref);
        } else if (value == 'fix_match') {
          _showFixTrackMatchDialog(context);
        } else if (value == 'uninstall') {
          _showUninstallDialog(context, ref);
        } else if (value == 'remove') {
          onRemove?.call();
        } else if (value == 'play_next' || value == 'add_to_queue') {
          final metadata = SongMetadata.fromEntity(song);
          if (value == 'play_next') {
            ref.read(audioProvider.notifier).addNext(metadata);
            ToastService.show(context, 'Will play next: ${song.title}');
          } else {
            ref.read(audioProvider.notifier).addLast(metadata);
            ToastService.show(context, 'Added to queue: ${song.title}');
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'play_next',
          child: Row(
            children: [
              Icon(Icons.queue_play_next_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Play Next', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_to_queue',
          child: Row(
            children: [
              Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Add to Queue', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
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
        const PopupMenuItem(
          value: 'fix_match',
          child: Row(
            children: [
              Icon(Icons.youtube_searched_for_rounded, color: Colors.lightBlueAccent, size: 18),
              SizedBox(width: 8),
              Text('Fix Track Match', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        if (onRemove != null)
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.remove_circle_outline_rounded, color: Colors.white54, size: 18),
                SizedBox(width: 8),
                Text('Remove from list', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        if (isDownloaded)
          const PopupMenuItem(
            value: 'uninstall',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 8),
                Text('Uninstall', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  void _showFixTrackMatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FixTrackMatchDialog(song: song),
    );
  }

  void _showUninstallDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('Uninstall', style: TextStyle(color: Colors.white)),
        content: Text('Delete ${song.title} from device?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              ref.read(trackDownloadServiceProvider).deleteDownloadedTrack(song);
              Navigator.pop(ctx);
            }, 
            child: const Text('UNINSTALL', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      )
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(playlistProvider).playlists;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: const Text('SELECT PLAYLIST', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
        content: playlists.isEmpty
            ? const Text('No playlists found. Create one first!', style: TextStyle(color: Colors.white38))
            : SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final p = playlists[index];
                    final isAlreadyAdded = p.songIds.contains(song.id);
                    return ListTile(
                      title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: isAlreadyAdded 
                        ? const Icon(Icons.check_circle_rounded, color: AetherColors.primaryAccent, size: 18)
                        : const Icon(Icons.add_circle_outline_rounded, color: Colors.white24, size: 18),
                      onTap: () {
                        if (isAlreadyAdded) return;
                        ref.read(playlistProvider.notifier).addSongToPlaylist(p.id!, song);
                        Navigator.pop(context);
                        ToastService.show(context, 'Added to ${p.name}');
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}
