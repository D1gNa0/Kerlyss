import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:kerlyss/core/services/logger_service.dart';

class YoutubeProxyServer {
  static HttpServer? _server;
  static int? _port;

  /// Starts the proxy server if it is not already running.
  /// Returns the local port the server is listening on.
  static Future<int> start(YoutubeExplode yt) async {
    if (_server != null && _port != null) return _port!;


    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    Log.i('YoutubeProxyServer started on port $_port');

    _server!.listen((HttpRequest request) async {
      final queryId = request.uri.queryParameters['id'];
      
      if (queryId == null || queryId.isEmpty) {
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }

      try {
        final manifest = await yt.videos.streamsClient.getManifest(
          queryId,
          ytClients: [YoutubeApiClient.androidVr],
        );

        final muxedStreams = manifest.muxed.toList();
        if (muxedStreams.isEmpty) {
          throw Exception('No standalone muxed streams available.');
        }

        final info = (muxedStreams..sort((a, b) => b.bitrate.compareTo(a.bitrate))).first;
        
        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        int start = 0;
        int end = info.size.totalBytes - 1;

        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          final parts = rangeHeader.substring(6).split('-');
          if (parts[0].isNotEmpty) {
            start = int.tryParse(parts[0]) ?? 0;
          }
          if (parts.length > 1 && parts[1].isNotEmpty) {
            end = int.tryParse(parts[1]) ?? (info.size.totalBytes - 1);
          }

          if (start < 0) start = 0;
          if (end >= info.size.totalBytes) end = info.size.totalBytes - 1;
          if (end < start) {
            end = info.size.totalBytes - 1;
          }
        }

        request.response.statusCode = start > 0 ? HttpStatus.partialContent : HttpStatus.ok;
        request.response.headers.contentType = ContentType.parse(info.codec.mimeType);
        request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        request.response.headers.set(HttpHeaders.contentLengthHeader, (end - start + 1).toString());
        request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/${info.size.totalBytes}');
        request.response.headers.set('Access-Control-Allow-Origin', '*');

        if (request.method == 'HEAD') {
          await request.response.close();
          return;
        }

        final httpRequest = await HttpClient().getUrl(info.url);
        httpRequest.headers.set(HttpHeaders.userAgentHeader,
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        httpRequest.headers.set('Referer', 'https://www.youtube.com/');
        if (start > 0) {
          httpRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
        }

        final httpResponse = await httpRequest.close();
        await for (final List<int> chunk in httpResponse) {
          request.response.add(chunk);
        }
        await request.response.close();

      } catch (e) {
        Log.e('Proxy Error for videoId=$queryId: $e');
        try {
          request.response.statusCode = 500;
          await request.response.close();
        } catch (_) {}
      }
    });

    return _port!;
  }
}
