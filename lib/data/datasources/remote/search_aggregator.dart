import 'dart:convert';
import '../../../domain/entities/song_entity.dart';
import '../../../domain/entities/audio_source_type.dart';
import 'deezer_public_service.dart';
import '../local/isar_database_service.dart';
import '../../../core/services/logger_service.dart';

/// Search result cache TTL in minutes.
const int _searchCacheTtlMinutes = 60;

class SearchAggregator {
  final DeezerPublicService _deezerService;
  final IsarDatabaseService? _isarService;

  SearchAggregator(this._deezerService, {IsarDatabaseService? isarService})
      : _isarService = isarService;

  Future<List<SongEntity>> search(String query) async {
    // Check cache first
    if (_isarService != null) {
      try {
        final cached = await _isarService.getCachedSearch(query);
        if (cached != null && !cached.isExpired) {
          Log.d('SearchAggregator: Cache HIT for "$query"');
          return _deserializeResults(cached.resultsJson);
        }
        Log.d('SearchAggregator: Cache MISS for "$query"');
      } catch (e) {
        Log.w('SearchAggregator: Failed to read search cache: $e');
      }
    }

    // Perform actual search
    final results = await _deezerService.searchTracks(query);

    // Cache the results
    if (_isarService != null && results.isNotEmpty) {
      try {
        await _isarService.cacheSearch(
          query,
          _serializeResults(results),
          ttlMinutes: _searchCacheTtlMinutes,
        );
        Log.d('SearchAggregator: Cached ${results.length} results for "$query"');
      } catch (e) {
        Log.w('SearchAggregator: Failed to cache search results: $e');
      }
    }

    return results;
  }

  String _serializeResults(List<SongEntity> songs) {
    final list = songs.map((s) => {
      'id': s.id,
      'title': s.title,
      'artist': s.artist,
      'album': s.album,
      'albumArtUrl': s.albumArtUrl,
      'duration': s.duration.inSeconds,
      'sourceUrl': s.sourceUrl,
      'sourceType': s.sourceType.name,
    }).toList();
    return jsonEncode(list);
  }

  List<SongEntity> _deserializeResults(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return SongEntity(
          id: map['id'] as String,
          title: map['title'] as String,
          artist: map['artist'] as String? ?? '',
          album: map['album'] as String? ?? '',
          albumArtUrl: map['albumArtUrl'] as String? ?? '',
          duration: Duration(seconds: map['duration'] as int? ?? 0),
          sourceUrl: map['sourceUrl'] as String? ?? '',
          sourceType: AudioSourceType.values.firstWhere(
            (e) => e.name == map['sourceType'],
            orElse: () => AudioSourceType.deezer,
          ),
          dateAdded: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      Log.e('SearchAggregator: Failed to deserialize cached results: $e');
      return [];
    }
  }
}
