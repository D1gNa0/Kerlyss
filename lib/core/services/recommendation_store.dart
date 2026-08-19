import 'dart:convert';
import 'dart:io';

import '../../domain/entities/audio_source_type.dart';
import '../../domain/entities/song_entity.dart';
import '../../presentation/state/recommendations_provider.dart';
import 'app_storage_paths.dart';

class RecommendationSnapshot {
  final List<SongEntity> similarSongs;
  final List<SongEntity> trendingSongs;
  final Map<String, String> similarReasons;
  final String? baseIdeaArtist;
  final RecommendationMode mode;
  final DateTime? lastFetchedAt;

  const RecommendationSnapshot({
    required this.similarSongs,
    required this.trendingSongs,
    required this.similarReasons,
    this.baseIdeaArtist,
    required this.mode,
    this.lastFetchedAt,
  });
}

class RecommendationStore {
  static const String _fileName = 'recommendations_cache.json';

  Future<void> save(RecommendationSnapshot snapshot) async {
    try {
      final root = await AppStoragePaths.appRootDirectory();
      final file = File('${root.path}${Platform.pathSeparator}$_fileName');

      final payload = <String, dynamic>{
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'mode': snapshot.mode.name,
        'baseIdeaArtist': snapshot.baseIdeaArtist,
        'similarReasons': snapshot.similarReasons,
        'lastFetchedAt': snapshot.lastFetchedAt?.toIso8601String(),
        'similarSongs': snapshot.similarSongs.map(_songToMap).toList(),
        'trendingSongs': snapshot.trendingSongs.map(_songToMap).toList(),
      };

      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (_) {
      // Best-effort cache. Ignore disk errors.
    }
  }

  Future<RecommendationSnapshot?> load() async {
    try {
      final root = await AppStoragePaths.appRootDirectory();
      final file = File('${root.path}${Platform.pathSeparator}$_fileName');
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final rawSimilar = json['similarSongs'] as List<dynamic>? ?? [];
      final rawTrending = json['trendingSongs'] as List<dynamic>? ?? [];
      final rawReasons = json['similarReasons'] as Map<String, dynamic>? ?? {};

      final similarSongs = rawSimilar
          .map((item) => _songFromMap(item as Map<String, dynamic>))
          .whereType<SongEntity>()
          .toList();

      final trendingSongs = rawTrending
          .map((item) => _songFromMap(item as Map<String, dynamic>))
          .whereType<SongEntity>()
          .toList();

      final similarReasons = rawReasons.map((k, v) => MapEntry(k, v.toString()));

      final modeName = json['mode'] as String? ?? 'auto';
      final mode = RecommendationMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => RecommendationMode.auto,
      );

      final baseIdeaArtist = json['baseIdeaArtist'] as String?;
      final lastFetchedAtRaw = json['lastFetchedAt'] as String?;
      final lastFetchedAt = lastFetchedAtRaw != null ? DateTime.tryParse(lastFetchedAtRaw) : null;

      if (similarSongs.isEmpty && trendingSongs.isEmpty) {
        return null;
      }

      return RecommendationSnapshot(
        similarSongs: similarSongs,
        trendingSongs: trendingSongs,
        similarReasons: similarReasons,
        baseIdeaArtist: baseIdeaArtist,
        mode: mode,
        lastFetchedAt: lastFetchedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _songToMap(SongEntity s) {
    return {
      'id': s.id,
      'title': s.title,
      'artist': s.artist,
      'album': s.album,
      'durationMs': s.duration.inMilliseconds,
      'sourceUrl': s.sourceUrl,
      'sourceType': s.sourceType.name,
      'albumArtUrl': s.albumArtUrl,
      'localPath': s.localPath,
      'dateAdded': s.dateAdded.toIso8601String(),
    };
  }

  SongEntity? _songFromMap(Map<String, dynamic> map) {
    try {
      final id = map['id'] as String? ?? '';
      final title = map['title'] as String? ?? '';
      final artist = map['artist'] as String? ?? '';
      if (id.isEmpty || title.isEmpty) return null;

      final sourceTypeStr = map['sourceType'] as String? ?? 'youtube';
      final sourceType = AudioSourceType.values.firstWhere(
        (st) => st.name == sourceTypeStr,
        orElse: () => AudioSourceType.youtube,
      );

      return SongEntity(
        id: id,
        title: title,
        artist: artist,
        album: map['album'] as String? ?? '',
        duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
        sourceUrl: map['sourceUrl'] as String? ?? '',
        sourceType: sourceType,
        albumArtUrl: map['albumArtUrl'] as String?,
        localPath: map['localPath'] as String?,
        dateAdded: DateTime.tryParse(map['dateAdded'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
