import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../domain/repositories/song_repository.dart';
import '../services/logger_service.dart';
import 'app_storage_paths.dart';

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
  void put(String songId, String videoId) {
    _cache[songId] = videoId;
    _scheduleSave();
  }
  void remove(String songId) {
    _cache.remove(songId);
    _scheduleSave();
  }
  void removeByVideoId(String videoId) {
    _cache.removeWhere((_, value) => value == videoId);
    _scheduleSave();
  }
  void clear() {
    _cache.clear();
    _scheduleSave();
  }

  // ───────────── persistence: replaying a song after a restart skips the YouTube search ─────────────

  static const int _maxEntries = 2000;
  bool _loaded = false;
  Timer? _saveTimer;

  Future<File?> _file() async {
    try {
      final dir = await AppStoragePaths.appRootDirectory();
      return File('${dir.path}${Platform.pathSeparator}stream_resolution_cache.json');
    } catch (_) {
      return null;
    }
  }

  /// Loads remembered songId -> videoId pairs from disk (once). Never throws.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return;
      final data = jsonDecode(await file.readAsString());
      if (data is Map) {
        final idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
        data.forEach((key, value) {
          if (key is String && value is String && idPattern.hasMatch(value)) {
            _cache.putIfAbsent(key, () => value); // anything resolved this session wins
          }
        });
        Log.i('StreamResolutionCache: Loaded ${_cache.length} remembered song -> video pairs');
      }
    } catch (e) {
      Log.w('StreamResolutionCache: Could not load saved cache: $e');
    }
  }

  void _scheduleSave() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return; // no timers/disk in unit tests
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), _save);
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      if (file == null) return;
      var entries = _cache.entries.toList();
      if (entries.length > _maxEntries) entries = entries.sublist(entries.length - _maxEntries);
      await file.writeAsString(jsonEncode({for (final e in entries) e.key: e.value}));
    } catch (e) {
      Log.w('StreamResolutionCache: Could not save cache: $e');
    }
  }

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
