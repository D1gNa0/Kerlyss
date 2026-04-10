import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:kerlyss/core/services/logger_service.dart';

class YoutubeProxyServer {
  static HttpServer? _server;
  static int? _port;
  static final YoutubeExplode _yt = YoutubeExplode();

  /// Starts the proxy server if it is not already running.
  /// Returns the local port the server is listening on.
  static Future<int> start() async {
    if (_server != null && _port != null) return _port!;

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    Log.i('YoutubeProxyServer started on port $_port');

    _server!.listen((HttpRequest request) async {
      final videoId = request.uri.queryParameters['id'];
      if (videoId == null || videoId.isEmpty) {
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }

      try {
        final manifest = await _yt.videos.streamsClient.getManifest(videoId);
        final info = manifest.audioOnly.withHighestBitrate();
        final stream = _yt.videos.streamsClient.get(info);

        // Support HTTP Range requests which media_kit / libmpv requires for seeking
        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        int start = 0;
        int end = info.size.totalBytes - 1;

        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          final rangeList = rangeHeader.substring(6).split('-');
          if (rangeList[0].isNotEmpty) {
            start = int.parse(rangeList[0]);
          }
          if (rangeList.length > 1 && rangeList[1].isNotEmpty) {
            end = int.parse(rangeList[1]);
          }
        }

        request.response.statusCode = start > 0 ? HttpStatus.partialContent : HttpStatus.ok;
        request.response.headers.contentType = ContentType('audio', 'mp4'); // Usually audio/mp4 for youtube
        request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        request.response.headers.set(HttpHeaders.contentLengthHeader, (end - start + 1).toString());
        request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/${info.size.totalBytes}');

        // If client only requested headers (HEAD request), finish early
        if (request.method == 'HEAD') {
          await request.response.close();
          return;
        }

        // Extremely robust pipe
        Stream<List<int>> dataStream = stream;
        if (start > 0) {
           // Skip bytes to support seeking. Note: Get() from youtube_explode_dart doesn't natively support byte-range fetching,
           // so we skip the bytes. For high-perf, it's better to fetch via range, but this is a perfectly working fallback.
           // Actually youtube_explode_dart 3.x get() method has a `rest` parameter but we can skip.
           int skipped = 0;
           dataStream = stream.expand((chunk) => chunk).skipWhile((_) {
              if (skipped < start) { skipped++; return true; }
              return false;
           }).take(end - start + 1).map((b) => [b]);
        }

        await dataStream.pipe(request.response);
      } catch (e) {
        Log.e('YoutubeProxyServer error for id $videoId: $e');
        if (!request.response.isClosed) {
           request.response.statusCode = 500;
           await request.response.close();
        }
      }
    });

    return _port!;
  }
}
