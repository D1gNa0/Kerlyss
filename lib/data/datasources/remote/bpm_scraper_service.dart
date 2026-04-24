import 'package:dio/dio.dart';
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
      final response = await _dio.get(
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
            final firstResult = results[0];
            final trackId = firstResult['id'];
            
            if (trackId != null) {
              Log.i('BpmDetection: Found track ID $trackId. Fetching full track details...');
              
              // Step 2: Fetch full track details to get BPM
              final trackUrl = 'https://api.deezer.com/track/$trackId';
              final trackResponse = await _dio.get(
                trackUrl,
                options: Options(
                  sendTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                ),
              );

              if (trackResponse.statusCode == 200) {
                final trackData = trackResponse.data;
                if (trackData != null && trackData['bpm'] != null && trackData['bpm'] > 0) {
                  final bpm = (trackData['bpm'] as num).round();
                  Log.i('BpmDetection: [SUCCESS] Found $bpm BPM for "$searchTerms"');
                  return bpm;
                } else {
                  Log.w('BpmDetection: [FAIL] Track details fetched, but BPM is missing or 0.');
                }
              } else {
                 Log.w('BpmDetection: [FAIL] Failed to fetch track details for ID $trackId.');
              }
            }
          } else {
            Log.w('BpmDetection: [FAIL] Deezer returned 0 results for "$searchTerms".');
          }
        } else {
           Log.w('BpmDetection: [FAIL] Unexpected JSON structure from Deezer search.');
        }
      }

      return null;
    } catch (e) {
      Log.e('BpmDetection: [ERROR] Network/API failure: $e');
      return null;
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
