/// Removes personal data from log text BEFORE it is shown to the user or put into a
/// bug report. Best effort: it is deliberately aggressive (better to hide too much).
class LogSanitizer {
  LogSanitizer._();

  // URL with a query string -> keep the address, drop the parameters (they often hold
  // tokens, signatures and the user's IP, e.g. googlevideo `ip=...&expire=...`).
  static final RegExp _urlQuery = RegExp(r'''(https?://[^\s?#"')<>]+)\?[^\s"')<>]*''');
  static final RegExp _email = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+');
  // User folder names may contain spaces ("C:\Users\Kerem Arslan\..."), so take everything up to the next slash.
  static final RegExp _windowsUserDir = RegExp(r'([A-Za-z]:[\\/]+Users[\\/]+)[^\\/"\r\n]+', caseSensitive: false);
  static final RegExp _unixUserDir = RegExp(r'(/(?:Users|home)/)[^/"\r\n]+');
  static final RegExp _secretKeyValue = RegExp(
    r'''(token|access_token|refresh_token|authorization|bearer|api[_-]?key|client[_-]?secret|password|secret)(["'\s:=]+)[^\s"'&,}]+''',
    caseSensitive: false,
  );
  static final RegExp _ipv4 = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');
  // IPv6: either 8 full groups, or a form containing "::".
  static final RegExp _ipv6Full = RegExp(r'\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b');
  static final RegExp _ipv6Short = RegExp(r'\b(?:[0-9a-fA-F]{1,4}:){1,6}:(?:[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{1,4}){0,5})?(?![0-9a-fA-F:])');
  static final RegExp _longToken = RegExp(r'\b[A-Za-z0-9_\-]{40,}\b');
  static final RegExp _playlistName = RegExp(r'(playlist\s+)"[^"]*"', caseSensitive: false);

  static String sanitize(String input) {
    var s = input;
    s = s.replaceAllMapped(_urlQuery, (m) => '${m.group(1)}?<redacted>');
    s = s.replaceAll(_email, '<email>');
    s = s.replaceAllMapped(_windowsUserDir, (m) => '${m.group(1)}<user>');
    s = s.replaceAllMapped(_unixUserDir, (m) => '${m.group(1)}<user>');
    s = s.replaceAllMapped(_secretKeyValue, (m) => '${m.group(1)}${m.group(2)}<redacted>');
    s = s.replaceAll(_ipv6Full, '<ip>');
    s = s.replaceAll(_ipv6Short, '<ip>');
    s = s.replaceAll(_ipv4, '<ip>');
    s = s.replaceAll(_longToken, '<token>');
    s = s.replaceAllMapped(_playlistName, (m) => '${m.group(1)}"<name>"');
    return s;
  }

  static List<String> sanitizeAll(Iterable<String> lines) => lines.map(sanitize).toList();
}
