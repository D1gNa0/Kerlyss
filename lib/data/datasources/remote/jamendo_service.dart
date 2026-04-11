import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/app_storage_paths.dart';
import '../../../core/services/logger_service.dart';
import '../../../domain/entities/audio_source_type.dart';
import '../../../domain/entities/downloaded_song.dart';
import '../../../domain/entities/song_entity.dart';

class JamendoService {
  static const String _baseUrl = 'https://api.jamendo.com/v3.0/tracks/';

  final Dio _dio;
  final String? _clientId;

  JamendoService(this._dio, {String? clientId}) : _clientId = clientId ?? _resolveClientId();

  bool get isConfigured => _clientId?.isNotEmpty == true;

  Future<List<SongEntity>> searchTracks(String query) async {
    if (!isConfigured) {
      Log.w('Jamendo search skipped because JAMENDO_CLIENT_ID is not configured.');
      return [];
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _baseUrl,
        queryParameters: {
          'client_id': _clientId,
          'format': 'json',
          'limit': 20,
          'search': query,
          'order': 'relevance',
          'audioformat': 'mp32',
          'audiodlformat': 'mp32',
          'include': 'musicinfo',
        },
      );

      final data = response.data;
      final results = data?['results'];
      if (results is! List) {
        return [];
      }

      return results
          .whereType<Map>()
          .map((entry) => _mapTrack(entry.cast<String, dynamic>()))
          .where((song) => song.sourceUrl.isNotEmpty)
          .toList();
    } catch (e, stackTrace) {
      Log.e('Jamendo search failed for "$query": $e');
      Log.e('$stackTrace');
      return [];
    }
  }

  Future<DownloadedSong> downloadTrack(SongEntity track) async {
    if (!isConfigured) {
      throw StateError('Jamendo client ID is not configured.');
    }

    if (track.sourceType != AudioSourceType.jamendo) {
      throw ArgumentError('Only Jamendo tracks can be downloaded through this service.');
    }

    if (track.sourceUrl.isEmpty) {
      throw ArgumentError('Jamendo track ${track.id} does not expose a download URL.');
    }

    final downloadsDirectory = await AppStoragePaths.downloadsDirectory();
    final destinationPath = _buildDestinationPath(downloadsDirectory.path, track);
    final destinationFile = File(destinationPath);

    if (await destinationFile.exists()) {
      return DownloadedSong.fromFile(destinationFile);
    }

    await _dio.download(
      track.sourceUrl,
      destinationPath,
      deleteOnError: true,
      options: Options(followRedirects: true),
    );

    return DownloadedSong.fromFile(destinationFile);
  }

  SongEntity _mapTrack(Map<String, dynamic> raw) {
    final rawId = raw['id']?.toString() ?? '';
    final title = _stringValue(raw['name']) ?? 'Untitled track';
    final artist = _stringValue(raw['artist_name']) ?? 'Unknown artist';
    final album = _stringValue(raw['album_name']) ?? 'Jamendo';
    final audioDownloadUrl = _stringValue(raw['audiodownload']) ?? '';
    final imageUrl = _stringValue(raw['image']) ?? _stringValue(raw['album_image']);
    final durationSeconds = _intValue(raw['duration']);
    final allowed = raw['audiodownload_allowed'] == true;

    return SongEntity(
      id: rawId.isEmpty ? 'jamendo_${title.hashCode}' : 'jamendo_$rawId',
      title: title,
      artist: artist,
      album: album,
      albumArtUrl: imageUrl,
      duration: Duration(seconds: durationSeconds),
      sourceUrl: allowed ? audioDownloadUrl : '',
      sourceType: AudioSourceType.jamendo,
    );
  }

  String _buildDestinationPath(String directoryPath, SongEntity track) {
    final safeArtist = _sanitizeFilePart(track.artist);
    final safeTitle = _sanitizeFilePart(track.title);
    final fileName = 'jamendo_${track.id}_$safeArtist-$safeTitle.mp3';
    return p.join(directoryPath, fileName);
  }

  static String? _resolveClientId() {
    const compileTimeClientId = String.fromEnvironment('JAMENDO_CLIENT_ID');
    if (compileTimeClientId.isNotEmpty) {
      return compileTimeClientId;
    }

    final dotenvClientId = dotenv.env['JAMENDO_CLIENT_ID'];
    if (dotenvClientId != null && dotenvClientId.trim().isNotEmpty) {
      return dotenvClientId.trim();
    }

    final runtimeClientId = Platform.environment['JAMENDO_CLIENT_ID'];
    if (runtimeClientId != null && runtimeClientId.trim().isNotEmpty) {
      return runtimeClientId.trim();
    }

    return null;
  }

  static String _sanitizeFilePart(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.replaceAll(' ', '_');
  }

  static String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
