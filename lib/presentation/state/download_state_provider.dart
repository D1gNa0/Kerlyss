import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadState {
  final Set<String> downloadingTrackIds;
  final Map<String, double> downloadProgress;
  final Set<String> alreadyDownloadedIds;

  DownloadState({
    this.downloadingTrackIds = const {},
    this.downloadProgress = const {},
    this.alreadyDownloadedIds = const {},
  });

  DownloadState copyWith({
    Set<String>? downloadingTrackIds,
    Map<String, double>? downloadProgress,
    Set<String>? alreadyDownloadedIds,
  }) {
    return DownloadState(
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      alreadyDownloadedIds: alreadyDownloadedIds ?? this.alreadyDownloadedIds,
    );
  }
}

class DownloadStateNotifier extends StateNotifier<DownloadState> {
  DownloadStateNotifier() : super(DownloadState());

  void setDownloading(String id) {
    state = state.copyWith(
      downloadingTrackIds: {...state.downloadingTrackIds, id},
      downloadProgress: {...state.downloadProgress, id: 0.0},
    );
  }

  void updateProgress(String id, double progress) {
    state = state.copyWith(
      downloadProgress: {...state.downloadProgress, id: progress},
    );
  }

  void completeDownload(String id) {
    final newDownloading = {...state.downloadingTrackIds}..remove(id);
    final newProgress = {...state.downloadProgress}..remove(id);

    state = state.copyWith(
      downloadingTrackIds: newDownloading,
      downloadProgress: newProgress,
      alreadyDownloadedIds: {...state.alreadyDownloadedIds, id},
    );
  }

  void setAlreadyDownloaded(Set<String> ids) {
    state = state.copyWith(alreadyDownloadedIds: ids);
  }
}

final downloadStateProvider = StateNotifierProvider<DownloadStateNotifier, DownloadState>((ref) {
  return DownloadStateNotifier();
});
