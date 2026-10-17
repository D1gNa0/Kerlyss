import 'dart:io';
import 'dart:convert';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/core/services/stream_resolution_cache.dart';
import 'package:kerlyss/main.dart';

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

  // All playable options for a video, best first. A 403 falls back to the next option WITHOUT
  // fetching the manifest again (the manifest request was the slow part of every retry).
  static final Map<String, List<StreamInfo>> _candidateCache = {};
  static final Set<String> _pendingAudioOnlyFailure = {};
  static DateTime? _audioOnlyBlockedUntil;
  static final Map<String, DateTime> _clientBlockedUntil = {};
  static String? _lastGoodClient;
  static final Map<String, DateTime> _recentManifest403s = {};
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
      Log.event('YoutubeProxyServer: Rate limit cooldown expired. Re-enabling YouTube API queries.');
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
        str.contains('too many requests');
  }

  /// A 403 while reading ONE video's manifest is not an IP block (age/region lock, one broken video...).
  /// Only when 3 DIFFERENT videos fail that way within a minute do we switch to the slow Piped route.
  static bool _shouldTripRateLimit(Object e, String videoId) {
    if (_isRateLimitException(e)) return true;
    final str = e.toString().toLowerCase();
    if (str.contains('403') && (str.contains('manifest') || str.contains('youtube_explode'))) {
      final now = DateTime.now();
      _recentManifest403s.removeWhere((_, t) => now.difference(t) > const Duration(minutes: 1));
      _recentManifest403s[videoId] = now;
      return _recentManifest403s.length >= 3;
    }
    return false;
  }

  static void _evictVideoFromCaches(String videoId) {
    _streamCache.remove(videoId);
    _candidateCache.remove(videoId);
    _resolvedUrlCache.remove(videoId);
    _pipedUrlCache.remove(videoId);
    _queryToVideoIdCache.removeWhere((_, id) => id == videoId);
    StreamResolutionCache.instance.removeByVideoId(videoId);
    Log.d('YoutubeProxyServer: Evicted dead videoId=$videoId from resolution caches');
  }

  /// Pre-fetches and caches the stream info for a video in the background.
  static Future<void> prefetchStream(String videoId, YoutubeExplode yt) async {
    try {
      await _getStreamInfo(videoId, yt);
      Log.d('YoutubeProxyServer: Pre-fetched and cached stream info for $videoId');
    } catch (e) {
      Log.d('YoutubeProxyServer: Failed to prefetch stream info for $videoId: $e. Evicting cache...');
      _evictVideoFromCaches(videoId);
      try {
        await _resolvePipedFallbackUrl(videoId);
        Log.d('YoutubeProxyServer: Pre-fetched and cached Piped fallback stream for $videoId');
      } catch (fallbackError) {
        Log.d('YoutubeProxyServer: Piped prefetch fallback failed for $videoId: $fallbackError');
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
    final candidates = await _fetchCandidates(videoId, yt);
    _candidateCache[videoId] = candidates;
    return candidates.first;
  }

  // ───────────────── learned YouTube behaviour (so we never pay for the same 403 twice) ─────────────────

  static final Map<String, YoutubeApiClient> _clientsByName = {
    'ANDROID': YoutubeApiClient.android,
    'IOS': YoutubeApiClient.ios,
    'ANDROID_VR': YoutubeApiClient.androidVr,
  };

  static bool _stillBlocked(DateTime? until) => until != null && DateTime.now().isBefore(until);

  static bool get _audioOnlyBlocked => _stillBlocked(_audioOnlyBlockedUntil);

  /// Which YouTube client produced this stream URL ("ANDROID", "IOS", "ANDROID_VR").
  static String? _clientOf(StreamInfo info) => info.url.queryParameters['c']?.toUpperCase();

  static String _describe(StreamInfo info) =>
      '${info is AudioOnlyStreamInfo ? 'audio' : 'muxed'} ${(info.bitrate.bitsPerSecond / 1000).round()}kbps';

  /// Clients to try, best first: the one that worked last time, then the others. Clients that
  /// recently returned only broken (403) streams are skipped. If ALL are blocked, try them all.
  static List<String> _clientTryOrder() {
    final all = _clientsByName.keys.toList();
    final good = _lastGoodClient;
    final ordered = <String>[
      if (good != null && !_stillBlocked(_clientBlockedUntil[good])) good,
      ...all.where((c) => c != good && !_stillBlocked(_clientBlockedUntil[c])),
    ];
    return ordered.isEmpty ? all : ordered;
  }

  /// Fetches the manifest and returns up to 3 playable options, best first.
  /// Audio-only is preferred (smaller, faster start, better quality) unless this session already
  /// learned that YouTube refuses audio-only; then the light muxed stream goes first.
  static Future<List<StreamInfo>> _fetchCandidates(String videoId, YoutubeExplode yt) async {
    StreamManifest? manifest;
    String? manifestClient;
    Object? lastError;
    final stopwatch = Stopwatch()..start();

    // null = the library's default client list (last resort)
    final attempts = <String?>[..._clientTryOrder(), null];
    for (final clientName in attempts) {
      try {
        final Future<StreamManifest> request = clientName == null
            ? yt.videos.streamsClient.getManifest(videoId)
            : yt.videos.streamsClient.getManifest(videoId, ytClients: [_clientsByName[clientName]!]);
        // A client that hangs must not stall the song: give up after 6 s and try the next one.
        final candidate = await request.timeout(const Duration(seconds: 6));
        if (candidate.audioOnly.isNotEmpty || candidate.muxed.isNotEmpty) {
          manifest = candidate;
          manifestClient = clientName;
          break;
        }
      } catch (e) {
        lastError = e;
        Log.d('YoutubeProxyServer: Manifest via ${clientName ?? 'default'} failed for $videoId: $e');
      }
    }
    Log.d('⏱ [TIMING] manifest for $videoId took ${stopwatch.elapsedMilliseconds} ms (client: ${manifestClient ?? 'none'})');

    if (manifest == null) {
      throw lastError ?? Exception('No compatible streams available for video $videoId.');
    }

    var muxedStreams = <MuxedStreamInfo>[];
    var audioStreams = <AudioOnlyStreamInfo>[];
    try {
      if (manifest.muxed.isNotEmpty) muxedStreams = manifest.muxed.toList();
    } catch (_) {}
    try {
      if (manifest.audioOnly.isNotEmpty) audioStreams = manifest.audioOnly.toList();
    } catch (_) {}

    audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate)); // best quality first
    muxedStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate)); // lightest first

    final candidates = <StreamInfo>[];
    if (_audioOnlyBlocked) {
      candidates
        ..addAll(muxedStreams.take(1))
        ..addAll(audioStreams.take(1))
        ..addAll(muxedStreams.skip(1).take(1));
    } else {
      candidates
        ..addAll(audioStreams.take(1))
        ..addAll(muxedStreams.take(1))
        ..addAll(audioStreams.skip(1).take(1));
    }

    if (candidates.isEmpty) {
      throw Exception('No compatible streams available for video $videoId.');
    }
    Log.d('YoutubeProxyServer: Options for $videoId: ${candidates.map(_describe).join(' > ')}');
    return candidates;
  }

  /// Called when YouTube refused [failed] (403 etc.). Returns the next option to try.
  /// Uses the options we already have (instant, no new manifest request). Only when all of
  /// them failed does it block that YouTube client for a while and fetch with another one.
  static Future<StreamInfo> _nextStreamAfterFailure(String videoId, YoutubeExplode yt, StreamInfo failed) async {
    if (failed is AudioOnlyStreamInfo) _pendingAudioOnlyFailure.add(videoId);

    final list = _candidateCache[videoId];
    if (list != null) {
      final index = list.indexWhere((s) => identical(s, failed) || s.url == failed.url);
      if (index >= 0 && index + 1 < list.length) {
        final next = list[index + 1];
        _streamCache[videoId] = next;
        Log.w('YoutubeProxyServer: ${_describe(failed)} refused for $videoId. Switching to ${_describe(next)} (no new manifest needed).');
        return next;
      }
    }

    final client = _clientOf(failed);
    if (client != null) {
      _clientBlockedUntil[client] = DateTime.now().add(const Duration(minutes: 10));
      if (_lastGoodClient == client) _lastGoodClient = null;
      Log.w('YoutubeProxyServer: All options from client $client failed for $videoId. Blocking that client for 10 minutes.');
    }
    _streamCache.remove(videoId);
    _candidateCache.remove(videoId);
    return await _getStreamInfo(videoId, yt);
  }

  /// Called as soon as upstream accepted [used]. Remembers what works.
  static void _onStreamSuccess(String videoId, StreamInfo used) {
    final client = _clientOf(used);
    if (client != null) _lastGoodClient = client;

    if (used is MuxedStreamInfo && _pendingAudioOnlyFailure.remove(videoId)) {
      // Audio-only was refused but muxed worked: go muxed-first for the next 30 minutes.
      _audioOnlyBlockedUntil = DateTime.now().add(const Duration(minutes: 30));
      Log.w('YoutubeProxyServer: Audio-only streams are being refused. Using muxed first for 30 minutes.');
    } else if (used is AudioOnlyStreamInfo) {
      _pendingAudioOnlyFailure.remove(videoId);
    }
  }

  /// Starts the proxy server if it is not already running.
  /// Returns the local port the server is listening on.
  static Future<int> start(YoutubeExplode yt) async {
    // Remembered deezerId -> videoId pairs from earlier sessions (skips the YouTube search for replays).
    await StreamResolutionCache.instance.load();

    if (_server != null && _port != null) return _port!;


    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    Log.d('YoutubeProxyServer started on port $_port');

    _server!.listen((HttpRequest request) async {
      final queryId = request.uri.queryParameters['id'];
      final queryStr = request.uri.queryParameters['query'];
      final deezerId = request.uri.queryParameters['deezer_id'];
      final requestStopwatch = Stopwatch()..start();

      Log.d('🌐 [PROXY_REQ] Request received -> queryId=$queryId, queryStr="$queryStr", deezerId=$deezerId');

      if (AetherHttpOverrides.isOfflineMode) {
        Log.d('YoutubeProxyServer: Offline mode active — rejecting proxy request.');
        request.response.statusCode = HttpStatus.serviceUnavailable;
        request.response.write('Offline Mode Active');
        await request.response.close();
        return;
      }

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
          Log.d('YoutubeProxyServer: Deezer ID cache HIT → $videoId');
        } else if (queryStr != null && queryStr.isNotEmpty && _queryToVideoIdCache.containsKey(queryStr)) {
          videoId = _queryToVideoIdCache[queryStr]!;
          Log.d('YoutubeProxyServer: Query cache HIT → $videoId');
        }

        // Check if explicit video ID is invalid format (e.g. test stubs like remote_youtube_123)
        if (videoId.isNotEmpty && !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoId) && (queryStr == null || queryStr.isEmpty)) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }

        // Lazy Resolution: If no explicit video ID was provided, perform the search on the fly!
        if (videoId.isEmpty && queryStr != null && queryStr.isNotEmpty) {
          Log.d('YoutubeProxyServer: Lazily resolving query "$queryStr"...');
          
          if (!_isLocalRateLimited) {
            try {
              Log.d('YoutubeProxyServer: Trying direct YouTube search...');
              final searchList = await yt.search.search(queryStr).timeout(const Duration(seconds: 6));
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
            Log.d('YoutubeProxyServer: YouTube is rate-limited. Skipping direct search and trying Piped...');
            final fallbackId = await _searchPipedFallback(queryStr);
            if (fallbackId != null) {
              videoId = fallbackId;
            } else {
              throw Exception('YouTube rate-limited and Piped search fallback failed for query: $queryStr');
            }
          }

          Log.d('⏱ [TIMING] YouTube search for "$queryStr" finished after ${requestStopwatch.elapsedMilliseconds} ms');

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
            Log.d('YoutubeProxyServer: Cache HIT for Piped fallback stream → ${cached.url}');
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
            Log.d('YoutubeProxyServer: Trying direct YouTube stream extraction...');
            info = await _getStreamInfo(videoId, yt);
          } catch (streamError) {
            Log.w('YoutubeProxyServer: Direct YouTube stream extraction failed: $streamError. Evicting cache...');
            _evictVideoFromCaches(videoId);
            if (streamError is ArgumentError) {
              request.response.statusCode = HttpStatus.badRequest;
              await request.response.close();
              return;
            }
            if (_shouldTripRateLimit(streamError, videoId)) {
              _reportRateLimit(streamError);
            }
            resolvedFallbackUrl = await _resolvePipedFallbackUrl(videoId);
            if (resolvedFallbackUrl == null) {
              rethrow;
            }
          }
        } else {
          Log.d('YoutubeProxyServer: YouTube is rate-limited. Skipping direct stream extraction and trying Piped...');
          resolvedFallbackUrl = await _resolvePipedFallbackUrl(videoId);
          if (resolvedFallbackUrl == null) {
            throw Exception('YouTube rate-limited and Piped stream fallback failed for videoId: $videoId');
          }
        }

        if (resolvedFallbackUrl != null) {
          Log.d('YoutubeProxyServer: Redirecting audio player to Piped stream: $resolvedFallbackUrl');
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
        final isPartialRequest = rangeHeader != null;

        /// Byte range [start, end, total] for ONE particular stream. It must be computed per stream:
        /// a fallback stream (muxed instead of audio-only) has a different total size.
        List<int> rangeFor(StreamInfo s) {
          final total = s.size.totalBytes > 0 ? s.size.totalBytes : 1;
          var rangeStart = 0;
          var rangeEnd = total - 1;

          if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
            final parts = rangeHeader.substring(6).split('-');
            if (parts[0].isNotEmpty) {
              rangeStart = int.tryParse(parts[0]) ?? 0;
            }
            if (parts.length > 1 && parts[1].isNotEmpty) {
              rangeEnd = int.tryParse(parts[1]) ?? (total - 1);
            }

            if (rangeStart < 0) rangeStart = 0;
            if (rangeEnd >= total) rangeEnd = total - 1;
            if (rangeEnd < rangeStart) {
              rangeEnd = total - 1;
            }
          }
          return [rangeStart, rangeEnd, total];
        }

        // User-Agent selection logic
        String userAgentForStreamUrl(Uri url) {
          final clientParam = url.queryParameters['c']?.toUpperCase() ?? '';
          if (clientParam.contains('IOS')) {
            return AetherColors.iosUserAgent;
          }
          return AetherColors.androidUserAgent;
        }

        Future<void> pipeFromUpstream(StreamInfo upstreamInfo, {bool isHeadRequest = false}) async {
          final range = rangeFor(upstreamInfo);
          final start = range[0];
          final end = range[1];
          final totalBytes = range[2];

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

          headersSent = true;
          _onStreamSuccess(videoId, upstreamInfo);
          Log.d('⏱ [TIMING] first byte for $videoId after ${requestStopwatch.elapsedMilliseconds} ms (${_describe(upstreamInfo)})');

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
            Log.d('YoutubeProxyServer: Detected recoverable error - trying the next stream option...');

            var failedInfo = streamInfo;
            for (int attempt = 1; attempt <= 3; attempt++) {
              try {
                if (headersSent) break;

                Log.d('YoutubeProxyServer: Retry attempt $attempt for videoId=$videoId...');

                final retryInfo = await _nextStreamAfterFailure(videoId, yt, failedInfo);
                failedInfo = retryInfo;
                await pipeFromUpstream(retryInfo, isHeadRequest: request.method == 'HEAD');
                Log.d('YoutubeProxyServer: Retry $attempt succeeded');
                break;
              } catch (retryError) {
                Log.d('YoutubeProxyServer: Retry $attempt failed: $retryError');
                if (attempt == 3) {
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
    _candidateCache.clear();
    _resolvedUrlCache.clear();
    _ProxyHttpClientPool.close();
    Log.d('YoutubeProxyServer: All caches cleared');
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
        final response = await request.close().timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final bodyJson = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 4));
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
              Log.d('YoutubeProxyServer: Resolved Piped stream URL from $instance');
              _lastSuccessfulInstance = instance; // Cache successful instance
              _pipedUrlCache[videoId] = _CachedPipedUrl(streamUrl, DateTime.now());
              return streamUrl;
            }
          }
        }
      } catch (e) {
        Log.d('YoutubeProxyServer: Piped fallback failed for instance $instance: $e');
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
        final response = await request.close().timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final bodyJson = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 4));
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
                  Log.d('YoutubeProxyServer: Resolved Piped query "$queryStr" → $videoId via $instance');
                  _lastSuccessfulInstance = instance; // Cache successful instance
                  return videoId;
                }
              }
            }
          }
        }
      } catch (e) {
        Log.d('YoutubeProxyServer: Piped search fallback failed for instance $instance: $e');
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
    Log.d('YoutubeProxyServer: Server stopped');
  }
}
