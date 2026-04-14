import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/spotify_metadata_model.dart';
import '../../models/spotify_track_model.dart';
import '../../../core/error/exceptions.dart';

class SpotifyPublicService {
  final Dio _dio;
  
  static const String _oEmbedBaseUrl = 'https://open.spotify.com/oembed';

  SpotifyPublicService(this._dio);

  /// Fetches metadata from a Spotify track/album/playlist URL using the public oEmbed endpoint.
  Future<SpotifyMetadataModel> fetchMetadata(String spotifyUrl) async {
    try {
      final response = await _dio.get(
        _oEmbedBaseUrl,
        queryParameters: {'url': spotifyUrl},
      );

      if (response.statusCode == 200) {
        return SpotifyMetadataModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to fetch Spotify metadata: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('Error resolving Spotify OEmbed: $e');
    }
  }

  /// Extracts the Spotify ID from a standard URL.
  String? extractId(String url) {
    final regExp = RegExp(r'track/([a-zA-Z0-9]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Searches for tracks on Spotify using the public search page (No-API).
  /// Note: This is a robust fallback for the "No-API" protocol.
  Future<List<SpotifyTrackModel>> searchTracks(String query) async {
    try {
      final String searchUrl = 'https://open.spotify.com/search/${Uri.encodeComponent(query)}';
      final response = await _dio.get(
        searchUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );

      if (response.statusCode != 200) return [];

      // Logic: Spotify search page contains a JSON object in a <script id="initial-state"> tag.
      // We parse this to extract track metadata.
      final String html = response.data.toString();
      final regExp = RegExp(r'<script id="initial-state" type="text/plain">([\s\S]*?)<\/script>');
      final match = regExp.firstMatch(html);

      if (match == null) return [];

      try {
        final decoded = utf8.decode(base64.decode(match.group(1)!));
        final json = jsonDecode(decoded);
        final tracks = json['entities']['items'] as Map<String, dynamic>?;

        if (tracks == null) return [];

        final results = <SpotifyTrackModel>[];
        for (final entry in tracks.values) {
          if (entry['type'] == 'track') {
            results.add(SpotifyTrackModel(
              id: entry['id'] ?? '',
              name: entry['name'] ?? 'Unknown Track',
              artist: entry['firstArtist'] ?? 'Unknown Artist',
              album: entry['album']?['name'] ?? 'Unknown Album',
              artworkUrl: entry['album']?['coverArt']?['sources']?[0]?['url'] ?? '',
            ));
          }
        }
        return results;
      } catch (e) {
        // Fallback to empty list if Spotify changes their internal state structure
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
