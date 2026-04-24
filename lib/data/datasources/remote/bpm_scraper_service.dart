import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import '../../../core/services/logger_service.dart';

class BpmScraperService {
  final Dio _dio;

  BpmScraperService(this._dio);

  /// Attempts to fetch the BPM for a given track from public databases.
  Future<int?> fetchBpm(String artist, String title) async {
    final cleanedTitle = _cleanString(title);
    final cleanedArtist = _cleanString(artist);
    
    final searchTerms = '$cleanedArtist $cleanedTitle'.trim();
    final query = Uri.encodeComponent(searchTerms);
    
    if (query.isEmpty) return null;

    Log.i('BpmScraperService: Searching BPM for "$searchTerms"...');

    try {
      // Strategy 1: Try SongBPM
      final songBpmResult = await _scrapeSongBpm(query);
      if (songBpmResult != null) {
        Log.i('BpmScraperService: Found $songBpmResult BPM on SongBPM');
        return songBpmResult;
      }

      // Strategy 2: Try Tunebat (if SongBPM fails)
      final tunebatResult = await _scrapeTunebat(query);
      if (tunebatResult != null) {
        Log.i('BpmScraperService: Found $tunebatResult BPM on Tunebat');
        return tunebatResult;
      }

      Log.w('BpmScraperService: No BPM found for "$searchTerms"');
      return null;
    } catch (e) {
      Log.e('BpmScraperService: Error fetching BPM for $artist - $title: $e');
      return null;
    }
  }

  String _cleanString(String input) {
    // Remove content in parentheses and brackets (e.g. "(Official Video)", "[Lyric Video]")
    String cleaned = input.replaceAll(RegExp(r'[\(\[][^\]\)]*[\]\)]'), '');
    
    // Remove common suffixes (case-insensitive)
    cleaned = cleaned.replaceAll(
      RegExp(
        r'official\s+video|lyric\s+video|official\s+audio|audio\s+only|4k|hd|hq|video|remastered', 
        caseSensitive: false,
      ), 
      '',
    );
    
    // Remove extra whitespace
    return cleaned.trim();
  }

  Future<int?> _scrapeSongBpm(String query) async {
    try {
      final url = 'https://songbpm.com/searches?q=$query';
      final response = await _dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': 'https://songbpm.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.data.toString());
        // Look for the first element containing BPM text
        final textContent = document.body?.text ?? '';
        
        // Simple regex to find a number followed by BPM, e.g., "120 BPM"
        final regExp = RegExp(r'(\d{2,3})\s*BPM', caseSensitive: false);
        final match = regExp.firstMatch(textContent);
        
        if (match != null) {
           final bpmStr = match.group(1);
           if (bpmStr != null) {
             return int.tryParse(bpmStr);
           }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> _scrapeTunebat(String query) async {
     try {
      final url = 'https://tunebat.com/Search?q=$query';
      final response = await _dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': 'https://tunebat.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.data.toString());
        
        // Look for typical tunebat result cards
        final textContent = document.body?.text ?? '';
        
        // Tunebat often formats it as "BPM 120" or just has it in a grid
        // Let's look for "BPM" followed closely by a number
        final regExp = RegExp(r'BPM[\s\n]*(\d{2,3})', caseSensitive: false);
        final match = regExp.firstMatch(textContent);
        
        if (match != null) {
           final bpmStr = match.group(1);
           if (bpmStr != null) {
             return int.tryParse(bpmStr);
           }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
