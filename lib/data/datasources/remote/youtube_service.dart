import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Searches for YouTube videos based on a query.
  Future<List<Video>> searchVideos(String query) async {
    final searchList = await _yt.search.search(query);
    return searchList.take(10).toList();
  }

  /// Extracts the direct audio stream URI for a given video ID.
  Future<String> getStreamUri(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    return audioStreamInfo.url.toString();
  }

  /// Closes the YouTube client to release resources.
  void close() {
    _yt.close();
  }
}
