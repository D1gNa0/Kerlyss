import '../../domain/repositories/audio_service_interface.dart';
import '../../data/datasources/local/just_audio_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;


import 'package:flutter_riverpod/flutter_riverpod.dart';
// Using custom AudioServiceInterface

import 'package:kerlyss/core/services/logger_service.dart';
import 'package:kerlyss/data/datasources/local/local_download_library.dart';
import 'package:kerlyss/core/services/youtube_proxy_server.dart';
import 'package:kerlyss/data/datasources/remote/youtube_service.dart';
import 'package:kerlyss/data/repositories/repository_providers.dart';
import 'package:kerlyss/presentation/state/downloaded_songs_provider.dart';


import 'audio_state.dart';

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final localDownloadLibrary = ref.watch(localDownloadLibraryProvider);
  final audioService = JustAudioService();
  final youtubeService = ref.watch(youtubeServiceProvider);
  return AudioNotifier(localDownloadLibrary, youtubeService, audioService);
});


/// Audio engine backed by just_audio.
/// YouTube playback goes through a local proxy so the player only sees a plain
/// HTTP audio stream.
class AudioNotifier extends StateNotifier<AudioState> {
  final AudioServiceInterface _audioService;
  final LocalDownloadLibrary _localDownloadLibrary;
  final YoutubeService _youtubeService;


  final _frequencyController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyController.stream;
  Timer? _visualizerTimer;

  final List<StreamSubscription<dynamic>> _subs = [];

  AudioNotifier(this._localDownloadLibrary, this._youtubeService, this._audioService)

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
      
      Log.i('Audio status changed: $status');
      state = state.copyWith(status: status);

      if (status == PlaybackStatus.completed) {
        next();
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

  /// Plays a specific song from a playlist and loads the rest of the list into the queue.
  Future<void> playPlaylist(List<SongMetadata> playlist, int index) async {
    if (index < 0 || index >= playlist.length) return;
    
    state = state.copyWith(
      playlist: playlist,
      currentIndex: index,
    );
    
    final song = playlist[index];
    globalAudioHandler.updateMediaItem(song);
    await playSong(song, song.id); 
  }

  Future<void> next() async {
    if (state.playlist.isEmpty) {
      Log.w('Audio: Cannot play next, playlist is empty');
      return;
    }
    
    final nextIndex = (state.currentIndex + 1) % state.playlist.length;
    Log.i('Audio: Auto-playing next track at index $nextIndex');
    
    // Small delay to let the previous session settle
    await Future.delayed(const Duration(milliseconds: 100));
    await playPlaylist(state.playlist, nextIndex);
  }

  void previous() {
    if (state.playlist.isEmpty) return;
    var prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) prevIndex = state.playlist.length - 1;
    playPlaylist(state.playlist, prevIndex);
  }

  Future<void> playSong(SongMetadata song, String sourceUrl) async {
    state = state.copyWith(currentSong: song, status: PlaybackStatus.loading);
    globalAudioHandler.updateMediaItem(song);

    try {
      // 1. Check for local download first
      String? videoId;
      final uri = Uri.tryParse(sourceUrl);

      if (uri != null &&
          (uri.host.contains('youtube') || uri.host.contains('youtu.be'))) {
        videoId = uri.queryParameters['v'];
        videoId ??= uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      } else if (!sourceUrl.startsWith('http')) {
        videoId = sourceUrl;
      }

      // Special case: Jamendo IDs are jamendo_ID
      final lookupId = videoId ?? song.id;
      final actualId = lookupId.startsWith('jamendo_') 
          ? lookupId.replaceFirst('jamendo_', '') 
          : lookupId;

      Log.d('playSong -> Looking for local file with ID: $actualId');
      final localSong = await _localDownloadLibrary.findDownloadedSongById(actualId);
      
      if (localSong != null) {
        final normalizedPath = _normalizePath(localSong.path);
        Log.d('playSong -> FOUND local file! Playing: $normalizedPath');
        
        // Brief delay to ensure file handle is released by OS after download
        await Future.delayed(const Duration(milliseconds: 200));
        await _audioService.setFilePath(normalizedPath);
        await _audioService.play();
        return;
      }

      // 2. If not local, proceed with streaming
      if (sourceUrl.startsWith('file://') || File(sourceUrl).existsSync()) {
        final localPath = sourceUrl.startsWith('file://')
            ? Uri.parse(sourceUrl).toFilePath()
            : sourceUrl;

        final finalPath = _normalizePath(localPath);
        Log.d('playSong -> Opening direct local file (fallback): $finalPath');

        // Brief delay to ensure file handle is released by OS after download
        await Future.delayed(const Duration(milliseconds: 200));
        await _audioService.setFilePath(finalPath);
        await _audioService.play();
        return;
      }

      Log.d('playSong -> No local file found. Proceeding with stream for ID: "$videoId"');

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

      if (videoId != null && videoId.isNotEmpty) {
        final port = await YoutubeProxyServer.start(_youtubeService.client);
        final proxyUrl = 'http://127.0.0.1:$port/?id=$videoId';

        Log.d('playSong -> Opening PROXY stream: $proxyUrl');
        await _audioService.setUrl(proxyUrl, headers: headers);
      } else {
        Log.d('playSong -> Opening direct stream: $sourceUrl');
        await _audioService.setUrl(sourceUrl, headers: headers);
      }

      await _audioService.play();
      Log.d('playSong -> just_audio started successfully');
    } catch (e, stacktrace) {

      Log.e('playSong -> FATAL ERROR: $e');
      Log.e('Stacktrace: $stacktrace');
      if (mounted) {
        state = state.copyWith(status: PlaybackStatus.error);
      }
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
