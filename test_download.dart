import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'dQw4w9WgXcQ'; // Rickroll for testing
  
  try {
    print('Fetching manifest...');
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    final stream = yt.videos.streamsClient.get(audioStreamInfo);
    final totalSize = audioStreamInfo.size.totalBytes;
    
    print('Downloading $videoId (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB)...');
    
    final file = File('test_download.mp3');
    final sink = file.openWrite();
    int downloaded = 0;
    
    await for (final chunk in stream) {
      sink.add(chunk);
      downloaded += chunk.length;
      final progress = (downloaded / totalSize * 100).toStringAsFixed(1);
      stdout.write('\rProgress: $progress%');
    }
    
    await sink.flush();
    await sink.close();
    
    print('\nDownload completed: ${file.path}');
    print('File size on disk: ${await file.length()} bytes');
  } catch (e) {
    print('\nDownload failed: $e');
  } finally {
    yt.close();
    exit(0);
  }
}
