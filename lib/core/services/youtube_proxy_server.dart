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
        final manifest = await _yt.videos.streamsClient.getManifest(queryId);
        Log.i('Proxy: Manifest fetched successfully');
        
        final info = manifest.audioOnly.withHighestBitrate();
        Log.i('Proxy: Using audio stream - codec=${info.codec.mimeType}, container=${info.container.name}, bitrate=${info.bitrate.kiloBitsPerSecond}kbps, size=${info.size.totalBytes} bytes');
        
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

        // Stream the audio
        final stream = _yt.videos.streamsClient.get(info);
        
        if (start == 0) {
          await stream.pipe(request.response);
        } else {
          // Efficient byte skipping without expand()
          int bytesToSkip = start;
          await for (final chunk in stream) {
            if (bytesToSkip > 0) {
              if (chunk.length <= bytesToSkip) {
                bytesToSkip -= chunk.length;
                continue;
              } else {
                final remaining = chunk.sublist(bytesToSkip);
                request.response.add(remaining);
                bytesToSkip = 0;
              }
            } else {
              request.response.add(chunk);
            }
          }
          await request.response.close();
        }
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
