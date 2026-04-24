import 'package:dio/dio.dart';
import '../../../core/services/logger_service.dart';
import '../../../domain/entities/song_entity.dart';
import '../../../domain/entities/audio_source_type.dart';

class DeezerPublicService {
  final Dio _dio;

  DeezerPublicService(this._dio);

  Future<List<SongEntity>> searchTracks(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    if (encodedQuery.isEmpty) return [];

    final url = 'https://api.deezer.com/search?q=$encodedQuery&limit=15';
    Log.i('DeezerPublicService: Searching for "$query"');

    try {
      final response = await _dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final List results = data['data'];
          final List<SongEntity> songs = [];

          for (var item in results) {
            final trackId = item['id']?.toString() ?? '';
            final title = item['title'] ?? 'Unknown Title';
            final artist = item['artist']?['name'] ?? 'Unknown Artist';
            final album = item['album']?['title'] ?? 'Unknown Album';
            final albumArtUrl = item['album']?['cover_xl'] ?? item['album']?['cover_big'] ?? item['album']?['cover_medium'];
            final durationSeconds = item['duration'] ?? 0;

            if (trackId.isNotEmpty) {
              songs.add(
                SongEntity(
                  id: 'deezer_$trackId',
                  title: title,
                  artist: artist,
                  album: album,
                  albumArtUrl: albumArtUrl,
                  duration: Duration(seconds: durationSeconds),
                  sourceUrl: '', // Will be resolved by YouTube in the background
                  sourceType: AudioSourceType.deezer,
                  dateAdded: DateTime.now(),
                ),
              );
            }
          }

          Log.i('DeezerPublicService: Found ${songs.length} tracks for "$query"');
          return songs;
        }
      }
      return [];
    } catch (e) {
      Log.e('DeezerPublicService: Error fetching tracks: $e');
      return [];
    }
  }
}
