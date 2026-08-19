import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';

class DownloadState {
  final Set<String> downloadingTrackIds;
  final Map<String, double> downloadProgress;
  final Set<String> alreadyDownloadedIds;
  final Map<String, SongEntity> activeDownloadSongs;
  final List<String> downloadQueueOrder;
  final int bulkTotal;
  final int bulkCompleted;

  DownloadState({
    this.downloadingTrackIds = const {},
    this.downloadProgress = const {},
    this.alreadyDownloadedIds = const {},
    this.activeDownloadSongs = const {},
    this.downloadQueueOrder = const [],
    this.bulkTotal = 0,
    this.bulkCompleted = 0,
  });

  bool get isBulkActive => bulkTotal > 0;
  bool get isAnyDownloadActive => downloadingTrackIds.isNotEmpty || isBulkActive;

  SongEntity? get activeSong {
    for (final id in downloadQueueOrder) {
      if (downloadingTrackIds.contains(id) && activeDownloadSongs.containsKey(id)) {
        return activeDownloadSongs[id];
      }
    }
    if (activeDownloadSongs.isNotEmpty) {
      return activeDownloadSongs.values.first;
    }
    return null;
  }

  double get activeSongProgress {
    final song = activeSong;
    if (song == null) return 0.0;
    return downloadProgress[song.id] ?? 0.0;
  }

  DownloadState copyWith({
    Set<String>? downloadingTrackIds,
    Map<String, double>? downloadProgress,
    Set<String>? alreadyDownloadedIds,
    Map<String, SongEntity>? activeDownloadSongs,
    List<String>? downloadQueueOrder,
    int? bulkTotal,
    int? bulkCompleted,
  }) {
    return DownloadState(
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      alreadyDownloadedIds: alreadyDownloadedIds ?? this.alreadyDownloadedIds,
      activeDownloadSongs: activeDownloadSongs ?? this.activeDownloadSongs,
      downloadQueueOrder: downloadQueueOrder ?? this.downloadQueueOrder,
      bulkTotal: bulkTotal ?? this.bulkTotal,
      bulkCompleted: bulkCompleted ?? this.bulkCompleted,
    );
  }
}

class DownloadStateNotifier extends StateNotifier<DownloadState> {
  DownloadStateNotifier() : super(DownloadState());

  final Map<String, double> _pendingProgress = {};
  Timer? _progressFlushTimer;

  void setDownloading(String id) {
    state = state.copyWith(
      downloadingTrackIds: {...state.downloadingTrackIds, id},
      downloadProgress: {...state.downloadProgress, id: 0.0},
    );
  }

  void setDownloadingSong(SongEntity song) {
    final updatedActive = {...state.activeDownloadSongs, song.id: song};
    final updatedQueue = List<String>.from(state.downloadQueueOrder);
    if (!updatedQueue.contains(song.id)) {
      updatedQueue.add(song.id);
    }
    state = state.copyWith(
      downloadingTrackIds: {...state.downloadingTrackIds, song.id},
      downloadProgress: {...state.downloadProgress, song.id: 0.0},
      activeDownloadSongs: updatedActive,
      downloadQueueOrder: updatedQueue,
    );
  }

  void updateProgress(String id, double progress) {
    _pendingProgress[id] = progress;

    _progressFlushTimer ??= Timer(const Duration(milliseconds: 75), _flushProgress);
  }

  void _flushProgress() {
    if (_pendingProgress.isEmpty) {
      _progressFlushTimer = null;
      return;
    }

    final updatedProgress = {...state.downloadProgress, ..._pendingProgress};
    _pendingProgress.clear();
    _progressFlushTimer = null;

    state = state.copyWith(downloadProgress: updatedProgress);
  }

  void completeDownload(String id) {
    final newDownloading = {...state.downloadingTrackIds}..remove(id);
    final newProgress = {...state.downloadProgress}..remove(id);
    final newActiveSongs = {...state.activeDownloadSongs}..remove(id);
    final newQueueOrder = List<String>.from(state.downloadQueueOrder)..remove(id);

    state = state.copyWith(
      downloadingTrackIds: newDownloading,
      downloadProgress: newProgress,
      activeDownloadSongs: newActiveSongs,
      downloadQueueOrder: newQueueOrder,
      alreadyDownloadedIds: {...state.alreadyDownloadedIds, id},
    );
  }

  void clearDownloadAttempt(String id) {
    final newDownloading = {...state.downloadingTrackIds}..remove(id);
    final newProgress = {...state.downloadProgress}..remove(id);
    final newActiveSongs = {...state.activeDownloadSongs}..remove(id);
    final newQueueOrder = List<String>.from(state.downloadQueueOrder)..remove(id);

    state = state.copyWith(
      downloadingTrackIds: newDownloading,
      downloadProgress: newProgress,
      activeDownloadSongs: newActiveSongs,
      downloadQueueOrder: newQueueOrder,
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

  @override
  void dispose() {
    _progressFlushTimer?.cancel();
    super.dispose();
  }
}

final downloadStateProvider = StateNotifierProvider<DownloadStateNotifier, DownloadState>((ref) {
  return DownloadStateNotifier();
});
