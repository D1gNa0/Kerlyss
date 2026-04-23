import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_source_type.dart';
import '../../presentation/state/audio_state.dart';
import 'app_storage_paths.dart';

class PlaybackSessionSnapshot {
  final List<SongMetadata> playlist;
  final int currentIndex;
  final Duration position;
  final bool wasPlaying;
  final double volume;
  final bool isShuffleEnabled;
  final bool isRepeatEnabled;

  const PlaybackSessionSnapshot({
    required this.playlist,
    required this.currentIndex,
    required this.position,
    required this.wasPlaying,
    required this.volume,
    required this.isShuffleEnabled,
    required this.isRepeatEnabled,
  });
}

class PlaybackSessionStore {
  static const String _fileName = 'playback_session.json';

  Future<void> save(PlaybackSessionSnapshot snapshot) async {
    try {
      final root = await AppStoragePaths.appRootDirectory();
      final file = File('${root.path}${Platform.pathSeparator}$_fileName');

      final payload = <String, dynamic>{
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'currentIndex': snapshot.currentIndex,
        'positionMs': snapshot.position.inMilliseconds,
        'wasPlaying': snapshot.wasPlaying,
        'volume': snapshot.volume,
        'isShuffleEnabled': snapshot.isShuffleEnabled,
        'isRepeatEnabled': snapshot.isRepeatEnabled,
        'playlist': snapshot.playlist.map(_songToMap).toList(),
      };

      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (_) {
      // Best-effort cache. Ignore disk errors to avoid breaking playback.
    }
  }

  Future<PlaybackSessionSnapshot?> load() async {
    try {
      final root = await AppStoragePaths.appRootDirectory();
      final file = File('${root.path}${Platform.pathSeparator}$_fileName');
      if (!await file.exists()) {
        return null;
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }

      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final rawPlaylist = data['playlist'];
      if (rawPlaylist is! List) {
        return null;
      }

      final playlist = <SongMetadata>[];
      for (final item in rawPlaylist) {
        if (item is Map<String, dynamic>) {
          final song = _songFromMap(item);
          if (song != null) {
            playlist.add(song);
          }
        }
      }

      if (playlist.isEmpty) {
        return null;
      }

      final rawIndex = data['currentIndex'];
      final clampedIndex = (rawIndex is int ? rawIndex : 0).clamp(0, playlist.length - 1);

      final positionMs = data['positionMs'] is int ? data['positionMs'] as int : 0;
      final volume = data['volume'] is num ? (data['volume'] as num).toDouble() : 1.0;

      return PlaybackSessionSnapshot(
        playlist: playlist,
        currentIndex: clampedIndex,
        position: Duration(milliseconds: positionMs < 0 ? 0 : positionMs),
        wasPlaying: data['wasPlaying'] == true,
        volume: volume.clamp(0.0, 1.0),
        isShuffleEnabled: data['isShuffleEnabled'] == true,
        isRepeatEnabled: data['isRepeatEnabled'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _songToMap(SongMetadata song) {
    return <String, dynamic>{
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'artworkUrl': song.artworkUrl,
      'durationMs': song.duration.inMilliseconds,
      'source': song.source.name,
    };
  }

  SongMetadata? _songFromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    final artist = map['artist'];

    if (id is! String || id.isEmpty) return null;
    if (title is! String || title.isEmpty) return null;
    if (artist is! String || artist.isEmpty) return null;

    final durationMs = map['durationMs'] is int ? map['durationMs'] as int : 0;
    final sourceName = map['source'] is String ? map['source'] as String : AudioSourceType.local.name;
    final source = AudioSourceType.values.where((s) => s.name == sourceName).firstOrNull ?? AudioSourceType.local;

    return SongMetadata(
      id: id,
      title: title,
      artist: artist,
      album: map['album'] is String ? map['album'] as String : null,
      artworkUrl: map['artworkUrl'] is String ? map['artworkUrl'] as String : null,
      duration: Duration(milliseconds: durationMs < 0 ? 0 : durationMs),
      source: source,
    );
  }
}
