import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'mGr_5vbL80Y';
  final manifest = await yt.videos.streamsClient.getManifest(videoId);
  
  print('--- All Audio-Only Streams ---');
  for (final s in manifest.audioOnly) {
    print('Codec: ${s.codec.mimeType}, Container: ${s.container.name}, Bitrate: ${s.bitrate}, Size: ${s.size}');
  }

  print('\n--- All Muxed (Video+Audio) Streams ---');
  for (final s in manifest.muxed) {
    print('Codec: ${s.codec.mimeType}, Container: ${s.container.name}, Bitrate: ${s.bitrate}, Quality: ${s.videoQuality}, Size: ${s.size}');
  }
  
  yt.close();
}
