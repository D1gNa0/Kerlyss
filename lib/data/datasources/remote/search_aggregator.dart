import 'package:string_similarity/string_similarity.dart';
import '../../../domain/entities/song_entity.dart';
import '../../../domain/entities/audio_source_type.dart';
import 'spotify_public_service.dart';
import 'youtube_service.dart';

class SearchAggregator {
  final SpotifyPublicService _spotifyService;
  final YoutubeService _youtubeService;

  SearchAggregator(this._spotifyService, this._youtubeService);

  Future<List<SongEntity>> search(String query) async {
    // 1. Parallel Search
    final results = await Future.wait([
      _spotifyService.searchTracks(query),
      _youtubeService.searchVideos(query),
    ]);

    final spotifyResults = results[0] as List<Map<String, dynamic>>;
    final youtubeResults = (results[1] as List).cast<dynamic>();

    final List<SongEntity> aggregatedResults = [];
    final Set<String> matchedYoutubeIds = {};

    // 2. Fuzzy Matching & Merging
    // Note: Since searchTracks currently returns empty in this draft, 
    // we focus on the logic structure for merging.
    for (var sTrack in spotifyResults) {
      final sTitle = sTrack['name'] ?? '';
      final sArtist = sTrack['artist'] ?? '';

      dynamic bestMatch;
      double bestScore = 0;

      for (var yVideo in youtubeResults) {
        final yTitle = yVideo.title;
        final yAuthor = yVideo.author;

        final score = _calculateSimilarityScore(
          sTitle: sTitle,
          sArtist: sArtist,
          yTitle: yTitle,
          yAuthor: yAuthor,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMatch = yVideo;
        }
      }

      // Merge Threshold: 0.85
      if (bestScore >= 0.85 && bestMatch != null) {
        matchedYoutubeIds.add(bestMatch.id.value);
        aggregatedResults.add(
          SongEntity(
            id: sTrack['id'] ?? 'spotify_${sTitle.hashCode}',
            title: sTitle,
            artist: sArtist,
            album: sTrack['album'] ?? 'Unknown Album',
            albumArtUrl: sTrack['artworkUrl'],
            duration: bestMatch.duration ?? Duration.zero,
            sourceUrl: 'https://www.youtube.com/watch?v=${bestMatch.id.value}',
            sourceType: AudioSourceType.spotify,
          ),
        );
      } else {
        // Add Spotify-only result if no match found (would need a resolution later)
        aggregatedResults.add(
          SongEntity(
            id: sTrack['id'] ?? 'spotify_${sTitle.hashCode}',
            title: sTitle,
            artist: sArtist,
            album: sTrack['album'] ?? 'Unknown Album',
            albumArtUrl: sTrack['artworkUrl'],
            duration: Duration.zero,
            sourceUrl: '',
            sourceType: AudioSourceType.spotify,
          ),
        );
      }
    }

    // 3. Add remaining YouTube results
    for (var yVideo in youtubeResults) {
      if (!matchedYoutubeIds.contains(yVideo.id.value)) {
        aggregatedResults.add(
          SongEntity(
            id: yVideo.id.value,
            title: yVideo.title,
            artist: yVideo.author,
            album: 'YouTube',
            albumArtUrl: yVideo.thumbnails.highResUrl,
            duration: yVideo.duration ?? Duration.zero,
            sourceUrl: 'https://www.youtube.com/watch?v=${yVideo.id.value}',
            sourceType: AudioSourceType.youtube,
          ),
        );
      }
    }

    return aggregatedResults;
  }

  double _calculateSimilarityScore({
    required String sTitle,
    required String sArtist,
    required String yTitle,
    required String yAuthor,
  }) {
    // Title similarity (Weight 1.0)
    final titleSimilarity = sTitle.similarityTo(yTitle);
    
    // Artist similarity (Weight 0.8)
    final artistSimilarity = sArtist.similarityTo(yAuthor);

    return (titleSimilarity * 1.0 + artistSimilarity * 0.8) / 1.8;
  }
}
