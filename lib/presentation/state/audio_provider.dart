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

import 'package:kerlyss/core/services/app_storage_paths.dart';
import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/core/services/playback_session_store.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';
import 'package:kerlyss/data/datasources/local/local_download_library.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';
import 'package:kerlyss/data/repositories/repository_providers.dart';
import 'package:kerlyss/domain/repositories/song_repository.dart';
import 'package:kerlyss/domain/entities/audio_source_type.dart';
import 'package:kerlyss/presentation/state/downloaded_songs_provider.dart';
import '../../domain/entities/downloaded_song.dart';

import 'audio_state.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';

final playbackErrorProvider = StateProvider<String?>((ref) => null);

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  final audioService = JustAudioService();
  final youtubeService = ref.watch(youtubeServiceProvider);
  final isarService = ref.read(isarDatabaseServiceProvider);
  final songRepo = ref.read(songRepositoryProvider);

  ref.onDispose(YoutubeProxyServer.stop);

  return AudioNotifier(localDownloadLibrary, youtubeService, audioService, isarService, songRepo);
});


/// Audio engine backed by just_audio.
/// YouTube playback goes through a local proxy so the player only sees a plain
/// HTTP audio stream.
class AudioNotifier extends StateNotifier<AudioState> {
  final AudioServiceInterface _audioService;
  final LocalDownloadLibrary _localDownloadLibrary;
  final YoutubeService _youtubeService;
  final IsarDatabaseService _isarService;
  final SongRepository _songRepository;
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
  final Map<String, bool> _fetchingBpm = {};

  final List<StreamSubscription<dynamic>> _subs = [];

  AudioNotifier(this._localDownloadLibrary, this._youtubeService, this._audioService, this._isarService, this._songRepository)

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
        final nextSong = state.playlist[index];
        Log.i('▶️ [ENGINE_PLAYING] Audio engine switched active track to index $index -> "${nextSong.title}" by "${nextSong.artist}" (ID: ${nextSong.id})');
        state = state.copyWith(
          currentIndex: index,
          currentSong: nextSong,
        );
        globalAudioHandler.setMediaFromSong(nextSong);
        _schedulePersistSession();
        _checkAndFetchBpm(nextSong);

        // Paced pre-fetch: resolve next 1 song for instant gapless transitions
        _prefetchUpcomingSongs(index, count: 1);
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
            bpm: state.currentSong.bpm,
          ),
        );
      }
    }));

    _subs.add(_audioService.bufferedPositionStream.listen((bufferedPosition) {
      if (!mounted) return;
      state = state.copyWith(bufferedPosition: bufferedPosition);
    }));

    if (_audioService is JustAudioService) {
      _subs.add(_audioService.errorStream.listen((error) {
        if (!mounted) return;
        Log.e('AudioNotifier: Playback error detected: $error');
        String userMessage = 'Playback failed';
        if (error.contains('403') || error.contains('Forbidden')) {
          userMessage = 'Stream unavailable - try downloading the song';
          YoutubeProxyServer.clearCaches();
        } else if (error.contains('SocketException') || error.contains('Network')) {
          userMessage = 'Network error - check your connection';
        } else if (error.contains('timeout')) {
          userMessage = 'Connection timeout - try again';
        }
        state = state.copyWith(
          status: PlaybackStatus.error,
          errorMessage: userMessage,
        );
      }));
    }

    _audioService.setVolume(1.0);
  }

  Future<void> _checkAndFetchBpm(SongMetadata song) async {
    if (song.bpm != null || song.id.isEmpty) return;
    if (_fetchingBpm[song.id] == true) return;

    _fetchingBpm[song.id] = true;
    Log.i('AudioNotifier: Background BPM fetch started for ${song.title}');
    try {
      final bpm = await _songRepository.fetchBpmRemotely(song.toEntity());
      if (bpm != null && mounted) {
        Log.i('AudioNotifier: Successfully retrieved BPM ($bpm) for ${song.title}');
        // Update the state if we are still playing the same song
        if (state.currentSong.id == song.id) {
          final updatedSong = SongMetadata(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album,
            artworkUrl: song.artworkUrl,
            duration: song.duration,
            source: song.source,
            bpm: bpm,
          );
          
          state = state.copyWith(currentSong: updatedSong);
          
          // Also update the playlist so it persists
          final newPlaylist = List<SongMetadata>.from(state.playlist);
          if (state.currentIndex >= 0 && state.currentIndex < newPlaylist.length) {
            newPlaylist[state.currentIndex] = updatedSong;
            state = state.copyWith(playlist: newPlaylist);
          }
          
          _schedulePersistSession();
        }

        // Persist to database so we don't have to fetch it again
        await _songRepository.updateBpm(song.id, bpm);
      }
    } catch (e) {
      Log.e('AudioNotifier: Failed to fetch BPM in background: $e');
    } finally {
      _fetchingBpm.remove(song.id);
    }
  }

  /// Pre-fetches stream URIs for upcoming songs to enable instant playback.
  /// [currentIndex] is the currently playing song index.
  /// [count] is how many upcoming songs to pre-fetch (default: 3).
  Future<void> _prefetchUpcomingSongs(int currentIndex, {int count = 1}) async {
    if (currentIndex < 0 || state.playlist.isEmpty) return;

    int staggeredCount = 0;
    for (var i = 1; i <= count; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex >= state.playlist.length) break;

      final upcomingSong = state.playlist[nextIndex];

      // Only pre-fetch remote sources
      if (upcomingSong.source == AudioSourceType.deezer ||
          upcomingSong.source == AudioSourceType.youtube) {
        if (staggeredCount > 0) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
        staggeredCount++;
        unawaited(_prefetchSongStream(upcomingSong));
      }
    }
  }

  Future<void> _prefetchSongStream(SongMetadata song) async {
    try {
      final videoId = await _songRepository.resolveStreamUri(song.toEntity());

      // Also pre-fetch the actual stream info through the proxy server
      if (Platform.isWindows && videoId.isNotEmpty) {
        YoutubeProxyServer.prefetchStream(videoId, _youtubeService.client);
      }
    } catch (e) {
      Log.w('AudioNotifier: Failed to pre-fetch stream for "${song.title}": $e');
    }
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

      state = state.copyWith(status: PlaybackStatus.loading, clearError: true);

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
  Future<void> playPlaylist(List<SongMetadata> playlist, int index) async {
    try {
      if (index < 0 || index >= playlist.length) return;
      final requestId = ++_playRequestId;
      _isRestoringSession = false;
      final clickedSong = playlist[index];
      Log.i('🎵 [USER_CLICK] User clicked song "${clickedSong.title}" by "${clickedSong.artist}" (ID: ${clickedSong.id}, source: ${clickedSong.source}) at index $index of ${playlist.length}');

      final canReuseCurrentQueue = !_isRestoringSession &&
          state.playlist.length == playlist.length &&
          state.playlist.isNotEmpty &&
          _hasSamePlaylistOrder(state.playlist, playlist);

      if (canReuseCurrentQueue) {
        final existingIndex = state.playlist.indexWhere((song) => song.id == clickedSong.id);
        if (existingIndex >= 0) {
          state = state.copyWith(
            status: PlaybackStatus.loading, clearError: true,
          );

          await _audioService.seek(Duration.zero, index: existingIndex);
          if (!mounted || requestId != _playRequestId) return;
          await _ensurePlaybackStarted();
          if (!mounted || requestId != _playRequestId) return;
          final resolvedIndex = _audioService.currentIndex ?? existingIndex;
          if (resolvedIndex < 0 || resolvedIndex >= state.playlist.length) return;
          final resolvedSong = state.playlist[resolvedIndex];
          state = state.copyWith(
            currentIndex: resolvedIndex,
            currentSong: resolvedSong,
          );
          globalAudioHandler.setMediaFromSong(resolvedSong);
          _syncStatusFromEngine();
          _schedulePersistSession();
          _checkAndFetchBpm(resolvedSong);
          _prefetchUpcomingSongs(resolvedIndex, count: 1);
          return;
        }
      }

      // Maintain exact 1-to-1 playlist order without rotation: [0, 1, 2, 3...]
      state = state.copyWith(
        playlist: playlist,
        status: PlaybackStatus.loading, clearError: true,
      );

      final sources = await Future.wait(
        playlist.map((song) => _buildAudioSource(song)),
      );
      if (!mounted || requestId != _playRequestId) return;

      await _audioService.setAudioQueue(sources, initialIndex: index, play: true);
      if (!mounted || requestId != _playRequestId) return;
      await _ensurePlaybackStarted();
      if (!mounted || requestId != _playRequestId) return;
      final resolvedIndex = _audioService.currentIndex ?? index;
      if (resolvedIndex < 0 || resolvedIndex >= playlist.length) return;
      final resolvedSong = playlist[resolvedIndex];
      state = state.copyWith(
        currentIndex: resolvedIndex,
        currentSong: resolvedSong,
      );
      globalAudioHandler.setMediaFromSong(resolvedSong);
      _syncStatusFromEngine();
      _schedulePersistSession();
      _checkAndFetchBpm(resolvedSong);
      _prefetchUpcomingSongs(resolvedIndex, count: 1);
    } catch (e) {
      _setPlaybackError('playPlaylist', e);
    }
  }

  bool _hasSamePlaylistOrder(List<SongMetadata> current, List<SongMetadata> next) {
    if (current.length != next.length) return false;

    for (var i = 0; i < current.length; i++) {
      if (current[i].id != next[i].id) {
        return false;
      }
    }

    return true;
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
      await _audioService.seek(Duration.zero, index: nextIndex).timeout(const Duration(seconds: 3));
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
        await _audioService.seek(Duration.zero).timeout(const Duration(seconds: 3));
        await _ensurePlaybackStarted();
        return;
      }

      final prevIndex = (state.currentIndex - 1 + state.playlist.length) % state.playlist.length;
      Log.i('Audio: Seeking previous track at index $prevIndex');
      await _audioService.seek(Duration.zero, index: prevIndex).timeout(const Duration(seconds: 3));
      await _ensurePlaybackStarted();
    } catch (e) {
      _setPlaybackError('previous', e);
    } finally {
      _isNavigatingQueue = false;
    }
  }

  Future<AudioSource> _buildAudioSource(SongMetadata song) async {
    Log.i('🛠️ [BUILD_SOURCE] Building AudioSource for "${song.title}" by "${song.artist}" (ID: ${song.id}, source: ${song.source})');
    // 1. Check Isar Database for local path
    String? localPath;
    try {
      final dbSong = await _isarService.getSongById(song.id);
      if (dbSong != null && dbSong.localPath != null) {
        localPath = dbSong.localPath;
      }
    } catch (e) {
      Log.w('AudioNotifier: Failed to lookup local path for ${song.id}: $e');
    }

    // Fallback: Check local downloads library directly by ID or sanitized title
    if (localPath == null) {
      try {
        final sanitizedTitle = YoutubeService.sanitizeFilePart(song.title);
        final downloadsDir = await AppStoragePaths.downloadsDirectory();
        if (await downloadsDir.exists()) {
          final rawId = song.id.replaceAll('deezer_', '').replaceAll('youtube_', '').replaceAll('jamendo_', '');
          await for (final entity in downloadsDir.list(recursive: false)) {
            if (entity is File) {
              final fileName = p.basename(entity.path).toLowerCase();
              if ((rawId.isNotEmpty && fileName.contains(rawId.toLowerCase())) ||
                  (sanitizedTitle.length > 2 && fileName.contains(sanitizedTitle.toLowerCase()))) {
                localPath = entity.path;
                Log.i('AudioNotifier: Local downloaded file HIT for "${song.title}" → $localPath');
                break;
              }
            }
          }
        }
      } catch (e) {
        Log.w('AudioNotifier: Downloads folder scan error for ${song.title}: $e');
      }
    }
    
    if (localPath != null && File(localPath).existsSync()) {
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
      'User-Agent': AetherColors.androidUserAgent,
    };

    // Priority: check if the provided sourceUrl is a direct stream URL (not youtube)
    if (sourceUrl.startsWith('http') && !sourceUrl.contains('youtube.com') && !sourceUrl.contains('youtu.be')) {
      return AudioSource.uri(Uri.parse(sourceUrl), headers: headers, tag: song);
    }

    // 4. Deezer track: resolve to YouTube via smart background search
    if (sourceUrl.startsWith('deezer_')) {
      // Lazy Resolution: We pass the query directly to the proxy server!
      // This prevents the UI from freezing when loading playlists, as the heavy YouTube search
      // is deferred until the exact moment the audio player tries to buffer the song.
      final port = await YoutubeProxyServer.start(_youtubeService.client);
      final queryStr = Uri.encodeComponent('${song.artist} ${song.title}');
      
      // We pass the deezer_id to bypass the ID check, and pass the query to trigger lazy search
      final proxyUrl = 'http://127.0.0.1:$port/?query=$queryStr&deezer_id=${song.id}';
      
      return AudioSource.uri(Uri.parse(proxyUrl), headers: headers, tag: song);
    }

    // 5. Resolve YouTube if needed
    final uri = Uri.tryParse(sourceUrl);
    String? videoId;
    if (uri != null && (uri.host.contains('youtube') || uri.host.contains('youtu.be'))) {
      videoId = uri.queryParameters['v'] ?? (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
    } else if (!sourceUrl.startsWith('http')) {
      videoId = sourceUrl;
    }

    if (videoId != null && videoId.isNotEmpty) {
      // Universal Streaming Proxy: Works on all platforms (Windows, Android, iOS)
      try {
        final port = await YoutubeProxyServer.start(_youtubeService.client);
        final proxyUrl = 'http://127.0.0.1:$port/?id=$videoId';
        return AudioSource.uri(Uri.parse(proxyUrl), headers: headers, tag: song);
      } catch (e) {
        Log.w('AudioNotifier: Proxy failed for YouTube video "$videoId": $e. Trying direct stream.');
        try {
          final directUrl = await _youtubeService.getStreamUri(videoId);
          return AudioSource.uri(Uri.parse(directUrl), headers: headers, tag: song);
        } catch (directError) {
          Log.e('AudioNotifier: Both proxy and direct failed for "$videoId": $directError');
          rethrow;
        }
      }
    } else {
      return AudioSource.uri(Uri.parse(sourceUrl), headers: headers, tag: song);
    }
  }

  void updateCurrentSongBpm(int newBpm) {
    if (state.currentSong.id.isNotEmpty) {
      final updated = SongMetadata(
        id: state.currentSong.id,
        title: state.currentSong.title,
        artist: state.currentSong.artist,
        album: state.currentSong.album,
        artworkUrl: state.currentSong.artworkUrl,
        duration: state.currentSong.duration,
        source: state.currentSong.source,
        bpm: newBpm,
      );
      state = state.copyWith(currentSong: updated);
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

  Timer? _sleepTimer;

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      state = state.copyWith(clearSleepTimer: true);
      Log.i('AudioNotifier: Sleep timer cancelled.');
      return;
    }

    final expireTime = DateTime.now().add(duration);
    state = state.copyWith(sleepTimerRemaining: duration);
    Log.i('AudioNotifier: Sleep timer set for ${duration.inMinutes}m.');

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = expireTime.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        _audioService.pause();
        state = state.copyWith(clearSleepTimer: true);
        Log.i('AudioNotifier: Sleep timer expired, playback paused.');
      } else {
        state = state.copyWith(sleepTimerRemaining: remaining);
      }
    });
  }

  void setEqPreset(String preset) {
    state = state.copyWith(eqPreset: preset);
    Log.i('AudioNotifier: Equalizer preset changed to "$preset".');
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sessionPersistDebounce?.cancel();
    unawaited(_persistPlaybackSession());

    for (final sub in _subs) {
      sub.cancel();
    }
    _visualizerTimer?.cancel();
    _frequencyController.close();
    _fetchingBpm.clear();
    super.dispose();
  }
}
