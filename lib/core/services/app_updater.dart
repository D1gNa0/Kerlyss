import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_storage_paths.dart';

/// Human-readable failure that can be shown directly to the user.
class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);

  @override
  String toString() => message;
}

/// Which release line an update comes from. The startup check and the normal
/// "Check for Updates" button only ever use [stable]; [beta] is opt-in (own button).
enum UpdateChannel { stable, beta }

class UpdateInfo {
  final String version;
  final String notes;
  final UpdateChannel channel;

  /// GitHub release tag that holds the files (beta only, e.g. `v1.4.0-beta.1`).
  final String? tag;

  const UpdateInfo({
    required this.version,
    required this.notes,
    this.channel = UpdateChannel.stable,
    this.tag,
  });

  bool get isBeta => channel == UpdateChannel.beta;
}

enum AndroidInstallResult { started, needsPermission }

/// All the "how do we update" logic (no UI, no Riverpod).
///
/// Release contract (see INSTRUCTIONS): for every release the repo must contain
///  - `version.json`   -> {"version": "1.3.4", "releaseNotes": "..."}
///  - `checksums.txt`  -> "Release Version: v1.3.4" + SHA-256 of both assets
///  - GitHub release assets named exactly `Kerlyss-Android.apk` / `Kerlyss-Windows.zip`
class AppUpdater {
  AppUpdater({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ));

  final Dio _dio;

  static const String versionUrl =
      'https://raw.githubusercontent.com/D1gNa0/Kerlyss/main/version.json';
  static const String checksumsUrl =
      'https://raw.githubusercontent.com/D1gNa0/Kerlyss/main/checksums.txt';
  // Beta channel: separate metadata files, so stable users can never see a beta.
  static const String betaVersionUrl =
      'https://raw.githubusercontent.com/D1gNa0/Kerlyss/main/beta.json';
  static const String betaChecksumsUrl =
      'https://raw.githubusercontent.com/D1gNa0/Kerlyss/main/checksums-beta.txt';
  static const String _releaseTagBase = 'https://github.com/D1gNa0/Kerlyss/releases/download';
  static const String _releaseBase =
      'https://github.com/D1gNa0/Kerlyss/releases/latest/download';

  static bool get supportsInAppUpdate => Platform.isAndroid || Platform.isWindows;
  static String get assetName => Platform.isAndroid ? 'Kerlyss-Android.apk' : 'Kerlyss-Windows.zip';
  static String get downloadUrl => '$_releaseBase/$assetName';

  /// Stable: GitHub's "latest release". Beta: the exact pre-release tag
  /// (GitHub's "latest" link never points to a pre-release).
  static String downloadUrlFor(UpdateInfo info) {
    if (info.isBeta) return '$_releaseTagBase/${info.tag}/$assetName';
    return downloadUrl;
  }

  // ───────────────────────── pure helpers (unit tested) ─────────────────────────

  /// Windows PowerShell can save files with a UTF-8 BOM (invisible first character), which
  /// makes `jsonDecode` fail. Remove it.
  static String stripBom(String text) => text.startsWith('\uFEFF') ? text.substring(1) : text;

  /// True when [latest] is a higher version than [current].
  /// Understands pre-releases: 1.4.0-beta.1 < 1.4.0-beta.2 < 1.4.0 (a final release
  /// is newer than any of its betas). The `+build` part is ignored.
  static bool isNewerVersion(String latest, String current) => compareVersions(latest, current) > 0;

  /// True for versions like `1.4.0-beta.1`.
  static bool isPrerelease(String version) => _ParsedVersion.parse(version).pre.isNotEmpty;

  /// Returns a negative number, 0, or a positive number (like `compareTo`).
  static int compareVersions(String a, String b) {
    final pa = _ParsedVersion.parse(a);
    final pb = _ParsedVersion.parse(b);

    final coreLength = pa.core.length > pb.core.length ? pa.core.length : pb.core.length;
    for (var i = 0; i < coreLength; i++) {
      final x = i < pa.core.length ? pa.core[i] : 0;
      final y = i < pb.core.length ? pb.core[i] : 0;
      if (x != y) return x > y ? 1 : -1;
    }

    // Same numbers: a version without a pre-release tag is newer than one with it.
    if (pa.pre.isEmpty && pb.pre.isEmpty) return 0;
    if (pa.pre.isEmpty) return 1;
    if (pb.pre.isEmpty) return -1;

    final preLength = pa.pre.length < pb.pre.length ? pa.pre.length : pb.pre.length;
    for (var i = 0; i < preLength; i++) {
      final x = pa.pre[i];
      final y = pb.pre[i];
      final xn = int.tryParse(x);
      final yn = int.tryParse(y);
      if (xn != null && yn != null) {
        if (xn != yn) return xn > yn ? 1 : -1;
      } else if (xn != null) {
        return -1; // numbers sort before words
      } else if (yn != null) {
        return 1;
      } else {
        final c = x.compareTo(y);
        if (c != 0) return c > 0 ? 1 : -1;
      }
    }
    if (pa.pre.length == pb.pre.length) return 0;
    return pa.pre.length > pb.pre.length ? 1 : -1;
  }

  /// Parses lines like `<64 hex chars>  Kerlyss-Android.apk` into {fileName: hash}.
  static Map<String, String> parseChecksums(String text) {
    final result = <String, String>{};
    final line = RegExp(r'^([A-Fa-f0-9]{64})\s+\*?(\S+)\s*$', multiLine: true);
    for (final m in line.allMatches(text)) {
      result[m.group(2)!] = m.group(1)!.toLowerCase();
    }
    return result;
  }

  /// Reads `Release Version: v1.3.4` -> `1.3.4`.
  static String? parseChecksumsVersion(String text) {
    final m = RegExp(r'Release Version:\s*[vV]?([0-9][0-9A-Za-z.\-]*)').firstMatch(text);
    return m?.group(1);
  }

  // ───────────────────────── check ─────────────────────────

  /// Returns the new version if one is available on [channel], otherwise null.
  Future<UpdateInfo?> fetchLatest({UpdateChannel channel = UpdateChannel.stable}) async {
    final isBeta = channel == UpdateChannel.beta;

    Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(isBeta ? betaVersionUrl : versionUrl);
    } on DioException catch (e) {
      // No beta.json in the repo = no beta is being tested right now (not an error).
      if (isBeta && e.response?.statusCode == 404) return null;
      rethrow;
    }

    final raw = response.data;
    final data = raw is String ? jsonDecode(stripBom(raw)) : raw;
    final latest = (data['version'] as String).trim();
    final notes = (data['releaseNotes'] as String?) ?? '';

    // Safety: the stable channel must never offer a pre-release by mistake.
    if (!isBeta && isPrerelease(latest)) return null;

    String? tag;
    if (isBeta) {
      tag = ((data['tag'] as String?) ?? 'v$latest').trim();
      if (!RegExp(r'^[A-Za-z0-9._+\-]+$').hasMatch(tag)) {
        throw const UpdateException('The beta release information is invalid.');
      }
    }

    final current = (await PackageInfo.fromPlatform()).version;
    if (!isNewerVersion(latest, current)) return null;
    return UpdateInfo(version: latest, notes: notes, channel: channel, tag: tag);
  }

  /// SHA-256 we must see for this platform's asset. Refuses to continue when the
  /// checksum file is for another release (release not fully published yet).
  Future<String> fetchExpectedHash(UpdateInfo info) async {
    final response = await _dio.get<String>(
      info.isBeta ? betaChecksumsUrl : checksumsUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final text = response.data ?? '';
    final listedVersion = parseChecksumsVersion(text);
    if (listedVersion == null || listedVersion != info.version.replaceFirst(RegExp(r'^[vV]'), '')) {
      throw const UpdateException('This update is not fully published yet. Please try again later.');
    }
    final hash = parseChecksums(text)[assetName];
    if (hash == null) {
      throw const UpdateException('Could not verify the update (no checksum published).');
    }
    return hash;
  }

  // ───────────────────────── download + verify ─────────────────────────

  Future<Directory> workDir() async {
    if (Platform.isWindows) {
      // Windows: keep the staged update in the app's data folder (not in Temp), so it is
      // still there after the app is closed and can be installed on quit / next start.
      final root = await AppStoragePaths.appRootDirectory();
      return Directory(p.join(root.path, 'update_staging'));
    }
    final temp = await getTemporaryDirectory();
    return Directory(p.join(temp.path, 'kerlyss_update'));
  }

  Future<void> cleanUp() async {
    try {
      final dir = await workDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Leftovers are harmless; they are cleaned on the next attempt.
    }
  }

  Future<void> download({
    required String url,
    required File target,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!url.startsWith('https://')) {
      throw const UpdateException('Refusing to download over an insecure connection.');
    }
    await target.parent.create(recursive: true);
    if (await target.exists()) await target.delete();
    await _dio.download(
      url,
      target.path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<bool> verifySha256(File file, String expected) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase() == expected.toLowerCase();
  }

  // ───────────────────────── Windows ─────────────────────────

  Directory get _installDir => File(Platform.resolvedExecutable).parent;

  /// Fails early (before a big download) when the app lives in a protected folder.
  Future<void> ensureInstallDirWritable() async {
    final probe = File(p.join(_installDir.path, '.kerlyss_write_test'));
    try {
      await probe.writeAsString('ok');
      await probe.delete();
    } catch (_) {
      throw const UpdateException(
        'Kerlyss is installed in a protected folder (like Program Files), so it cannot update itself. '
        'Move the Kerlyss folder somewhere normal (Documents, Desktop, D:\\) and try again.',
      );
    }
  }

  /// Unzips with PowerShell (built into Windows 10/11) and returns the folder that
  /// contains the app's .exe (the zip may or may not have a top-level folder).
  Future<Directory> extractWindowsZip(File zip, Directory workDir) async {
    final out = Directory(p.join(workDir.path, 'extracted'));
    if (await out.exists()) await out.delete(recursive: true);
    await out.create(recursive: true);

    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      "Expand-Archive -LiteralPath ${_ps(zip.path)} -DestinationPath ${_ps(out.path)} -Force",
    ]);
    if (result.exitCode != 0) {
      throw UpdateException('Could not unpack the update (${result.stderr.toString().trim()}).');
    }

    final exeName = p.basename(Platform.resolvedExecutable);
    await for (final entity in out.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path).toLowerCase() == exeName.toLowerCase()) {
        return entity.parent;
      }
    }
    throw UpdateException('The update package looks wrong ($exeName not found).');
  }

  /// Starts a hidden PowerShell script that waits for this process to exit, copies
  /// the new files over the install folder, and (when [relaunch] is true) starts the app again.
  /// With [relaunch] false the update is installed silently after the user closed the app.
  /// The app removes the staged files itself on the next start (see PendingUpdateManager.loadValid).
  /// The caller must exit the app right after this returns.
  Future<void> launchWindowsUpdater(Directory sourceDir, {bool relaunch = true}) async {
    final exePath = Platform.resolvedExecutable;
    final root = await AppStoragePaths.appRootDirectory();
    final scriptFile = File(p.join(sourceDir.parent.path, 'apply_update.ps1'));
    // The log lives in the app data folder: the staging folder is deleted after an update.
    final logPath = p.join(root.path, 'update.log');

    final script = _windowsScriptTemplate
        .replaceAll('{{PID}}', pid.toString())
        .replaceAll('{{LOG}}', _ps(logPath))
        .replaceAll('{{SRC}}', _ps(sourceDir.path))
        .replaceAll('{{DEST}}', _ps(_installDir.path))
        .replaceAll('{{EXE}}', _ps(exePath))
        .replaceAll('{{RELAUNCH}}', relaunch ? r'$true' : r'$false');

    // UTF-8 with BOM so Windows PowerShell 5.1 reads non-ASCII paths correctly.
    await scriptFile.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(script)]);

    await Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ],
      mode: ProcessStartMode.detached,
    );
  }

  static String _ps(String value) => "'${value.replaceAll("'", "''")}'";

  static const String _windowsScriptTemplate = r'''
$ErrorActionPreference = 'Continue'
$log = {{LOG}}
function Log($m) { Add-Content -LiteralPath $log -Value ("[" + (Get-Date -Format s) + "] " + $m) }
Log 'waiting for Kerlyss to exit'
try { Wait-Process -Id {{PID}} -Timeout 60 -ErrorAction SilentlyContinue } catch {}
Start-Sleep -Milliseconds 800
Log 'copying files'
& robocopy {{SRC}} {{DEST}} /E /IS /IT /R:10 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
  Log ('copy FAILED, robocopy exit code ' + $LASTEXITCODE)
} else {
  Log 'copy ok'
}
if ({{RELAUNCH}}) {
  Log 'restarting Kerlyss'
  Start-Process -FilePath {{EXE}} -WorkingDirectory {{DEST}}
}
''';

  // ───────────────────────── Android ─────────────────────────

  /// Opens the system installer for the downloaded APK.
  Future<AndroidInstallResult> installAndroid(File apk) async {
    final result = await OpenFilex.open(apk.path, type: 'application/vnd.android.package-archive');
    switch (result.type) {
      case ResultType.done:
        return AndroidInstallResult.started;
      case ResultType.permissionDenied:
        return AndroidInstallResult.needsPermission;
      default:
        throw UpdateException('Could not start the installer: ${result.message}');
    }
  }
}

/// `1.4.0-beta.1+12` -> core [1,4,0], pre ['beta','1'] (the `+12` build part is dropped).
class _ParsedVersion {
  final List<int> core;
  final List<String> pre;
  const _ParsedVersion(this.core, this.pre);

  factory _ParsedVersion.parse(String input) {
    var v = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final plus = v.indexOf('+');
    if (plus >= 0) v = v.substring(0, plus);

    String corePart = v;
    String prePart = '';
    final dash = v.indexOf('-');
    if (dash >= 0) {
      corePart = v.substring(0, dash);
      prePart = v.substring(dash + 1);
    }
    final core = corePart.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pre = prePart.isEmpty ? <String>[] : prePart.split('.');
    return _ParsedVersion(core, pre);
  }
}
