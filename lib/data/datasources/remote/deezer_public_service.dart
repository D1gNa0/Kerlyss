import 'package:dio/dio.dart';
import '../../models/deezer_track_model.dart';
import '../../../core/error/exceptions.dart';
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
      final response = await _dio.get<Map<String, dynamic>>(
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
            try {
              final model = DeezerTrackModel.fromJson(item as Map<String, dynamic>);
              
              if (model.id.isNotEmpty) {
                songs.add(
                  SongEntity(
                    id: 'deezer_${model.id}',
                    title: model.title,
                    artist: model.artistName,
                    album: model.albumTitle,
                    albumArtUrl: model.albumCoverUrl,
                    duration: Duration(seconds: model.duration),
                    sourceUrl: '', // Will be resolved by YouTube in the background
                    sourceType: AudioSourceType.deezer,
                    dateAdded: DateTime.now(),
                  ),
                );
              }
            } catch (e) {
              Log.w('DeezerPublicService: Failed to parse track: $e');
              continue;
            }
          }

          Log.i('DeezerPublicService: Found ${songs.length} tracks for "$query"');
          return songs;
        }
      }
      return [];
    } on DioException catch (e) {
      Log.e('DeezerPublicService: Network error fetching tracks: $e');
      throw ServerException('Deezer network error: ${e.message}');
    } catch (e) {
      Log.e('DeezerPublicService: Error fetching tracks: $e');
      throw ServerException('Deezer service error: $e');
    }
  }
}
