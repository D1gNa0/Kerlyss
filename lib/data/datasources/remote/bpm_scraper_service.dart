import 'package:dio/dio.dart';
import '../../models/deezer_track_model.dart';
import '../../models/deezer_track_detail_model.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/services/logger_service.dart';
import '../../../domain/entities/song_entity.dart';
import '../../../domain/entities/audio_source_type.dart';

class BpmScraperService {
  final Dio _dio;

  BpmScraperService(this._dio);

  Future<int?> fetchBpm(SongEntity song) async {
    String cleanedTitle = _cleanString(song.title);
    String cleanedArtist = _cleanString(song.artist);
    
    // Handle local files where metadata is missing but filename is "Artist - Title"
    if (song.sourceType == AudioSourceType.local && (cleanedArtist.isEmpty || cleanedArtist.toLowerCase().contains('unknown'))) {
      if (cleanedTitle.contains(' - ')) {
        final parts = cleanedTitle.split(' - ');
        if (parts.length >= 2) {
          cleanedArtist = parts[0].trim();
          cleanedTitle = parts.sublist(1).join(' - ').trim();
        }
      } else {
        cleanedArtist = ''; // Clear 'unknown' to avoid breaking the query
      }
    }

    // Using Deezer Advanced Search syntax for much higher accuracy
    String searchTerms;
    if (cleanedArtist.isNotEmpty && !cleanedTitle.toLowerCase().contains(cleanedArtist.toLowerCase())) {
      searchTerms = 'track:"$cleanedTitle" artist:"$cleanedArtist"';
    } else {
      searchTerms = cleanedTitle;
    }
    
    final query = Uri.encodeComponent(searchTerms);
    if (query.isEmpty) return null;

    final url = 'https://api.deezer.com/search?q=$query&limit=1';
    Log.i('BpmDetection: [START] Requesting URL -> $url');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      Log.i('BpmDetection: [STATUS] Deezer returned status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final List results = data['data'];
          if (results.isNotEmpty) {
            try {
              final firstResult = results[0] as Map<String, dynamic>;
              final model = DeezerTrackModel.fromJson(firstResult);
              
              if (model.id.isNotEmpty) {
                Log.i('BpmDetection: Found track ID ${model.id}. Fetching full track details...');
                
                // Step 2: Fetch full track details to get BPM
                final trackUrl = 'https://api.deezer.com/track/${model.id}';
                final trackResponse = await _dio.get<Map<String, dynamic>>(
                  trackUrl,
                  options: Options(
                    sendTimeout: const Duration(seconds: 10),
                    receiveTimeout: const Duration(seconds: 10),
                  ),
                );

                if (trackResponse.statusCode == 200) {
                  final trackData = trackResponse.data;
                  if (trackData != null) {
                    final detailModel = DeezerTrackDetailModel.fromJson(trackData);
                    if (detailModel.bpm != null && detailModel.bpm! > 0) {
                      Log.i('BpmDetection: [SUCCESS] Found ${detailModel.bpm} BPM for "$searchTerms"');
                      return detailModel.bpm;
                    } else {
                      Log.w('BpmDetection: [FAIL] Track details fetched, but BPM is missing or 0.');
                    }
                  }
                } else {
                   Log.w('BpmDetection: [FAIL] Failed to fetch track details for ID ${model.id}.');
                }
              }
            } catch (e) {
              Log.w('BpmDetection: [FAIL] Failed to parse track data: $e');
              throw ParsingFailure('Failed to parse Deezer track: $e');
            }
          } else {
            Log.w('BpmDetection: [FAIL] Deezer returned 0 results for "$searchTerms".');
          }
        } else {
           Log.w('BpmDetection: [FAIL] Unexpected JSON structure from Deezer search.');
           throw ParsingFailure('Unexpected Deezer response structure');
        }
      }

      return null;
    } on DioException catch (e) {
      Log.e('BpmDetection: [ERROR] Network/API failure: $e');
      throw ServerException('Deezer BPM fetch failed: ${e.message}');
    } catch (e) {
      Log.e('BpmDetection: [ERROR] Unexpected failure: $e');
      throw ServerException('BPM detection error: $e');
    }
  }

  String _cleanString(String input) {
    // Remove content in parentheses and brackets (e.g. "(Official Video)")
    String cleaned = input.replaceAll(RegExp(r'[\(\[][^\]\)]*[\]\)]'), '');
    
    // Remove file extensions typical of downloaded files
    cleaned = cleaned.replaceAll(RegExp(r'\.(mp3|m4a|flac|wav|ogg|aac|wma)$', caseSensitive: false), '');
    
    cleaned = cleaned.replaceAll(
      RegExp(
        r'official\s+video|lyric\s+video|official\s+audio|audio\s+only|4k|hd|hq|video|remastered', 
        caseSensitive: false,
      ), 
      '',
    );
    return cleaned.trim();
  }
}
