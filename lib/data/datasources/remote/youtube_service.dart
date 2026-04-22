import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/services/logger_service.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio;

  YoutubeService(this._dio);

  YoutubeExplode get client => _yt;

  /// Searches for YouTube videos based on a query.
  Future<List<Video>> searchVideos(String query) async {
    final searchList = await _yt.search.search(query);
    return searchList.where((v) => (v.duration?.inMinutes ?? 0) < 10).take(10).toList();
  }

  /// Fetches related videos for a given video ID (Recommendations).
  Future<List<Video>> getRelatedVideos(String videoId) async {
    try {
      final video = await _yt.videos.get(VideoId(videoId));
      final related = await _yt.videos.getRelatedVideos(video);
      return related?.where((v) => (v.duration?.inMinutes ?? 0) < 10).take(10).toList() ?? [];
    } catch (e) {
      Log.e('YoutubeService: Failed to fetch related videos for $videoId: $e');
      return [];
    }
  }

  /// Fetches trendy music by querying trending global keywords.
  Future<List<Video>> getTrendingMusic() async {
    try {
      final searchList = await _yt.search.search('popular hit songs official audio');
      return searchList.where((v) => (v.duration?.inMinutes ?? 0) < 10).take(15).toList();
    } catch (e) {
      Log.e('YoutubeService: Failed to fetch trending music: $e');
      return [];
    }
  }

  /// Extracts the direct audio stream URI for a given video ID.
  Future<String> getStreamUri(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    return audioStreamInfo.url.toString();
  }

  Future<File> downloadTrack(
    String videoId,
    String destinationPath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      Log.i('YoutubeService: Starting install for $videoId');
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidVr],
      );

      final muxedStreams = manifest.muxed.toList();
      if (muxedStreams.isEmpty) {
        throw Exception('No standalone muxed streams available for this video.');
      }
      
      final audioStreamInfo = (muxedStreams..sort((a, b) => b.bitrate.compareTo(a.bitrate))).first;
      final totalSize = audioStreamInfo.size.totalBytes;
      final rawUrl = audioStreamInfo.url;

      final file = File(destinationPath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      const int connections = 4;
      final int chunkSize = (totalSize / connections).ceil();
      int totalDownloaded = 0;
      final partResults = List<List<int>>.filled(connections, []);

      Future<void> downloadPart(int i) async {
        final start = i * chunkSize;
        final end = (start + chunkSize - 1).clamp(0, totalSize - 1);
        if (start >= totalSize) return;

        final client = HttpClient();
        final req = await client.getUrl(rawUrl);
        req.headers.set(HttpHeaders.userAgentHeader,
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        req.headers.set('Referer', 'https://www.youtube.com/');
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
        final res = await req.close();

        final bytes = <int>[];
        await for (final chunk in res) {
          bytes.addAll(chunk);
          totalDownloaded += chunk.length;
          if (onProgress != null) onProgress(totalDownloaded / totalSize);
        }
        partResults[i] = bytes;
        client.close();
      }

      await Future.wait(List.generate(connections, downloadPart));

      final sink = file.openWrite();
      for (final part in partResults) {
        sink.add(part);
      }
      await sink.flush();
      await sink.close();

      Log.i('YoutubeService: Install finalized successfully for $videoId');
      return file;
    } catch (e, stack) {
      Log.e('YoutubeService: Install failed for $videoId: $e');
      rethrow;
    }
  }

  /// Builds a sanitized, unique destination path for a YouTube download.
  static String buildDestinationPath(String directoryPath, String videoId, String title) {
    var safeTitle = sanitizeFilePart(title);
    if (safeTitle.isEmpty) {
      safeTitle = videoId;
    }
    
    // YouTube muxed streams are standard MP4 files (Video+Audio).
    // Using .mp4 ensures the Windows OS sees it as a standalone container.
    final fileName = '$safeTitle.mp4';
    final candidate = p.join(directoryPath, fileName);
    
    if (!File(candidate).existsSync()) {
      return candidate;
    }

    // Uniqueness logic
    var suffix = 1;
    while (true) {
      final nextCandidate = p.join(directoryPath, '$safeTitle ($suffix).mp4');
      if (!File(nextCandidate).existsSync()) {
        return nextCandidate;
      }
      suffix++;
    }
  }


  static String sanitizeFilePart(String value) {
    // Replace Turkish/Accented characters with ASCII equivalents
    var sanitized = value
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U');

    return sanitized
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '') // Remove remaining non-ascii
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(' ', '_');
  }


  /// Closes the YouTube client to release resources.
  void close() {
    _yt.close();
  }
}

