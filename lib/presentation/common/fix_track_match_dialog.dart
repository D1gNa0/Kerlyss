import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../../domain/entities/song_entity.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';
import '../../core/services/stream_resolution_cache.dart';
import '../../data/repositories/repository_providers.dart';
import '../../core/services/toast_service.dart';

class FixTrackMatchDialog extends ConsumerStatefulWidget {
  final SongEntity song;

  const FixTrackMatchDialog({
    super.key,
    required this.song,
  });

  @override
  ConsumerState<FixTrackMatchDialog> createState() => _FixTrackMatchDialogState();
}

class _FixTrackMatchDialogState extends ConsumerState<FixTrackMatchDialog> {
  bool _isLoading = true;
  String? _error;
  List<yt.Video> _youtubeResults = [];

  @override
  void initState() {
    super.initState();
    _searchYouTube();
  }

  Future<void> _searchYouTube() async {
    try {
      final youtubeService = ref.read(youtubeServiceProvider);
      final query = '${widget.song.artist} ${widget.song.title}';
      final results = await youtubeService.searchVideos(query);
      if (mounted) {
        setState(() {
          _youtubeResults = results.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search YouTube alternatives.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectVideo(yt.Video video) async {
    try {
      final chosenVideoId = video.id.value;

      // 1. Lock in StreamResolutionCache
      StreamResolutionCache.instance.put(widget.song.id, chosenVideoId);

      // 2. Save updated sourceUrl in Isar DB
      final songRepo = ref.read(songRepositoryProvider);
      final updatedSong = widget.song.copyWith(sourceUrl: chosenVideoId);
      await songRepo.saveSong(updatedSong);

      if (mounted) {
        Navigator.of(context).pop();
        ToastService.show(context, 'Locked track match to YouTube video: $chosenVideoId');
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(context, 'Failed to update track match.', backgroundColor: Colors.redAccent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AetherColors.ultraDarkGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FIX TRACK MATCH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.song.title} • ${widget.song.artist}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: _isLoading
            ? const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.lightGreenAccent),
                ),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  )
                : _youtubeResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No YouTube matches found.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _youtubeResults.length,
                        itemBuilder: (context, index) {
                          final video = _youtubeResults[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AetherGlass(
                              borderRadius: 12,
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                dense: true,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    video.thumbnails.lowResUrl,
                                    width: 48,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 36,
                                      color: Colors.white10,
                                      child: const Icon(Icons.video_library_rounded, color: Colors.white38, size: 16),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  video.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${video.author} • ${video.duration != null ? "${video.duration!.inMinutes}:${(video.duration!.inSeconds % 60).toString().padLeft(2, '0')}" : ""}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                onTap: () => _selectVideo(video),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}
