import '../../domain/repositories/audio_service_interface.dart';
import '../../data/datasources/local/just_audio_service.dart';
import '../../data/datasources/local/isar_database_service.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import '../../main.dart';
import 'package:path/path.dart' as p;


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show AudioSource;
// Using custom AudioServiceInterface

import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/core/services/playback_session_store.dart';
import 'package:kerlyss/data/datasources/local/local_download_library.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';
import 'package:kerlyss/data/repositories/repository_providers.dart';
import 'package:kerlyss/presentation/state/downloaded_songs_provider.dart';
import '../../domain/entities/downloaded_song.dart';

import 'audio_state.dart';

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  final audioService = JustAudioService();
  final youtubeService = ref.watch(youtubeServiceProvider);
  final isarService = ref.read(isarDatabaseServiceProvider);
  return AudioNotifier(localDownloadLibrary, youtubeService, audioService, isarService);
});


/// Audio engine backed by just_audio.
/// YouTube playback goes through a local proxy so the player only sees a plain
/// HTTP audio stream.
class AudioNotifier extends StateNotifier<AudioState> {
  final AudioServiceInterface _audioService;
  final LocalDownloadLibrary _localDownloadLibrary;
  final YoutubeService _youtubeService;
  final IsarDatabaseService _isarService;
  final PlaybackSessionStore _sessionStore = PlaybackSessionStore();

  final _frequencyController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyController.stream;
  Timer? _visualizerTimer;
  Timer? _sessionPersistDebounce;
  int _playRequestId = 0;
  bool _isRestoringSession = false;
  bool _isNavigatingQueue = false;
  int _lastPersistedSecondMark = -1;
  DateTime? _forcePlayingUntil;

  final List<StreamSubscription<dynamic>> _subs = [];

  AudioNotifier(this._localDownloadLibrary, this._youtubeService, this._audioService, this._isarService)

      : super(
          AudioState(

            currentSong: SongMetadata.empty(),
            status: PlaybackStatus.idle,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
          ),
        ) {
    _init();
    _startVibrancyLoop();
      unawaited(_restorePlaybackSession());
  }

  void _init() {
        _subs.add(_audioService.playbackStatusStream.listen((status) {
      if (!mounted) return;

      // Ignore idle/buffering status if we are in a loading state to prevent flickering
      // This ensures the spinner stays until the engine is truly Ready or Playing.
      if (state.status == PlaybackStatus.loading && 
              (status == PlaybackStatus.idle || status == PlaybackStatus.buffering || status == PlaybackStatus.completed)) {
        return;
      }

          // During an explicit play intent, transient paused events from just_audio_windows
          // can appear before the stream settles. Ignore this short-lived oscillation.
          final now = DateTime.now();
          if (status == PlaybackStatus.paused &&
              _forcePlayingUntil != null &&
              now.isBefore(_forcePlayingUntil!)) {
            return;
          }

          if (status == state.status) {
            return;
          }

          Log.i('Audio status changed: $status (Current state: ${state.status})');

      state = state.copyWith(status: status);

          if (status == PlaybackStatus.playing) {
            _forcePlayingUntil = null;
          }

      if (status == PlaybackStatus.paused || status == PlaybackStatus.playing || status == PlaybackStatus.completed) {
        _schedulePersistSession();
      }
    }));

    _subs.add(_audioService.currentIndexStream.listen((index) {
      if (!mounted || index == null) return;
      if (index != state.currentIndex && index >= 0 && index < state.playlist.length) {
        Log.i('AudioNotifier: Gapless transition to index $index');
        final nextSong = state.playlist[index];
        state = state.copyWith(
          currentIndex: index,
          currentSong: nextSong,
        );
        globalAudioHandler.setMediaFromSong(nextSong);
        _schedulePersistSession();
      }
    }));


    _subs.add(_audioService.positionStream.listen((position) {
      if (!mounted) return;
      state = state.copyWith(position: position);

      // Persist at coarse position intervals to support resume without heavy disk churn.
      final second = position.inSeconds;
      if (_audioService.playing && second % 5 == 0 && second != _lastPersistedSecondMark) {
        _lastPersistedSecondMark = second;
        _schedulePersistSession();
      }
    }));

    _subs.add(_audioService.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      if (state.currentSong.duration != duration) {
        state = state.copyWith(
          currentSong: SongMetadata(
            id: state.currentSong.id,
            title: state.currentSong.title,
            artist: state.currentSong.artist,
            album: state.currentSong.album,
            artworkUrl: state.currentSong.artworkUrl,
            duration: duration,
            source: state.currentSong.source,
          ),
        );
      }
    }));

    _subs.add(_audioService.bufferedPositionStream.listen((bufferedPosition) {
      if (!mounted) return;
      state = state.copyWith(bufferedPosition: bufferedPosition);
    }));

    _audioService.setVolume(1.0);
  }

  Future<void> _restorePlaybackSession() async {
    try {
      _isRestoringSession = true;
      final requestId = ++_playRequestId;

      final snapshot = await _sessionStore.load();
      if (!mounted || requestId != _playRequestId) {
        _isRestoringSession = false;
        return;
      }

      if (snapshot == null || snapshot.playlist.isEmpty) {
        _isRestoringSession = false;
        return;
      }

      final clampedIndex = min(max(snapshot.currentIndex, 0), snapshot.playlist.length - 1);
      final restoredSong = snapshot.playlist[clampedIndex];

      state = state.copyWith(status: PlaybackStatus.loading);

      _audioService.setVolume(snapshot.volume);

      final sources = await Future.wait(
        snapshot.playlist.map((song) => _buildAudioSource(song)),
      );

      if (!mounted || requestId != _playRequestId) {
        _isRestoringSession = false;
        return;
      }

      await _audioService.setAudioQueue(sources, initialIndex: clampedIndex, play: false);

      if (!mounted || requestId != _playRequestId) {
        _isRestoringSession = false;
        return;
      }

      await _audioService.seek(snapshot.position, index: clampedIndex);

      if (!mounted || requestId != _playRequestId) {
        _isRestoringSession = false;
        return;
      }

      state = state.copyWith(
        playlist: snapshot.playlist,
        currentIndex: clampedIndex,
        currentSong: restoredSong,
        position: snapshot.position,
        bufferedPosition: Duration.zero,
        volume: snapshot.volume,
        isShuffleEnabled: snapshot.isShuffleEnabled,
        isRepeatEnabled: snapshot.isRepeatEnabled,
      );

      globalAudioHandler.setMediaFromSong(restoredSong);

      if (snapshot.wasPlaying) {
        await _ensurePlaybackStarted();
      } else {
        await _audioService.pause();
        if (mounted) {
          state = state.copyWith(status: PlaybackStatus.paused);
        }
      }

      _isRestoringSession = false;
      _schedulePersistSession();
    } catch (e) {
      _isRestoringSession = false;
      if (mounted) {
        state = state.copyWith(status: PlaybackStatus.idle);
      }
      Log.e('AudioNotifier: Failed to restore playback session: $e');
    }
  }

  void _schedulePersistSession() {
    _sessionPersistDebounce?.cancel();
    _sessionPersistDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_persistPlaybackSession());
    });
  }

  Future<void> _persistPlaybackSession() async {
    if (!mounted || state.playlist.isEmpty || state.currentIndex < 0 || state.currentIndex >= state.playlist.length) {
      return;
    }

    final snapshot = PlaybackSessionSnapshot(
      playlist: List<SongMetadata>.from(state.playlist),
      currentIndex: state.currentIndex,
      position: state.position,
      wasPlaying: _audioService.playing,
      volume: state.volume,
      isShuffleEnabled: state.isShuffleEnabled,
      isRepeatEnabled: state.isRepeatEnabled,
    );

    await _sessionStore.save(snapshot);
  }

  void _setPlaybackError(String context, Object error) {
    Log.e('AudioNotifier: $context failed: $error');
    if (!mounted) return;
    state = state.copyWith(status: PlaybackStatus.error);
  }

  void _syncStatusFromEngine() {
    if (!mounted) return;
    final resolved = _audioService.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
    if (state.status != resolved) {
      state = state.copyWith(status: resolved);
    }
  }

  void _startVibrancyLoop() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (state.status == PlaybackStatus.playing) {
        final bands = List.generate(16, (i) {
          final base = (1.0 - (i / 16.0)) * 0.4;
          return (base + (DateTime.now().millisecond % 1000) / 1000.0 * 0.6)
              .clamp(0.1, 1.0);
        });
        _frequencyController.add(bands);
      } else {
        _frequencyController.add(List.generate(16, (_) => 0.0));
      }
    });
  }

  /// Plays a playlist starting at [index].
  /// Reorders queue so clicked song is at position 0 — bypasses broken
  /// initialIndex on just_audio_windows which always plays index 0.
  Future<void> playPlaylist(List<SongMetadata> playlist, int index) async {
    try {
      if (index < 0 || index >= playlist.length) return;
      final requestId = ++_playRequestId;
      _isRestoringSession = false;
      final clickedSong = playlist[index];

      final canReuseCurrentQueue = !_isRestoringSession &&
          state.playlist.length == playlist.length &&
          state.playlist.isNotEmpty &&
          state.playlist.every((song) => playlist.any((candidate) => candidate.id == song.id)) &&
          playlist.every((song) => state.playlist.any((candidate) => candidate.id == song.id));

      if (canReuseCurrentQueue) {
        final existingIndex = state.playlist.indexWhere((song) => song.id == clickedSong.id);
        if (existingIndex >= 0) {
          state = state.copyWith(
            status: PlaybackStatus.loading,
          );

          final currentIdx = (state.currentIndex >= 0)
              ? state.currentIndex
              : (_audioService.currentIndex ?? 0);

          int targetIndex = existingIndex;
          final currentValid = currentIdx >= 0 && currentIdx < state.playlist.length;

          // If clicked song is already in queue, place it right after current song
          // to preserve queue flow and still play the clicked song immediately.
          if (currentValid && existingIndex != currentIdx) {
            int insertionIndex = currentIdx + 1;
            if (insertionIndex > state.playlist.length) {
              insertionIndex = state.playlist.length;
            }

            final reordered = List<SongMetadata>.from(state.playlist);
            final movedSong = reordered.removeAt(existingIndex);
            if (existingIndex < insertionIndex) {
              insertionIndex -= 1;
            }
            reordered.insert(insertionIndex, movedSong);

            targetIndex = insertionIndex;

            state = state.copyWith(playlist: reordered);
            await _audioService.moveInQueue(existingIndex, insertionIndex);
            if (!mounted || requestId != _playRequestId) return;
          }

          await _audioService.seek(Duration.zero, index: targetIndex);
          if (!mounted || requestId != _playRequestId) return;
          await _ensurePlaybackStarted();
          if (!mounted || requestId != _playRequestId) return;
          final resolvedIndex = _audioService.currentIndex ?? targetIndex;
          if (resolvedIndex < 0 || resolvedIndex >= state.playlist.length) return;
          final resolvedSong = state.playlist[resolvedIndex];
          state = state.copyWith(
            currentIndex: resolvedIndex,
            currentSong: resolvedSong,
          );
          globalAudioHandler.setMediaFromSong(resolvedSong);
          _syncStatusFromEngine();
          _schedulePersistSession();
          return;
        }
      }

      // Reorder: [clicked, ...after clicked, ...before clicked]
      final reordered = [
        ...playlist.sublist(index),
        ...playlist.sublist(0, index),
      ];

      state = state.copyWith(
        playlist: reordered,
        status: PlaybackStatus.loading,
      );

      final sources = await Future.wait(
        reordered.map((song) => _buildAudioSource(song)),
      );
      if (!mounted || requestId != _playRequestId) return;

      await _audioService.setAudioQueue(sources, initialIndex: 0, play: false);
      if (!mounted || requestId != _playRequestId) return;
      await _ensurePlaybackStarted();
      if (!mounted || requestId != _playRequestId) return;
      final resolvedIndex = _audioService.currentIndex ?? 0;
      if (resolvedIndex < 0 || resolvedIndex >= reordered.length) return;
      final resolvedSong = reordered[resolvedIndex];
      state = state.copyWith(
        currentIndex: resolvedIndex,
        currentSong: resolvedSong,
      );
      globalAudioHandler.setMediaFromSong(resolvedSong);
      _syncStatusFromEngine();
      _schedulePersistSession();
    } catch (e) {
      _setPlaybackError('playPlaylist', e);
    }
  }

  Future<void> _ensurePlaybackStarted() async {
    try {
      _forcePlayingUntil = DateTime.now().add(const Duration(milliseconds: 1200));
      await _audioService.play();

      // just_audio_windows occasionally drops the first play intent right after load.
      // Retry once to ensure user-initiated taps actually start playback.
      if (!_audioService.playing) {
        await Future.delayed(const Duration(milliseconds: 120));
        _forcePlayingUntil = DateTime.now().add(const Duration(milliseconds: 1200));
        await _audioService.play();
      }

      _syncStatusFromEngine();
    } catch (e) {
      _forcePlayingUntil = null;
      _setPlaybackError('ensurePlaybackStarted', e);
      rethrow;
    }
  }








  Future<void> addNext(SongMetadata song) async {
    if (state.playlist.isEmpty) {
      await playPlaylist([song], 0);
      return;
    }
    final newPlaylist = List<SongMetadata>.from(state.playlist);
    newPlaylist.insert(state.currentIndex + 1, song);
    state = state.copyWith(playlist: newPlaylist);

    final source = await _buildAudioSource(song);
    await _audioService.insertIntoQueue(state.currentIndex + 1, source);
    _schedulePersistSession();
  }

  Future<void> addLast(SongMetadata song) async {
    if (state.playlist.isEmpty) {
      await playPlaylist([song], 0);
      return;
    }
    final newPlaylist = List<SongMetadata>.from(state.playlist);
    newPlaylist.add(song);
    state = state.copyWith(playlist: newPlaylist);

    final source = await _buildAudioSource(song);
    await _audioService.insertIntoQueue(newPlaylist.length - 1, source);
    _schedulePersistSession();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.playlist.length) return;
    if (newIndex < 0 || newIndex > state.playlist.length) return;
    
    if (oldIndex < newIndex) newIndex -= 1;

    final newPlaylist = List<SongMetadata>.from(state.playlist);
    final item = newPlaylist.removeAt(oldIndex);
    newPlaylist.insert(newIndex, item);

    int newCurrentIndex = state.currentIndex;
    if (state.currentIndex == oldIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex && newIndex >= state.currentIndex) {
      newCurrentIndex--;
    } else if (oldIndex > state.currentIndex && newIndex <= state.currentIndex) {
      newCurrentIndex++;
    }

    state = state.copyWith(playlist: newPlaylist, currentIndex: newCurrentIndex);
    await _audioService.moveInQueue(oldIndex, newIndex);
    _schedulePersistSession();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.playlist.length) return;
    final newPlaylist = List<SongMetadata>.from(state.playlist);
    newPlaylist.removeAt(index);
    
    int newCurrentIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newCurrentIndex--;
    } else if (index == state.currentIndex) {
      if (newPlaylist.isEmpty) {
        _audioService.pause();
        newCurrentIndex = -1;
      }
    }
    
    state = state.copyWith(playlist: newPlaylist, currentIndex: newCurrentIndex);
    await _audioService.removeFromQueue(index);
    _schedulePersistSession();
  }

  Future<void> next() async {
    try {
      if (_isNavigatingQueue) return;
      if (state.playlist.isEmpty) return;
      _isNavigatingQueue = true;
      final nextIndex = (state.currentIndex + 1) % state.playlist.length;
      Log.i('Audio: Seeking next track at index $nextIndex');
      await _audioService.seek(Duration.zero, index: nextIndex);
      await _ensurePlaybackStarted();
    } catch (e) {
      _setPlaybackError('next', e);
    } finally {
      _isNavigatingQueue = false;
    }
  }

  Future<void> previous() async {
    try {
      if (_isNavigatingQueue) return;
      if (state.playlist.isEmpty) return;
      _isNavigatingQueue = true;
      if (_audioService.position > const Duration(seconds: 4)) {
        await _audioService.seek(Duration.zero);
        await _ensurePlaybackStarted();
        return;
      }
      var prevIndex = state.currentIndex - 1;
      if (prevIndex < 0) prevIndex = state.playlist.length - 1;
      await _audioService.seek(Duration.zero, index: prevIndex);
      await _ensurePlaybackStarted();
    } catch (e) {
      _setPlaybackError('previous', e);
    } finally {
      _isNavigatingQueue = false;
    }
  }

  Future<AudioSource> _buildAudioSource(SongMetadata song) async {
    // 1. Check Isar Database for local path
    String? localPath;
    try {
      final dbSong = await _isarService.getSongById(song.id);
      if (dbSong != null && dbSong.localPath != null) {
        localPath = dbSong.localPath;
      }
    } catch (_) {}

    // Fallback: Check local downloads library directly
    if (localPath == null) {
      String lookupId = song.id.startsWith('jamendo_') 
          ? song.id.replaceFirst('jamendo_', '') 
          : song.id;

      DownloadedSong? localSong;
      if (!lookupId.startsWith('file://') && !lookupId.contains(Platform.pathSeparator) && !lookupId.contains('/')) {
        localSong = await _localDownloadLibrary.findDownloadedSongById(lookupId);
        if (localSong != null) localPath = localSong.path;
      }
    }
    
    if (localPath != null) {
      final normalizedPath = _normalizePath(localPath);
      return AudioSource.uri(Uri.file(normalizedPath), tag: song);
    }

    final sourceUrl = song.id;

    // 2. If it is already a direct file path (fallback)
    if (sourceUrl.startsWith('file://') || (sourceUrl.length > 3 && !sourceUrl.startsWith('http') && File(sourceUrl).existsSync())) {
      final finalPath = _normalizePath(sourceUrl.replaceFirst('file://', ''));
      return AudioSource.uri(Uri.file(finalPath), tag: song);
    }

    // 3. Streaming (Remote Source)
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    // Priority: check if the provided sourceUrl is a direct stream URL (not youtube)
    if (sourceUrl.startsWith('http') && !sourceUrl.contains('youtube.com') && !sourceUrl.contains('youtu.be')) {
      return AudioSource.uri(Uri.parse(sourceUrl), headers: headers, tag: song);
    }

    // Resolve YouTube if needed
    final uri = Uri.tryParse(sourceUrl);
    String? videoId;
    if (uri != null && (uri.host.contains('youtube') || uri.host.contains('youtu.be'))) {
      videoId = uri.queryParameters['v'] ?? (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
    } else if (!sourceUrl.startsWith('http')) {
      videoId = sourceUrl;
    }

    if (videoId != null && videoId.isNotEmpty) {
      final port = await YoutubeProxyServer.start(_youtubeService.client);
      final proxyUrl = 'http://127.0.0.1:$port/?id=$videoId';
      return AudioSource.uri(Uri.parse(proxyUrl), headers: headers, tag: song);
    } else {
      return AudioSource.uri(Uri.parse(sourceUrl), headers: headers, tag: song);
    }
  }

  void togglePlay() {
    if (_audioService.playing) {
      _audioService.pause();
    } else {
      _audioService.play();
    }
    _schedulePersistSession();
  }

  void seek(Duration position) {
    _audioService.seek(position);
    _schedulePersistSession();
  }

  void setVolume(double volume) {
    _audioService.setVolume(volume);
    state = state.copyWith(volume: volume);
    _schedulePersistSession();
  }

  void seekRelative(int seconds) {
    final currentPosition = _audioService.position;
    final duration = _audioService.duration ?? Duration.zero;
    final nextPosition = currentPosition + Duration(seconds: seconds);
    
    // Clamp to [0, duration]
    if (nextPosition < Duration.zero) {
      _audioService.seek(Duration.zero);
    } else if (nextPosition > duration) {
      _audioService.seek(duration);
    } else {
      _audioService.seek(nextPosition);
    }
    _schedulePersistSession();
  }

  /// Normalizes file path separators for Windows.
  /// just_audio_windows passes paths directly to WMF which requires backslashes.
  String _normalizePath(String path) {
    if (Platform.isWindows) {
      return p.normalize(path).replaceAll('/', '\\');
    }
    return p.normalize(path);
  }

  @override
  void dispose() {
    _sessionPersistDebounce?.cancel();
    unawaited(_persistPlaybackSession());

    for (final sub in _subs) {
      sub.cancel();
    }
    _visualizerTimer?.cancel();
    _frequencyController.close();
    _audioService.dispose();
    super.dispose();
  }
}
