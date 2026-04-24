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

  /// Pre-resolves the YouTube video IDs for a list of Deezer songs, silently
  /// in the background. Skips songs that are already cached or being resolved.
  Future<void> prefetch(List<SongEntity> songs, SongRepository songRepository) async {
    final toResolve = songs
        .where((s) => s.sourceType == AudioSourceType.deezer)
        .where((s) => !_cache.containsKey(s.id) && !_resolving.contains(s.id))
        .take(5)
        .toList();

    if (toResolve.isEmpty) return;

    Log.d('StreamResolutionCache: Pre-fetching ${toResolve.length} YouTube stream IDs...');

    // Fire all in parallel — they don't depend on each other
    await Future.wait(toResolve.map((song) => _resolveOne(song, songRepository)));
  }

  Future<void> _resolveOne(SongEntity song, SongRepository songRepository) async {
    _resolving.add(song.id);
    try {
      final videoId = await songRepository.resolveStreamUri(song);
      _cache[song.id] = videoId;
      Log.d('StreamResolutionCache: Pre-cached "${song.title}" → $videoId');
    } catch (e) {
      Log.w('StreamResolutionCache: Failed to pre-resolve "${song.title}": $e');
    } finally {
      _resolving.remove(song.id);
    }
  }

  void clear() => _cache.clear();
}
