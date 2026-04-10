import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/local_download_library.dart';
import '../../domain/entities/downloaded_song.dart';

final localDownloadLibraryProvider = Provider<LocalDownloadLibrary>((ref) {
  return LocalDownloadLibrary();
});

final downloadedSongsProvider = FutureProvider<List<DownloadedSong>>((ref) async {
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  return localDownloadLibrary.listDownloadedSongs();
});

final downloadedSongsPathProvider = FutureProvider<String>((ref) async {
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  return localDownloadLibrary.downloadsPath;
});