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
      Log.i('Proxy: [${request.method}] ${request.uri.path} ?id=$queryId from ${request.connectionInfo?.remoteAddress.address}:${request.connectionInfo?.remotePort}');
      
      if (queryId == null || queryId.isEmpty) {
        Log.w('Proxy: Missing or empty video ID in query');
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }

      try {
        Log.i('Proxy: Fetching YouTube manifest for videoId=$queryId...');
        final manifest = await yt.videos.streamsClient.getManifest(
          queryId,
          ytClients: [YoutubeApiClient.androidVr],
        );

        Log.i('Proxy: Manifest fetched successfully');
        
        // We MUST use 'muxed' streams for Windows playback compatibility.
        // DASH fragments (audioOnly) are not supported by WMF via the proxy.
        final muxedStreams = manifest.muxed.toList();
        if (muxedStreams.isEmpty) {
          throw Exception('No standalone muxed streams available.');
        }

        final info = (muxedStreams..sort((a, b) => b.bitrate.compareTo(a.bitrate))).first;
        Log.i('Proxy: Using STANDALONE muxed stream - Bitrate: ${info.bitrate.kiloBitsPerSecond}kbps, Quality: ${info.videoQuality}');


        
        // Support HTTP Range requests for seeking
        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        int start = 0;
        int end = info.size.totalBytes - 1;

        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          final parts = rangeHeader.substring(6).split('-');
          if (parts[0].isNotEmpty) start = int.parse(parts[0]);
          if (parts.length > 1 && parts[1].isNotEmpty) end = int.parse(parts[1]);
          Log.i('Proxy: Range request - bytes $start-$end (total: ${info.size.totalBytes})');
        }

        request.response.statusCode = start > 0 ? HttpStatus.partialContent : HttpStatus.ok;
        request.response.headers.contentType = ContentType.parse(info.codec.mimeType);
        request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        request.response.headers.set(HttpHeaders.contentLengthHeader, (end - start + 1).toString());
        request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/${info.size.totalBytes}');
        request.response.headers.set('Access-Control-Allow-Origin', '*');

        if (request.method == 'HEAD') {
          Log.i('Proxy: HEAD request, closing without body');
          await request.response.close();
          return;
        }

        Log.i('Proxy: Streaming audio...');

        // youtube_explode stream client hangs on Windows — use raw HttpClient instead
        final rawUrl = info.url;
        final httpClient = HttpClient();
        final httpRequest = await httpClient.getUrl(rawUrl);
        httpRequest.headers.set(HttpHeaders.userAgentHeader,
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        httpRequest.headers.set('Referer', 'https://www.youtube.com/');
        if (start > 0) {
          httpRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
        }

        final httpResponse = await httpRequest.close();
        Log.i('Proxy: CDN responded with ${httpResponse.statusCode}');

        await for (final List<int> chunk in httpResponse) {
          request.response.add(chunk);
        }

        await request.response.close();
        httpClient.close();
        Log.i('Proxy: Stream completed successfully');


      } catch (e, stacktrace) {
        Log.e('Proxy Error getting manifest for videoId=$queryId: $e');
        Log.e('Stack: $stacktrace');

        try {
          request.response.statusCode = 500;
          request.response.write('Proxy Error: $e');
          await request.response.close();
        } catch (_) {}
      }
    });

    return _port!;
  }
}
