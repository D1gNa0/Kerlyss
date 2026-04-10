import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest('dQw4w9WgXcQ');
    final highest = manifest.audioOnly.withHighestBitrate();
    print('Highest: \${highest.codec.mimeType} | \${highest.container.name} | \${highest.bitrate}');
    print('URL: \${highest.url.toString().substring(0, 50)}...');

    final mp4 = manifest.audioOnly.where((s) => s.container.name == 'mp4').lastOrNull;
    if (mp4 != null) {
      print('MP4: \${mp4.codec.mimeType} | \${mp4.container.name} | \${mp4.bitrate}');
    }
  } finally {
    yt.close();
  }
}
