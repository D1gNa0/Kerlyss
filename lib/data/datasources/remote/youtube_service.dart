import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/services/logger_service.dart';

class DownloadChunk {
  final int startOffset;
  final List<int> data;
  DownloadChunk(this.startOffset, this.data);
}

class Lock {
  bool _locked = false;
  final _waiters = <Completer<void>>[];

  Future<T> synchronized<T>(Future<T> Function() action) async {
    while (_locked) {
      final completer = Completer<void>();
      _waiters.add(completer);
      await completer.future;
    }
    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete();
      }
    }
  }
}

/// Reusable HTTP client for YouTube downloads with connection pooling.
/// YouTube throttles connections, so we limit concurrent downloads.
class YoutubeDownloadClient {
  static final HttpClient _sharedClient = HttpClient()
    ..maxConnectionsPerHost = 6
    ..connectionTimeout = const Duration(seconds: 30);

  static HttpClient get instance => _sharedClient;

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String _referer = 'https://www.youtube.com/';

  static Future<HttpClientRequest> createRequest(Uri url, {String? range}) async {
    final req = await _sharedClient.getUrl(url);
    req.headers.set(HttpHeaders.userAgentHeader, _userAgent);
    req.headers.set('Referer', _referer);
    if (range != null) {
      req.headers.set(HttpHeaders.rangeHeader, range);
    }
    return req;
  }
}

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  YoutubeService();

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
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [
        YoutubeApiClient.ios,
        YoutubeApiClient.android,
        YoutubeApiClient.androidVr,
      ],
    );
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    return audioStreamInfo.url.toString();
  }

  Future<File> downloadTrack(
    String videoId,
    String destinationPath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      Log.i('YoutubeService: Starting download for $videoId');
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidVr],
      );

      final muxedStreams = manifest.muxed.toList();
      if (muxedStreams.isEmpty) {
        throw Exception('No standalone muxed streams available for this video.');
      }

      // Use highest bitrate muxed stream for best quality
      final audioStreamInfo = (muxedStreams..sort((a, b) => b.bitrate.compareTo(a.bitrate))).first;
      final totalSize = audioStreamInfo.size.totalBytes;
      final rawUrl = audioStreamInfo.url;

      final file = File(destinationPath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      // Single connection download with progress tracking
      // Note: YouTube throttles multi-connection downloads, so we use single connection
      // which is actually faster due to no overhead of managing chunks
      final progressCompleter = Completer<void>();
      final receivedBytes = List<int>.empty(growable: true);
      int lastReportedPercent = 0;

      final request = await YoutubeDownloadClient.createRequest(rawUrl);
      request.close().then((response) async {
        try {
          await for (final chunk in response) {
            receivedBytes.addAll(chunk);
            if (onProgress != null) {
              final percent = (receivedBytes.length * 100 ~/ totalSize);
              if (percent != lastReportedPercent && percent <= 100) {
                lastReportedPercent = percent;
                onProgress(receivedBytes.length / totalSize);
              }
            }
          }
          progressCompleter.complete();
        } catch (e) {
          progressCompleter.completeError(e);
        }
      }).catchError((e) {
        progressCompleter.completeError(e);
      });

      await progressCompleter.future;

      // Write to file
      await file.writeAsBytes(receivedBytes);

      Log.i('YoutubeService: Download finalized successfully for $videoId');
      return file;
    } catch (e) {
      Log.e('YoutubeService: Download failed for $videoId: $e');
      rethrow;
    }
  }

  /// Downloads a track using parallel chunks for faster speeds.
  /// Use this for large files where YouTube doesn't throttle aggressively.
  Future<File> downloadTrackParallel(
    String videoId,
    String destinationPath, {
    void Function(double progress)? onProgress,
    int connections = 3,
  }) async {
    try {
      Log.i('YoutubeService: Starting parallel download for $videoId ($connections connections)');
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidVr],
      );

      final muxedStreams = manifest.muxed.toList();
      if (muxedStreams.isEmpty) {
        throw Exception('No standalone muxed streams available for this video.');
      }

      final audioStreamInfo = muxedStreams.first;
      final totalSize = audioStreamInfo.size.totalBytes;
      final rawUrl = audioStreamInfo.url;

      final file = File(destinationPath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      final chunkSize = (totalSize / connections).ceil();
      final partResults = List<DownloadChunk?>.filled(connections, null);

      // Atomic progress tracking using a lock
      int totalDownloaded = 0;
      int lastReportedPercent = 0;
      final progressLock = Lock();

      Future<void> downloadPart(int i) async {
        final start = i * chunkSize;
        final end = (start + chunkSize - 1).clamp(0, totalSize - 1);
        if (start >= totalSize) return;

        final req = await YoutubeDownloadClient.createRequest(
          rawUrl,
          range: 'bytes=$start-$end',
        );
        final res = await req.close();

        final bytes = <int>[];
        await for (final chunk in res) {
          bytes.addAll(chunk);
          if (onProgress != null) {
            await progressLock.synchronized(() async {
              totalDownloaded += chunk.length;
              final percent = (totalDownloaded * 100 ~/ totalSize);
              if (percent != lastReportedPercent && percent <= 100) {
                lastReportedPercent = percent;
                onProgress(totalDownloaded / totalSize);
              }
            });
          }
        }
        partResults[i] = DownloadChunk(start, bytes);
      }

      await Future.wait(List.generate(connections, downloadPart));

      // Combine chunks in order
      final sink = file.openWrite();
      for (var i = 0; i < partResults.length; i++) {
        if (partResults[i] != null) {
          sink.add(partResults[i]!.data);
        }
      }
      await sink.flush();
      await sink.close();

      Log.i('YoutubeService: Parallel download finalized for $videoId');
      return file;
    } catch (e) {
      Log.e('YoutubeService: Parallel download failed for $videoId: $e');
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

