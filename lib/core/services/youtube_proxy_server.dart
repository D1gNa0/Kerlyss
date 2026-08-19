import 'dart:io';
import 'dart:convert';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/core/services/stream_resolution_cache.dart';

class _CachedPipedUrl {
  final String url;
  final DateTime resolvedAt;
  _CachedPipedUrl(this.url, this.resolvedAt);
}

/// Shared HTTP client pool for proxy server connections.
/// Reusing connections significantly reduces latency for repeated requests.
class _ProxyHttpClientPool {
  static HttpClient? _client;

  static HttpClient get instance {
    _client ??= HttpClient()
      ..maxConnectionsPerHost = 8
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 60);
    return _client!;
  }

  static void close() {
    _client?.close(force: true);
    _client = null;
  }
}

class YoutubeProxyServer {
  static HttpServer? _server;
  static int? _port;
  static final Map<String, StreamInfo> _streamCache = {};
  static final Map<String, Future<StreamInfo>> _inFlightStreams = {};
  static final Set<String> _audioOnlyFailures = {};

  // Pre-resolved stream URLs cache (reduces YouTube API calls)
  static final Map<String, String> _resolvedUrlCache = {};
  static const _maxUrlCacheSize = 100;
  static final Map<String, _CachedPipedUrl> _pipedUrlCache = {};

  // Cache mapping search query to resolved videoId
  static final Map<String, String> _queryToVideoIdCache = {};

  static String? _lastSuccessfulInstance;


  // Global state for tracking YouTube IP rate limits to prevent laggy retry loops
  static DateTime? _rateLimitExpiry;

  static bool get _isLocalRateLimited {
    if (_rateLimitExpiry == null) return false;
    if (DateTime.now().isAfter(_rateLimitExpiry!)) {
      _rateLimitExpiry = null;
      Log.i('YoutubeProxyServer: Rate limit cooldown expired. Re-enabling YouTube API queries.');
      return false;
    }
    return true;
  }

  static void _reportRateLimit(Object error) {
    if (!_isLocalRateLimited) {
      _rateLimitExpiry = DateTime.now().add(const Duration(minutes: 10));
      Log.e('YoutubeProxyServer: YouTube IP rate limit detected ($error)! Bypassing direct YouTube queries for 10 minutes to guarantee instant start-up.');
    }
  }

  static bool _isRateLimitException(Object e) {
    final str = e.toString().toLowerCase();
    return str.contains('requestlimitexceededexception') ||
        str.contains('429') ||
        str.contains('rate limit') ||
        str.contains('too many requests') ||
        (str.contains('403') && (str.contains('manifest') || str.contains('youtube_explode')));
  }

  static void _evictVideoFromCaches(String videoId) {
    _streamCache.remove(videoId);
    _resolvedUrlCache.remove(videoId);
    _pipedUrlCache.remove(videoId);
    _queryToVideoIdCache.removeWhere((_, id) => id == videoId);
    StreamResolutionCache.instance.removeByVideoId(videoId);
    Log.i('YoutubeProxyServer: Evicted dead videoId=$videoId from resolution caches');
  }

  /// Pre-fetches and caches the stream info for a video in the background.
  static Future<void> prefetchStream(String videoId, YoutubeExplode yt) async {
    try {
      await _getStreamInfo(videoId, yt);
      Log.d('YoutubeProxyServer: Pre-fetched and cached stream info for $videoId');
    } catch (e) {
      Log.w('YoutubeProxyServer: Failed to prefetch stream info for $videoId: $e. Evicting cache...');
      _evictVideoFromCaches(videoId);
      try {
        await _resolvePipedFallbackUrl(videoId);
        Log.d('YoutubeProxyServer: Pre-fetched and cached Piped fallback stream for $videoId');
      } catch (fallbackError) {
        Log.w('YoutubeProxyServer: Piped prefetch fallback failed for $videoId: $fallbackError');
      }
    }
  }

  static Future<StreamInfo> _getStreamInfo(String videoId, YoutubeExplode yt) async {
    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId]!;
    }
    
    if (_inFlightStreams.containsKey(videoId)) {
      return await _inFlightStreams[videoId]!;
    }

    final future = _fetchStreamInfo(videoId, yt);
    _inFlightStreams[videoId] = future;
    
    try {
      final info = await future;
      _streamCache[videoId] = info;
      return info;
    } finally {
      _inFlightStreams.remove(videoId);
    }
  }

  static Future<StreamInfo> _fetchStreamInfo(String videoId, YoutubeExplode yt) async {
    StreamManifest? manifest;
    Object? lastError;

    final clientOptions = [
      [YoutubeApiClient.android],
      [YoutubeApiClient.ios],
      [YoutubeApiClient.androidVr],
      <YoutubeApiClient>[], // default client list fallback
    ];

    for (final clients in clientOptions) {
      try {
        if (clients.isEmpty) {
          manifest = await yt.videos.streamsClient.getManifest(videoId);
        } else {
          manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: clients);
        }
        if (manifest.audioOnly.isNotEmpty || manifest.muxed.isNotEmpty) {
          break;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (manifest == null) {
      throw lastError ?? Exception('No compatible streams available for video $videoId.');
    }

    StreamInfo info;
    final audioStreams = manifest.audioOnly.toList();
    final hasFailedAudio = _audioOnlyFailures.contains(videoId);

    if (audioStreams.isNotEmpty && !hasFailedAudio) {
      // Prioritize high-quality audio-only stream (AAC/Opus) which uses 70% LESS data than video (~3-5MB total)
      audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      info = audioStreams.first;
      Log.i('YoutubeProxyServer: Selected pure audio-only stream for $videoId (${(info.bitrate.bitsPerSecond / 1000).toStringAsFixed(0)} kbps)');
    } else {
      // Fallback to lowest-bitrate muxed stream if audio-only fails or is unavailable (extremely stable)
      final muxedStreams = manifest.muxed.toList();
      if (muxedStreams.isNotEmpty) {
        muxedStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
        info = muxedStreams.first;
        Log.w('YoutubeProxyServer: Selected lowest-bitrate muxed fallback stream for $videoId (Audio failure or unavailable)');
      } else {
        // Ultimate fallback to whatever is available
        if (audioStreams.isNotEmpty) {
          audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
          info = audioStreams.first;
        } else {
          throw Exception('No compatible streams available for video $videoId.');
        }
      }
    }

    return info;
  }

  /// Starts the proxy server if it is not already running.
  /// Returns the local port the server is listening on.
  static Future<int> start(YoutubeExplode yt) async {
    if (_server != null && _port != null) return _port!;


    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    Log.i('YoutubeProxyServer started on port $_port');

    _server!.listen((HttpRequest request) async {
      final queryId = request.uri.queryParameters['id'];
      final queryStr = request.uri.queryParameters['query'];
      final deezerId = request.uri.queryParameters['deezer_id'];

      Log.i('🌐 [PROXY_REQ] Request received -> queryId=$queryId, queryStr="$queryStr", deezerId=$deezerId');

      if ((queryId == null || queryId.isEmpty) && 
          (queryStr == null || queryStr.isEmpty) &&
          (deezerId == null || deezerId.isEmpty)) {
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }

      String videoId = '';
      bool headersSent = false;
      try {
        if (queryId != null && queryId.isNotEmpty) {
          videoId = queryId;
        } else if (deezerId != null && deezerId.isNotEmpty && StreamResolutionCache.instance.has(deezerId)) {
          videoId = StreamResolutionCache.instance.get(deezerId)!;
          Log.i('YoutubeProxyServer: Deezer ID cache HIT → $videoId');
        } else if (queryStr != null && queryStr.isNotEmpty && _queryToVideoIdCache.containsKey(queryStr)) {
          videoId = _queryToVideoIdCache[queryStr]!;
          Log.i('YoutubeProxyServer: Query cache HIT → $videoId');
        }

        // Check if explicit video ID is invalid format (e.g. test stubs like remote_youtube_123)
        if (videoId.isNotEmpty && !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoId) && (queryStr == null || queryStr.isEmpty)) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }

        // Lazy Resolution: If no explicit video ID was provided, perform the search on the fly!
        if (videoId.isEmpty && queryStr != null && queryStr.isNotEmpty) {
          Log.i('YoutubeProxyServer: Lazily resolving query "$queryStr"...');
          
          if (!_isLocalRateLimited) {
            try {
              Log.i('YoutubeProxyServer: Trying direct YouTube search...');
              final searchList = await yt.search.search(queryStr);
              final videos = searchList.where((v) => (v.duration?.inMinutes ?? 0) < 10).take(5).toList();
              if (videos.isNotEmpty) {
                videoId = videos.first.id.value;
              } else {
                throw Exception('No videos found for query: $queryStr');
              }
            } catch (searchError) {
              Log.w('YoutubeProxyServer: Direct YouTube search failed: $searchError. Trying Piped fallback...');
              if (_isRateLimitException(searchError)) {
                _reportRateLimit(searchError);
              }
              final fallbackId = await _searchPipedFallback(queryStr);
              if (fallbackId != null) {
                videoId = fallbackId;
              } else {
                rethrow;
              }
            }
          } else {
            Log.i('YoutubeProxyServer: YouTube is rate-limited. Skipping direct search and trying Piped...');
            final fallbackId = await _searchPipedFallback(queryStr);
            if (fallbackId != null) {
              videoId = fallbackId;
            } else {
              throw Exception('YouTube rate-limited and Piped search fallback failed for query: $queryStr');
            }
          }

          // Cache resolved video ID to prevent redundant subsequent queries
          if (videoId.isNotEmpty) {
            if (deezerId != null && deezerId.isNotEmpty) {
              StreamResolutionCache.instance.put(deezerId, videoId);
            }
            _queryToVideoIdCache[queryStr] = videoId;
          }
        }

        // Double check cache before manifest resolution (e.g. if resolved during search fallback)
        if (_pipedUrlCache.containsKey(videoId)) {
          final cached = _pipedUrlCache[videoId]!;
          if (DateTime.now().difference(cached.resolvedAt) < const Duration(hours: 2)) {
            Log.i('YoutubeProxyServer: Cache HIT for Piped fallback stream → ${cached.url}');
            request.response.statusCode = HttpStatus.movedTemporarily; // 302
            request.response.headers.set(HttpHeaders.locationHeader, cached.url);
            await request.response.close();
            return;
          } else {
            _pipedUrlCache.remove(videoId);
          }
        }

        StreamInfo? info;
        String? resolvedFallbackUrl;

        if (!_isLocalRateLimited) {
          try {
            Log.i('YoutubeProxyServer: Trying direct YouTube stream extraction...');
            info = await _getStreamInfo(videoId, yt);
          } catch (streamError) {
            Log.w('YoutubeProxyServer: Direct YouTube stream extraction failed: $streamError. Evicting cache...');
            _evictVideoFromCaches(videoId);
            if (streamError is ArgumentError) {
              request.response.statusCode = HttpStatus.badRequest;
              await request.response.close();
              return;
            }
            if (_isRateLimitException(streamError)) {
              _reportRateLimit(streamError);
            }
            resolvedFallbackUrl = await _resolvePipedFallbackUrl(videoId);
            if (resolvedFallbackUrl == null) {
              rethrow;
            }
          }
        } else {
          Log.i('YoutubeProxyServer: YouTube is rate-limited. Skipping direct stream extraction and trying Piped...');
          resolvedFallbackUrl = await _resolvePipedFallbackUrl(videoId);
          if (resolvedFallbackUrl == null) {
            throw Exception('YouTube rate-limited and Piped stream fallback failed for videoId: $videoId');
          }
        }

        if (resolvedFallbackUrl != null) {
          Log.i('YoutubeProxyServer: Redirecting audio player to Piped stream: $resolvedFallbackUrl');
          request.response.statusCode = HttpStatus.movedTemporarily; // 302
          request.response.headers.set(HttpHeaders.locationHeader, resolvedFallbackUrl);
          await request.response.close();
          return;
        }


        if (info == null) {
          throw Exception('Failed to resolve stream info');
        }
        final streamInfo = info;

        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        final totalBytes = streamInfo.size.totalBytes > 0 ? streamInfo.size.totalBytes : 1;
        int start = 0;
        int end = totalBytes - 1;

        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          final parts = rangeHeader.substring(6).split('-');
          if (parts[0].isNotEmpty) {
            start = int.tryParse(parts[0]) ?? 0;
          }
          if (parts.length > 1 && parts[1].isNotEmpty) {
            end = int.tryParse(parts[1]) ?? (totalBytes - 1);
          }

          if (start < 0) start = 0;
          if (end >= totalBytes) end = totalBytes - 1;
          if (end < start) {
            end = totalBytes - 1;
          }
        }

        final isPartialRequest = rangeHeader != null;

        // User-Agent selection logic
        String userAgentForStreamUrl(Uri url) {
          final clientParam = url.queryParameters['c']?.toUpperCase() ?? '';
          if (clientParam.contains('IOS')) {
            return AetherColors.iosUserAgent;
          }
          return AetherColors.androidUserAgent;
        }

        Future<void> pipeFromUpstream(StreamInfo upstreamInfo, {bool isHeadRequest = false}) async {
          // Use shared client pool instead of creating new client per request
          final client = _ProxyHttpClientPool.instance;
          
          Uri targetUrl = upstreamInfo.url;
          bool useRangeHeader = false;
          
          if (isPartialRequest) {
            if (targetUrl.queryParameters['c'] == 'ANDROID') {
              useRangeHeader = true;
            } else {
              // Non-Android clients (e.g. WEB) require the range in the query params, NOT the header
              final newParams = Map<String, dynamic>.from(targetUrl.queryParameters);
              newParams['range'] = '$start-$end';
              targetUrl = targetUrl.replace(queryParameters: newParams);
            }
          }

          final httpRequest = await client.getUrl(targetUrl);

          // YouTube blocks default 'Dart/3.x' User-Agents with a 403 Forbidden.
          // We must mask the request to match the client that generated the URL.
          final userAgent = userAgentForStreamUrl(upstreamInfo.url);
          httpRequest.headers.set(HttpHeaders.userAgentHeader, userAgent);
          httpRequest.headers.set('Referer', 'https://www.youtube.com/');

          if (useRangeHeader) {
            httpRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
          }

          final httpResponse = await httpRequest.close();
          if (httpResponse.statusCode != HttpStatus.ok &&
              httpResponse.statusCode != HttpStatus.partialContent) {
            throw HttpException(
              'Upstream returned status ${httpResponse.statusCode}',
              uri: upstreamInfo.url,
            );
          }

          // Authoritative content length from upstream response
          int upstreamLength = httpResponse.contentLength;
          if (upstreamLength <= 0) {
            upstreamLength = end - start + 1;
          }

          // Write headers
          request.response.statusCode = isPartialRequest ? HttpStatus.partialContent : HttpStatus.ok;
          request.response.headers.contentType = ContentType.parse(upstreamInfo.codec.mimeType);
          request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
          request.response.headers.set(HttpHeaders.contentLengthHeader, upstreamLength.toString());
          if (isPartialRequest) {
            final upstreamRange = httpResponse.headers.value(HttpHeaders.contentRangeHeader);
            if (upstreamRange != null) {
              request.response.headers.set(HttpHeaders.contentRangeHeader, upstreamRange);
            } else {
              request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$totalBytes');
            }
          }
          request.response.headers.set('Access-Control-Allow-Origin', '*');

          headersSent = true;

          if (isHeadRequest) {
            return;
          }

          try {
            // Using addStream handles backpressure and automatically stops 
            // reading from upstream if the client (just_audio) disconnects.
            await request.response.addStream(httpResponse);
          } catch (e) {
            Log.d('YoutubeProxyServer: Stream ended or interrupted mid-transfer for $videoId: $e');
          }
        }

        bool isRecoverableError(Object error) {
          final errorStr = error.toString().toLowerCase();
          return errorStr.contains('403') ||
              errorStr.contains('forbidden') ||
              errorStr.contains('upstream returned status') ||
              errorStr.contains('socketexception') ||
              errorStr.contains('connection');
        }

        try {
          await pipeFromUpstream(streamInfo, isHeadRequest: request.method == 'HEAD');
        } catch (e) {
          Log.w('YoutubeProxyServer: Initial attempt failed for $videoId: $e');

          if (isRecoverableError(e) && !headersSent) {
            Log.i('YoutubeProxyServer: Detected recoverable error - registering audio-only failure if applicable');
            if (streamInfo is AudioOnlyStreamInfo) {
              _audioOnlyFailures.add(videoId);
              Log.w('YoutubeProxyServer: Audio-only stream failed with 403 for $videoId. Flagged for muxed fallback.');
            }

            for (int attempt = 1; attempt <= 2; attempt++) {
              try {
                if (headersSent) break;
                _streamCache.remove(videoId);

                Log.w('YoutubeProxyServer: Immediate retry attempt $attempt for videoId=$videoId (switching to muxed fallback)...');

                final retryInfo = await _getStreamInfo(videoId, yt);
                await pipeFromUpstream(retryInfo, isHeadRequest: request.method == 'HEAD');
                Log.i('YoutubeProxyServer: Retry $attempt succeeded');
                break;
              } catch (retryError) {
                Log.w('YoutubeProxyServer: Retry $attempt failed: $retryError');
                if (attempt == 2) {
                  rethrow;
                }
              }
            }
          } else {
            rethrow;
          }
        }

        try {
          await request.response.close();
        } catch (_) {}

      } catch (e) {
        Log.e('Proxy Error for videoId=$videoId: $e');
        if (!headersSent) {
          try {
            request.response.statusCode = 500;
          } catch (_) {}
        }
        try {
          await request.response.close();
        } catch (_) {}
      }
    });

    return _port!;
  }

  /// Clears all caches (stream info, URLs, and HTTP client pool).
  /// Call this when YouTube throttling is suspected.
  static void clearCaches() {
    _streamCache.clear();
    _resolvedUrlCache.clear();
    _ProxyHttpClientPool.close();
    Log.i('YoutubeProxyServer: All caches cleared');
  }

  /// Gets cached stream URL if available.
  /// Returns null if not cached.
  static String? getCachedUrl(String videoId) {
    return _resolvedUrlCache[videoId];
  }

  /// Gets cached stream info for a song ID (either mapped directly or resolved through cache).
  static StreamInfo? getStreamInfoForSong(String songId) {
    if (_streamCache.containsKey(songId)) {
      return _streamCache[songId];
    }
    if (StreamResolutionCache.instance.has(songId)) {
      final videoId = StreamResolutionCache.instance.get(songId);
      if (videoId != null && _streamCache.containsKey(videoId)) {
        return _streamCache[videoId];
      }
    }
    return null;
  }

  /// Adds a resolved URL to the cache.
  static void cacheUrl(String videoId, String url) {
    if (_resolvedUrlCache.length >= _maxUrlCacheSize) {
      // Remove oldest entries (simple eviction)
      final keysToRemove = _resolvedUrlCache.keys.take(_maxUrlCacheSize ~/ 4).toList();
      for (final key in keysToRemove) {
        _resolvedUrlCache.remove(key);
      }
    }
    _resolvedUrlCache[videoId] = url;
  }

  /// Resolves the direct stream URL for a given video ID using decentralized Piped API instance rotation.
  static Future<String?> _resolvePipedFallbackUrl(String videoId) async {
    final baseInstances = [
      'https://api.piped.private.coffee',
      'https://pipedapi.kavin.rocks',
    ];

    // Try last successful instance first to avoid iteration latency
    final instances = List<String>.from(baseInstances);
    if (_lastSuccessfulInstance != null) {
      instances.remove(_lastSuccessfulInstance);
      instances.insert(0, _lastSuccessfulInstance!);
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 1500);

    for (final instance in instances) {
      try {
        final uri = Uri.parse('$instance/streams/$videoId');
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final bodyJson = await response.transform(utf8.decoder).join();
          final data = jsonDecode(bodyJson) as Map<String, dynamic>;
          final audioStreams = data['audioStreams'] as List<dynamic>?;

          if (audioStreams != null && audioStreams.isNotEmpty) {
            // Sort streams by quality/bitrate in descending order
            audioStreams.sort((a, b) {
              final aBitrate = a['bitrate'] as int? ?? 0;
              final bBitrate = b['bitrate'] as int? ?? 0;
              return bBitrate.compareTo(aBitrate);
            });

            final bestStream = audioStreams.first as Map<String, dynamic>;
            final streamUrl = bestStream['url'] as String?;
            if (streamUrl != null && streamUrl.isNotEmpty) {
              Log.i('YoutubeProxyServer: Resolved Piped stream URL from $instance');
              _lastSuccessfulInstance = instance; // Cache successful instance
              _pipedUrlCache[videoId] = _CachedPipedUrl(streamUrl, DateTime.now());
              return streamUrl;
            }
          }
        }
      } catch (e) {
        Log.w('YoutubeProxyServer: Piped fallback failed for instance $instance: $e');
        if (instance == _lastSuccessfulInstance) {
          _lastSuccessfulInstance = null; // Reset if failed
        }
      }
    }
    return null;
  }

  /// Searches for a video ID on decentralized Piped API instances as a fallback for lazy search queries.
  static Future<String?> _searchPipedFallback(String queryStr) async {
    final baseInstances = [
      'https://api.piped.private.coffee',
      'https://pipedapi.kavin.rocks',
    ];

    final instances = List<String>.from(baseInstances);
    if (_lastSuccessfulInstance != null) {
      instances.remove(_lastSuccessfulInstance);
      instances.insert(0, _lastSuccessfulInstance!);
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 1500);

    for (final instance in instances) {
      try {
        final uri = Uri.parse('$instance/search?q=${Uri.encodeComponent(queryStr)}&filter=videos');
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final bodyJson = await response.transform(utf8.decoder).join();
          final data = jsonDecode(bodyJson) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>?;

          if (items != null && items.isNotEmpty) {
            for (final item in items) {
              final map = item as Map<String, dynamic>;
              final url = map['url'] as String?;
              final duration = map['duration'] as int? ?? 0;

              // Filter for videos under 10 minutes (prevents capturing long compilations)
              if (url != null && url.contains('watch?v=') && duration < 600) {
                final videoId = url.split('watch?v=').last;
                if (videoId.isNotEmpty) {
                  Log.i('YoutubeProxyServer: Resolved Piped query "$queryStr" → $videoId via $instance');
                  _lastSuccessfulInstance = instance; // Cache successful instance
                  return videoId;
                }
              }
            }
          }
        }
      } catch (e) {
        Log.w('YoutubeProxyServer: Piped search fallback failed for instance $instance: $e');
        if (instance == _lastSuccessfulInstance) {
          _lastSuccessfulInstance = null; // Reset if failed
        }
      }
    }
    return null;
  }

  /// Stops the proxy server and cleans up resources.
  static Future<void> stop() async {
    _server?.close(force: true);
    _server = null;
    _port = null;
    _ProxyHttpClientPool.close();
    clearCaches();
    Log.i('YoutubeProxyServer: Server stopped');
  }
}
