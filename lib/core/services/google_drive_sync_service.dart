import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/local/isar_database_service.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../main.dart';
import 'logger_service.dart';

/// Custom authenticated HTTP client for googleapis
class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}

/// Service managing synchronization of playlists, favorites, and settings
/// using Google Drive's hidden AppData folder.
class GoogleDriveSyncService {
  static const String syncFileName = 'KerlyssSyncData.json';
  static const String driveScope = 'https://www.googleapis.com/auth/drive.file';

  // Windows Desktop OAuth Client ID and Secret
  // These must be provided at compile time via:
  // --dart-define=OAUTH_CLIENT_ID=xxx --dart-define=OAUTH_CLIENT_SECRET=yyy
  static const String desktopClientId = String.fromEnvironment(
    'OAUTH_CLIENT_ID',
    defaultValue: '',
  );
  static const String desktopClientSecret = String.fromEnvironment(
    'OAUTH_CLIENT_SECRET',
    defaultValue: '',
  );

  final IsarDatabaseService _isarService;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      driveScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _accessToken;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  GoogleDriveSyncService(this._isarService);

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null || _accessToken != null;
  bool get isSyncing => _isSyncing;
  String? get userEmail => _currentUser?.email;

  // --- Authentication ---

  /// Attempt silent sign-in on app startup
  Future<bool> silentSignIn() async {
    if (AetherHttpOverrides.isOfflineMode) {
      Log.i('GoogleDriveSync: Offline mode enabled, skipping silent sign-in.');
      return false;
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          _currentUser = account;
          final auth = await account.authentication;
          _accessToken = auth.accessToken;
          Log.i('GoogleDriveSync: Silent sign-in succeeded for ${account.email}');
          return true;
        }
      } else if (!kIsWeb && Platform.isWindows) {
        final settings = await _isarService.getSettings();
        if (settings.googleRefreshToken != null) {
          final response = await http.post(
            Uri.parse('https://oauth2.googleapis.com/token'),
            body: {
              'client_id': desktopClientId,
              if (desktopClientSecret.isNotEmpty) 'client_secret': desktopClientSecret,
              'refresh_token': settings.googleRefreshToken!,
              'grant_type': 'refresh_token',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            _accessToken = data['access_token'] as String?;
            Log.i('GoogleDriveSync: Windows silent sign-in succeeded.');
            return true;
          } else {
            Log.w('GoogleDriveSync: Windows silent sign-in failed (invalid refresh token).');
            // Clear the invalid token
            settings.googleRefreshToken = null;
            await _isarService.saveSettings(settings);
          }
        }
      }
    } catch (e) {
      Log.w('GoogleDriveSync: Silent sign-in failed: $e');
    }
    return false;
  }

  /// Interactive sign-in flow
  Future<bool> signIn() async {
    if (AetherHttpOverrides.isOfflineMode) {
      Log.w('GoogleDriveSync: Cannot sign in while Offline Mode is active.');
      throw const SocketException('Offline Mode is active. Disable it to connect Google Drive.');
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final account = await _googleSignIn.signIn();
        if (account != null) {
          _currentUser = account;
          final auth = await account.authentication;
          _accessToken = auth.accessToken;
          Log.i('GoogleDriveSync: Android sign-in successful: ${account.email}');
          return true;
        }
        return false;
      } else if (!kIsWeb && Platform.isWindows) {
        return await _signInWindowsDesktop();
      }
    } catch (e) {
      Log.e('GoogleDriveSync: Sign-in failed: $e');
      rethrow;
    }
    return false;
  }

  /// Sign out and clear stored tokens
  Future<void> signOut() async {
    _debounceTimer?.cancel();
    _currentUser = null;
    _accessToken = null;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      Log.w('GoogleDriveSync: Error signing out: $e');
    }
    Log.i('GoogleDriveSync: Signed out successfully.');
  }

  /// Windows Desktop loopback OAuth2 flow
  Future<bool> _signInWindowsDesktop() async {
    if (desktopClientId.isEmpty) {
      Log.w('GoogleDriveSync: Desktop Client ID is not configured.');
      throw StateError(
        'Google Desktop OAuth Client ID is not configured. '
        'Please compile with --dart-define=OAUTH_CLIENT_ID=...',
      );
    }

    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final redirectUri = 'http://localhost:${server.port}/oauth2callback';

      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': desktopClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'email $driveScope',
        'access_type': 'offline',
        'prompt': 'consent',
      });

      await launchUrl(authUri, mode: LaunchMode.externalApplication);

      final request = await server.first;
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];

      final response = request.response;
      response.headers.contentType = ContentType.html;

      if (code != null) {
        response.write('''
<!DOCTYPE html>
<html>
<head><title>Kerlyss - Connected</title></head>
<body style="background:#0F0F14;color:#fff;font-family:sans-serif;text-align:center;padding:50px;">
  <h2 style="color:#00F0FF;">Authentication Successful!</h2>
  <p>Google Drive has been connected to Kerlyss. You can close this tab and return to the app.</p>
</body>
</html>
''');
        await response.close();

        // Exchange authorization code for tokens
        final tokenResponse = await http.post(
          Uri.parse('https://oauth2.googleapis.com/token'),
          body: {
            'code': code,
            'client_id': desktopClientId,
            if (desktopClientSecret.isNotEmpty) 'client_secret': desktopClientSecret,
            'redirect_uri': redirectUri,
            'grant_type': 'authorization_code',
          },
        );

        if (tokenResponse.statusCode == 200) {
          final data = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
          _accessToken = data['access_token'] as String?;
          final refreshToken = data['refresh_token'] as String?;

          if (refreshToken != null) {
            final settings = await _isarService.getSettings();
            settings.googleRefreshToken = refreshToken;
            await _isarService.saveSettings(settings);
          }

          // Fetch user email
          if (_accessToken != null) {
            final userinfo = await http.get(
              Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
              headers: {'Authorization': 'Bearer $_accessToken'},
            );
            if (userinfo.statusCode == 200) {
              final info = jsonDecode(userinfo.body) as Map<String, dynamic>;
              Log.i('GoogleDriveSync: Windows desktop sign-in succeeded: ${info['email']}');
            }
          }
          return true;
        } else {
          Log.e('GoogleDriveSync: Token exchange failed: ${tokenResponse.body}');
          return false;
        }
      } else {
        response.write('<html><body><h3>Authentication Cancelled: $error</h3></body></html>');
        await response.close();
        return false;
      }
    } finally {
      await server?.close(force: true);
    }
  }

  // --- Drive API Client Helper ---

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_accessToken == null && _currentUser != null) {
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;
    }
    if (_accessToken == null) return null;

    final client = _AuthenticatedClient({'Authorization': 'Bearer $_accessToken'});
    return drive.DriveApi(client);
  }

  // --- Synchronization Operations ---

  /// Pull remote data from Drive root and merge into local database
  Future<bool> pullAndMerge() async {
    if (AetherHttpOverrides.isOfflineMode) {
      Log.i('GoogleDriveSync: Offline mode active, skipping pull.');
      return false;
    }

    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      Log.w('GoogleDriveSync: Cannot pull, not authenticated.');
      return false;
    }

    _isSyncing = true;
    try {
      Log.i('GoogleDriveSync: Checking Drive root for $syncFileName...');
      final fileList = await driveApi.files.list(
        q: "name = '$syncFileName' and trashed = false",
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        Log.i('GoogleDriveSync: No remote sync file found. Performing initial push.');
        await pushData();
        return true;
      }

      final file = fileList.files!.first;
      final fileId = file.id;
      if (fileId == null) return false;

      // Download content
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final contentBytes = await media.stream.fold<List<int>>([], (prev, element) => prev..addAll(element));
      final jsonString = utf8.decode(contentBytes);
      final remoteData = jsonDecode(jsonString) as Map<String, dynamic>;

      await _mergeRemoteData(remoteData);
      Log.i('GoogleDriveSync: Pull and merge completed successfully.');
      return true;
    } catch (e) {
      Log.e('GoogleDriveSync: Pull and merge failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Serialize local Isar database into JSON and upload to Drive root
  Future<bool> pushData() async {
    if (AetherHttpOverrides.isOfflineMode) {
      Log.i('GoogleDriveSync: Offline mode active, skipping push.');
      return false;
    }

    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      Log.w('GoogleDriveSync: Cannot push, not authenticated.');
      return false;
    }

    _isSyncing = true;
    try {
      final payload = await _exportLocalData();
      final jsonBytes = utf8.encode(jsonEncode(payload));
      final stream = Stream.value(jsonBytes);
      final media = drive.Media(stream, jsonBytes.length);

      // Check if file already exists
      final fileList = await driveApi.files.list(
        q: "name = '$syncFileName' and trashed = false",
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        Log.i('GoogleDriveSync: Updated existing $syncFileName in Drive.');
      } else {
        final newFile = drive.File()..name = syncFileName;
        await driveApi.files.create(
          newFile,
          uploadMedia: media,
        );
        Log.i('GoogleDriveSync: Created new $syncFileName in Drive.');
      }
      return true;
    } catch (e) {
      Log.e('GoogleDriveSync: Push data failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Schedule a debounced push (e.g. 4 seconds after a playlist or favorite is modified)
  void scheduleDebouncedPush({Duration delay = const Duration(seconds: 4)}) {
    if (!isSignedIn) return;
    if (AetherHttpOverrides.isOfflineMode) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      Log.i('GoogleDriveSync: Debounce timer triggered, pushing changes...');
      await pushData();
    });
  }

  // --- Data Serialization & Merging ---

  Future<Map<String, dynamic>> _exportLocalData() async {
    final playlists = await _isarService.getAllPlaylists();
    final allSongs = await _isarService.getAllSongs();
    final settings = await _isarService.getSettings();

    final songsJson = allSongs.map((s) => {
      'songId': s.songId,
      'title': s.title,
      'artist': s.artist,
      'album': s.album,
      'albumArtUrl': s.albumArtUrl,
      'durationMs': s.durationMs,
      'sourceUrl': s.sourceUrl,
      'sourceType': s.sourceType.name,
      'isFavorite': s.isFavorite,
      'bpm': s.bpm,
      'dateAdded': s.dateAdded.toIso8601String(),
    }).toList();

    final playlistsJson = playlists.map((p) => {
      'name': p.name,
      'songIds': p.songIds,
      'createdAt': p.createdAt.toIso8601String(),
      'isRealtimeSynced': p.isRealtimeSynced,
      'autoDownloadNewTracks': p.autoDownloadNewTracks,
      'spotifySourceUrl': p.spotifySourceUrl,
      'coverArtUrl': p.coverArtUrl,
      'lastSyncedAt': p.lastSyncedAt?.toIso8601String(),
    }).toList();

    return {
      'version': 1,
      'lastModified': DateTime.now().millisecondsSinceEpoch,
      'playlists': playlistsJson,
      'songs': songsJson,
      'dislikedSongIds': settings.dislikedSongIds,
      'dislikedArtists': settings.dislikedArtists,
      'settings': {
        'audioQuality': settings.audioQuality,
        'gaplessPlayback': settings.gaplessPlayback,
        'equalizerEnabled': settings.equalizerEnabled,
        'eqPreset': settings.eqPreset,
        'eqBandGains': settings.eqBandGains,
        'volume': settings.volume,
      },
    };
  }

  Future<void> _mergeRemoteData(Map<String, dynamic> remoteData) async {
    // 1. Merge Songs (hydrate songs metadata so titles/artists show immediately)
    if (remoteData['songs'] is List) {
      final remoteSongs = remoteData['songs'] as List;
      for (final item in remoteSongs) {
        if (item is Map<String, dynamic>) {
          final songId = item['songId'] as String?;
          if (songId == null || songId.isEmpty) continue;

          final existing = await _isarService.getSongById(songId);
          if (existing == null) {
            final song = SongModel()
              ..songId = songId
              ..title = (item['title'] as String?) ?? 'Unknown Title'
              ..artist = (item['artist'] as String?) ?? 'Unknown Artist'
              ..album = (item['album'] as String?) ?? 'Unknown Album'
              ..albumArtUrl = item['albumArtUrl'] as String?
              ..durationMs = (item['durationMs'] as int?) ?? 0
              ..sourceUrl = (item['sourceUrl'] as String?) ?? ''
              ..sourceType = _parseSourceType(item['sourceType'] as String?)
              ..isFavorite = (item['isFavorite'] as bool?) ?? false
              ..bpm = item['bpm'] as int?
              ..dateAdded = DateTime.tryParse(item['dateAdded'] as String? ?? '') ?? DateTime.now();
            await _isarService.saveSong(song);
          } else {
            // If remote marked as favorite and local is not, merge favorite status (union)
            final remoteFav = (item['isFavorite'] as bool?) ?? false;
            if (remoteFav && !existing.isFavorite) {
              existing.isFavorite = true;
              await _isarService.saveSong(existing);
            }
          }
        }
      }
    }

    // 2. Merge Playlists
    if (remoteData['playlists'] is List) {
      final remotePlaylists = remoteData['playlists'] as List;
      final localPlaylists = await _isarService.getAllPlaylists();
      final localByName = {for (final p in localPlaylists) p.name: p};

      for (final item in remotePlaylists) {
        if (item is Map<String, dynamic>) {
          final name = item['name'] as String?;
          if (name == null || name.isEmpty) continue;

          final rawSongIds = (item['songIds'] as List?)?.cast<String>() ?? [];
          final existing = localByName[name];

          if (existing == null) {
            // Brand new playlist from remote device
            final playlist = PlaylistModel()
              ..name = name
              ..songIds = rawSongIds
              ..createdAt = DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now()
              ..isRealtimeSynced = (item['isRealtimeSynced'] as bool?) ?? false
              ..autoDownloadNewTracks = (item['autoDownloadNewTracks'] as bool?) ?? false
              ..spotifySourceUrl = item['spotifySourceUrl'] as String?
              ..coverArtUrl = item['coverArtUrl'] as String?
              ..lastSyncedAt = DateTime.now();
            await _isarService.savePlaylist(playlist);
          } else {
            // Playlist exists locally: merge song IDs (preserve local order + append unique remote)
            final mergedSongIds = List<String>.from(existing.songIds);
            for (final sid in rawSongIds) {
              if (!mergedSongIds.contains(sid)) {
                mergedSongIds.add(sid);
              }
            }
            existing.songIds = mergedSongIds;
            existing.lastSyncedAt = DateTime.now();
            if (item['coverArtUrl'] != null && existing.coverArtUrl == null) {
              existing.coverArtUrl = item['coverArtUrl'] as String?;
            }
            await _isarService.savePlaylist(existing);
          }
        }
      }
    }

    // 3. Merge Settings (disliked songs/artists union)
    final localSettings = await _isarService.getSettings();
    bool settingsChanged = false;

    if (remoteData['dislikedSongIds'] is List) {
      final remoteDislikedSongs = (remoteData['dislikedSongIds'] as List).cast<String>();
      final merged = Set<String>.from(localSettings.dislikedSongIds)..addAll(remoteDislikedSongs);
      if (merged.length != localSettings.dislikedSongIds.length) {
        localSettings.dislikedSongIds = merged.toList();
        settingsChanged = true;
      }
    }

    if (remoteData['dislikedArtists'] is List) {
      final remoteDislikedArtists = (remoteData['dislikedArtists'] as List).cast<String>();
      final merged = Set<String>.from(localSettings.dislikedArtists)..addAll(remoteDislikedArtists);
      if (merged.length != localSettings.dislikedArtists.length) {
        localSettings.dislikedArtists = merged.toList();
        settingsChanged = true;
      }
    }

    if (settingsChanged) {
      await _isarService.saveSettings(localSettings);
    }
  }

  AudioSourceType _parseSourceType(String? name) {
    if (name == null) return AudioSourceType.youtube;
    return AudioSourceType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AudioSourceType.youtube,
    );
  }
}
