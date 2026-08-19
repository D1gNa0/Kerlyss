import 'dart:async';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../domain/repositories/song_repository.dart';
import '../services/logger_service.dart';

/// Singleton cache that pre-resolves Deezer track IDs to YouTube video IDs
/// in the background, so playback can start instantly without a live search.
class StreamResolutionCache {
  StreamResolutionCache._();
  static final StreamResolutionCache instance = StreamResolutionCache._();

  // deezerSongId -> youtubeVideoId
  final Map<String, String> _cache = {};

  // Tracks which IDs are currently being resolved to prevent duplicate work
  final Set<String> _resolving = {};

  String? get(String songId) => _cache[songId];
  bool has(String songId) => _cache.containsKey(songId);
  void put(String songId, String videoId) => _cache[songId] = videoId;
  void remove(String songId) => _cache.remove(songId);
  void removeByVideoId(String videoId) {
    _cache.removeWhere((_, value) => value == videoId);
  }
  void clear() => _cache.clear();

  /// Pre-resolves the YouTube video IDs and stream manifests for a list of songs,
  /// silently in the background. Supports both Deezer and YouTube tracks.
  Future<void> prefetch(List<SongEntity> songs, SongRepository songRepository) async {
    final toResolve = songs
        .where((s) => s.sourceType == AudioSourceType.deezer || s.sourceType == AudioSourceType.youtube)
        .where((s) => !_resolving.contains(s.id))
        .take(3) // Limit background tasks to top 3 results to conserve resources and avoid rate limits
        .toList();

    if (toResolve.isEmpty) return;

    Log.d('StreamResolutionCache: Proactively pre-fetching stream manifests for ${toResolve.length} tracks...');

    // Run sequentially with a paced delay (1000ms) to prevent IP rate-limiting from YouTube
    for (int i = 0; i < toResolve.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      unawaited(_resolveOne(toResolve[i], songRepository));
    }
  }

  Future<void> _resolveOne(SongEntity song, SongRepository songRepository) async {
    _resolving.add(song.id);
    try {
      // Calls repository to prefetch manifest and cache ID
      await songRepository.prefetchSongStream(song);
      Log.d('StreamResolutionCache: Proactively pre-cached manifest for "${song.title}"');
    } catch (e) {
      Log.w('StreamResolutionCache: Failed to pre-resolve manifest for "${song.title}": $e');
    } finally {
      _resolving.remove(song.id);
    }
  }
}
