import 'youtube_service.dart';

class YoutubeAudioEngine {
  final YoutubeService _youtubeService;
  
  // Tiered Cache: Stream Headers (Memory)
  final Map<String, _CachedStream> _memoryCache = {};
  
  // Concurrency Lock: Prevent multiple simultaneous resolutions for the same ID
  final Map<String, Future<String>> _activeResolutions = {};

  YoutubeAudioEngine(this._youtubeService);

  Future<String> getStreamUri(String videoId) async {
    // 1. Check Memory Cache
    if (_memoryCache.containsKey(videoId)) {
      final cached = _memoryCache[videoId]!;
      if (!cached.isExpired) {
        return cached.uri;
      }
    }

    // 2. Check for Active Resolution (Lock)
    if (_activeResolutions.containsKey(videoId)) {
      return await _activeResolutions[videoId]!;
    }

    // 3. Resolve fresh URI and Cache it
    final resolution = _resolveAndCache(videoId);
    _activeResolutions[videoId] = resolution;
    
    try {
      return await resolution;
    } finally {
      _activeResolutions.remove(videoId);
    }
  }

  Future<String> _resolveAndCache(String videoId) async {
    final uri = await _youtubeService.getStreamUri(videoId);
    
    _memoryCache[videoId] = _CachedStream(
      uri: uri,
      timestamp: DateTime.now(),
    );

    return uri;
  }
}

class _CachedStream {
  final String uri;
  final DateTime timestamp;

  _CachedStream({required this.uri, required this.timestamp});

  // Conservatively set expiration to 5 hours (as URIs usually last 6)
  bool get isExpired => DateTime.now().difference(timestamp).inHours >= 5;
}
