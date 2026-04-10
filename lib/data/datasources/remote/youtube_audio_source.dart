import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:typed_data';

/// A custom just_audio AudioSource that uses youtube_explode_dart's
/// own authenticated HTTP client to fetch the stream.
/// This bypasses just_audio's raw URL fetch, which fails on Windows
/// because YouTube CDN requires specific headers (Origin, Referer, User-Agent).
class YoutubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode _yt = YoutubeExplode();

  YoutubeAudioSource({required this.videoId}) : super(tag: videoId);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final info = manifest.audioOnly.withHighestBitrate();
    final stream = _yt.videos.streamsClient.get(info);

    // Collect full bytes for StreamAudioResponse
    final List<int> bytes = [];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    final data = Uint8List.fromList(bytes);

    final rangeStart = start ?? 0;
    final rangeEnd = end ?? data.length;

    return StreamAudioResponse(
      sourceLength: data.length,
      contentLength: rangeEnd - rangeStart,
      offset: rangeStart,
      stream: Stream.value(data.sublist(rangeStart, rangeEnd)),
      contentType: info.codec.mimeType,
    );
  }
}
