import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadState {
  final Set<String> downloadingTrackIds;
  final Map<String, double> downloadProgress;
  final Set<String> alreadyDownloadedIds;
  final int bulkTotal;
  final int bulkCompleted;

  DownloadState({
    this.downloadingTrackIds = const {},
    this.downloadProgress = const {},
    this.alreadyDownloadedIds = const {},
    this.bulkTotal = 0,
    this.bulkCompleted = 0,
  });

  bool get isBulkActive => bulkTotal > 0;

  DownloadState copyWith({
    Set<String>? downloadingTrackIds,
    Map<String, double>? downloadProgress,
    Set<String>? alreadyDownloadedIds,
    int? bulkTotal,
    int? bulkCompleted,
  }) {
    return DownloadState(
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      alreadyDownloadedIds: alreadyDownloadedIds ?? this.alreadyDownloadedIds,
      bulkTotal: bulkTotal ?? this.bulkTotal,
      bulkCompleted: bulkCompleted ?? this.bulkCompleted,
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

  void startBulk(int total) {
    state = state.copyWith(bulkTotal: total, bulkCompleted: 0);
  }

  void incrementBulk() {
    final next = state.bulkCompleted + 1;
    if (next >= state.bulkTotal) {
      state = state.copyWith(bulkTotal: 0, bulkCompleted: 0);
    } else {
      state = state.copyWith(bulkCompleted: next);
    }
  }

  void clearBulk() {
    state = state.copyWith(bulkTotal: 0, bulkCompleted: 0);
  }

  void setAlreadyDownloaded(Set<String> ids) {
    state = state.copyWith(alreadyDownloadedIds: ids);
  }
}

final downloadStateProvider = StateNotifierProvider<DownloadStateNotifier, DownloadState>((ref) {
  return DownloadStateNotifier();
});
