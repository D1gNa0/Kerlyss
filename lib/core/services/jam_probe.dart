import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Gives the signed-in Drive client (null when the user is not signed in).
typedef DriveApiProvider = Future<drive.DriveApi?> Function({bool forceRefresh});

class JamProbeException implements Exception {
  const JamProbeException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Min / average / max of the last 50 measured delays.
class DelayStats {
  final List<Duration> _values = <Duration>[];

  int get count => _values.length;

  void add(Duration delay) {
    _values.add(delay);
    if (_values.length > 50) _values.removeAt(0);
  }

  String get summary {
    if (_values.isEmpty) return 'no data yet';
    final ms = _values.map((d) => d.inMilliseconds).toList()..sort();
    final average = (ms.reduce((a, b) => a + b) / ms.length).round();
    return 'n=${ms.length}   min ${_seconds(ms.first)}   avg ${_seconds(average)}   max ${_seconds(ms.last)}';
  }

  static String _seconds(int ms) => '${(ms / 1000).toStringAsFixed(1)}s';
}

/// Small Google Drive experiments for the planned "Jam" (listen together) feature.
/// It answers two questions with real devices:
///  1. Can a friend's app read a file that was shared with them (drive.file scope)?
///  2. How long does a Drive write take to become visible on the other device?
/// Nothing here touches the normal sync file.
class JamProbe {
  JamProbe(this._api, {http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final DriveApiProvider _api;
  final http.Client _http;

  /// Counters for the test screen.
  int requests = 0;
  int failures = 0;

  static const String fileName = 'kerlyss_jam_probe.json';

  /// Short readable text for an error.
  static String describe(Object error) {
    if (error is drive.DetailedApiRequestError) return 'HTTP ${error.status}: ${error.message}';
    return error.toString();
  }

  Future<T> _call<T>(Future<T> Function(drive.DriveApi api) action) async {
    requests++;
    var api = await _api(forceRefresh: false);
    if (api == null) {
      failures++;
      throw const JamProbeException('Not signed in to Google. Sign in under Settings first.');
    }
    try {
      return await action(api);
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 401) {
        // The access token expired: get a fresh one and try once more.
        api = await _api(forceRefresh: true);
        if (api != null) {
          try {
            return await action(api);
          } catch (_) {
            failures++;
            rethrow;
          }
        }
      }
      failures++;
      rethrow;
    } catch (_) {
      failures++;
      rethrow;
    }
  }

  /// Creates the probe file in the user's Drive with [text] inside and returns its id.
  Future<String> createFile(String text) => _call((api) async {
        final bytes = utf8.encode(text);
        final created = await api.files.create(
          drive.File()
            ..name = fileName
            ..mimeType = 'application/json',
          uploadMedia: drive.Media(Stream<List<int>>.value(bytes), bytes.length),
          $fields: 'id',
        );
        final id = created.id;
        if (id == null) throw const JamProbeException('Drive did not return a file id');
        return id;
      });

  /// Replaces the content of the probe file. Returns Drive's own save time.
  Future<DateTime?> writeText(String id, String text) => _call((api) async {
        final bytes = utf8.encode(text);
        final updated = await api.files.update(
          drive.File(),
          id,
          uploadMedia: drive.Media(Stream<List<int>>.value(bytes), bytes.length),
          $fields: 'modifiedTime',
        );
        return updated.modifiedTime;
      });

  /// Cheap check: has the file changed? (version number + Drive save time)
  Future<({String? version, DateTime? modified})> readMeta(String id) => _call((api) async {
        final file = await api.files.get(id, $fields: 'modifiedTime,version') as drive.File;
        return (version: file.version, modified: file.modifiedTime);
      });

  /// Downloads the file content with the signed-in account.
  Future<String> readContent(String id) => _call((api) async {
        final media = await api.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final bytes = <int>[];
        await for (final chunk in media.stream) {
          bytes.addAll(chunk);
        }
        return utf8.decode(bytes, allowMalformed: true);
      });

  /// Downloads a link-shared file WITHOUT any login.
  Future<String> readPublic(String id) async {
    requests++;
    try {
      final response = await _http.get(
        Uri.parse('https://drive.google.com/uc?export=download&id=$id'),
        headers: const {'Cache-Control': 'no-cache'},
      );
      if (response.statusCode != 200) {
        throw JamProbeException('Public link answered HTTP ${response.statusCode}');
      }
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      failures++;
      rethrow;
    }
  }

  /// Gives [email] access to the file (reader, or editor when [canEdit]).
  Future<void> share(String id, String email, {required bool canEdit}) => _call((api) async {
        await api.permissions.create(
          drive.Permission()
            ..type = 'user'
            ..role = canEdit ? 'writer' : 'reader'
            ..emailAddress = email,
          id,
          sendNotificationEmail: false,
        );
      });

  /// "Anyone with the link can view".
  Future<void> makePublic(String id) => _call((api) async {
        await api.permissions.create(
          drive.Permission()
            ..type = 'anyone'
            ..role = 'reader',
          id,
        );
      });

  /// Files other people shared with this account that THIS APP is allowed to see.
  Future<List<String>> listSharedWithMe() => _call((api) async {
        final list = await api.files.list(
          q: 'sharedWithMe = true',
          pageSize: 20,
          $fields: 'files(id,name,owners(emailAddress))',
        );
        return (list.files ?? <drive.File>[])
            .map((f) => '${f.name} (${f.id}) from ${f.owners?.firstOrNull?.emailAddress ?? '?'}')
            .toList();
      });

  Future<void> deleteFile(String id) => _call((api) async {
        await api.files.delete(id);
      });

  /// How far this device's clock is AHEAD of Google's (negative = behind).
  /// Read from the HTTP Date header, so the accuracy is only about +-1 second.
  Future<Duration> clockOffsetToGoogle() async {
    final samples = <int>[];
    for (var i = 0; i < 3; i++) {
      try {
        final before = DateTime.now().toUtc();
        final response = await _http.head(Uri.parse('https://www.google.com/generate_204'));
        final after = DateTime.now().toUtc();
        final header = response.headers['date'];
        if (header == null) continue;
        final server = HttpDate.parse(header);
        final middle = before.add(after.difference(before) ~/ 2);
        samples.add(middle.difference(server).inMilliseconds);
      } catch (_) {
        // try the next sample
      }
    }
    if (samples.isEmpty) return Duration.zero;
    samples.sort();
    return Duration(milliseconds: samples[samples.length ~/ 2]);
  }
}
