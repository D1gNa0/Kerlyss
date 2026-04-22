import '../../domain/repositories/audio_service_interface.dart';
import '../../data/datasources/local/just_audio_service.dart';
import 'dart:async';
import 'dart:io';
import '../../main.dart';
import 'package:path/path.dart' as p;


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show AudioSource;
// Using custom AudioServiceInterface

import 'package:kerlyss/core/services/logger_service.dart';
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
  final dynamic _isarService;

  final _frequencyController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyController.stream;
  Timer? _visualizerTimer;

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
  }

  void _init() {
        _subs.add(_audioService.playbackStatusStream.listen((status) {
      if (!mounted) return;
      
      Log.i('Audio status changed: $status (Current state: ${state.status})');

      // Ignore idle/buffering status if we are in a loading state to prevent flickering
      // This ensures the spinner stays until the engine is truly Ready or Playing.
      if (state.status == PlaybackStatus.loading && 
          (status == PlaybackStatus.idle || status == PlaybackStatus.buffering)) {
        return;
      }

      state = state.copyWith(status: status);
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
      }
    }));


    _subs.add(_audioService.positionStream.listen((position) {
      if (!mounted) return;
      state = state.copyWith(position: position);
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
    if (index < 0 || index >= playlist.length) return;

    // Reorder: [clicked, ...after clicked, ...before clicked]
    final reordered = [
      ...playlist.sublist(index),
      ...playlist.sublist(0, index),
    ];

    state = state.copyWith(
      playlist: reordered,
      currentIndex: 0,
      currentSong: reordered[0],
      status: PlaybackStatus.loading,
    );
    globalAudioHandler.setMediaFromSong(reordered[0]);

    final sources = await Future.wait(
      reordered.map((song) => _buildAudioSource(song)),
    );
    if (!mounted) return;

    await _audioService.setAudioQueue(sources, initialIndex: 0, play: true);
  }








  Future<void> addNext(SongMetadata song) async {
    if (state.playlist.isEmpty) {
      playPlaylist([song], 0);
      return;
    }
    final newPlaylist = List<SongMetadata>.from(state.playlist);
    newPlaylist.insert(state.currentIndex + 1, song);
    state = state.copyWith(playlist: newPlaylist);

    final source = await _buildAudioSource(song);
    await _audioService.insertIntoQueue(state.currentIndex + 1, source);
  }

  Future<void> addLast(SongMetadata song) async {
    if (state.playlist.isEmpty) {
      playPlaylist([song], 0);
      return;
    }
    final newPlaylist = List<SongMetadata>.from(state.playlist);
    newPlaylist.add(song);
    state = state.copyWith(playlist: newPlaylist);

    final source = await _buildAudioSource(song);
    await _audioService.insertIntoQueue(newPlaylist.length - 1, source);
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
  }

  Future<void> next() async {
    if (state.playlist.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % state.playlist.length;
    Log.i('Audio: Seeking next track at index $nextIndex');
    await _audioService.seek(Duration.zero, index: nextIndex);
  }

  Future<void> previous() async {
    if (state.playlist.isEmpty) return;
    if (_audioService.position > const Duration(seconds: 4)) {
      await _audioService.seek(Duration.zero);
      return;
    }
    var prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) prevIndex = state.playlist.length - 1;
    await _audioService.seek(Duration.zero, index: prevIndex);
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
  }

  void seek(Duration position) {
    _audioService.seek(position);
  }

  void setVolume(double volume) {
    _audioService.setVolume(volume);
    state = state.copyWith(volume: volume);
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
  }

  /// Normalizes file path separators for Windows.
  /// just_audio_windows passes paths directly to WMF which requires backslashes.
  String _normalizePath(String path) {
    if (Platform.isWindows) {
      return p.normalize(path).replaceAll('/', '\\');
    }
    return p.normalize(path);
  }
}
