import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A custom just_audio AudioSource that uses youtube_explode_dart's
/// own authenticated HTTP client to stream audio.
///
/// Key difference from raw setUrl(): youtube_explode_dart sends the correct
/// YouTube authentication headers (Origin, Referer, User-Agent) that
/// Windows Media Foundation does NOT send natively. Without these,
/// YouTube CDN rejects every request with an HTTP error ("Media error").
///
/// Streams progressively — does NOT buffer the full file before playing.
class YoutubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode _yt = YoutubeExplode();

  YoutubeAudioSource({required this.videoId}) : super(tag: videoId);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // 1. Fetch stream manifest via youtube_explode's authenticated client.
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final info = manifest.audioOnly.withHighestBitrate();

    final totalBytes = info.size.totalBytes;

    // 2. Get the authenticated progressive stream.
    //    youtube_explode's streamsClient handles all YouTube headers internally.
    //    We stream from byte 0; seeking is handled by just_audio re-calling request()
    //    with a start offset. For range: if start > 0, skip bytes.
    final fullStream = _yt.videos.streamsClient.get(info);

    Stream<List<int>> responseStream;
    int responseStart = start ?? 0;
    int responseLength = (end ?? totalBytes - 1) - responseStart + 1;

    if (responseStart == 0) {
      // Most common case: play from the beginning
      responseStream = fullStream.map((chunk) => List<int>.from(chunk));
    } else {
      // Seek: skip bytes up to the start offset
      int skipped = 0;
      responseStream = fullStream
          .expand((chunk) => chunk)
          .skipWhile((_) {
            if (skipped < responseStart) { skipped++; return true; }
            return false;
          })
          .take(responseLength)
          .map((b) => [b]);
    }

    return StreamAudioResponse(
      sourceLength: totalBytes,
      contentLength: responseLength,
      offset: responseStart,
      stream: responseStream,
      contentType: info.codec.mimeType,
    );
  }
}
