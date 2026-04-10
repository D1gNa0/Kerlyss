import 'dart:io';

class DownloadedSong {
  final String path;
  final String title;
  final int sizeBytes;
  final DateTime modifiedAt;

  const DownloadedSong({
    required this.path,
    required this.title,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  static Future<DownloadedSong> fromFile(File file) async {
    final stat = await file.stat();
    return DownloadedSong(
      path: file.path,
      title: _displayNameForPath(file.path),
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
    );
  }

  static String _displayNameForPath(String path) {
    final separator = Platform.pathSeparator;
    final fileName = path.split(separator).last;
    final lastDot = fileName.lastIndexOf('.');

    if (lastDot <= 0) {
      return fileName;
    }

    return fileName.substring(0, lastDot);
  }
}