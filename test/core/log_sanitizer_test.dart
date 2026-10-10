import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/log_sanitizer.dart';

void main() {
  group('LogSanitizer', () {
    test('removes emails', () {
      expect(LogSanitizer.sanitize('sign-in succeeded for kerem01arslan01@gmail.com.'),
          'sign-in succeeded for <email>.');
    });

    test('removes URL query strings but keeps the address', () {
      final out = LogSanitizer.sanitize(
          'Upstream 403, uri = https://rr2---sn-ajnv4c-5h.googlevideo.com/videoplayback?expire=1791578963&ip=2a09%3Abac5&id=abc');
      expect(out, contains('https://rr2---sn-ajnv4c-5h.googlevideo.com/videoplayback?<redacted>'));
      expect(out, isNot(contains('expire=')));
      expect(out, isNot(contains('2a09')));
    });

    test('removes user names from Windows and unix paths', () {
      expect(LogSanitizer.sanitize(r'C:\Users\kerem\AppData\Local\kerlyss'), r'C:\Users\<user>\AppData\Local\kerlyss');
      expect(LogSanitizer.sanitize('C:/Users/kerem/Music'), 'C:/Users/<user>/Music');
      expect(LogSanitizer.sanitize('/home/melih/.config/x'), '/home/<user>/.config/x');
    });

    test('removes user names that contain spaces', () {
      expect(LogSanitizer.sanitize(r'C:\Users\Kerem Arslan\AppData\Local\kerlyss'), r'C:\Users\<user>\AppData\Local\kerlyss');
    });

    test('removes IPv4 and IPv6 addresses', () {
      expect(LogSanitizer.sanitize('connect to 192.168.1.20 failed'), 'connect to <ip> failed');
      expect(LogSanitizer.sanitize('ip 2a09:bac5:58bc:2682::3d6:c end'), 'ip <ip> end');
      expect(LogSanitizer.sanitize('addr 2001:0db8:85a3:0000:0000:8a2e:0370:7334 end'), 'addr <ip> end');
    });

    test('does not mangle timestamps', () {
      expect(LogSanitizer.sanitize('[12:30:45] INFO: ok'), '[12:30:45] INFO: ok');
    });

    test('redacts secrets and playlist names', () {
      expect(LogSanitizer.sanitize('refresh_token=abc123XYZ and more'), contains('refresh_token=<redacted>'));
      expect(LogSanitizer.sanitize('Remote update applied for playlist "80s Music I found on Insta" (uuid: x)'),
          'Remote update applied for playlist "<name>" (uuid: x)');
      expect(LogSanitizer.sanitize('key ${'a' * 45} end'), 'key <token> end');
    });

    test('leaves normal log text alone', () {
      const text = 'INFO: YoutubeProxyServer: Selected audio stream for eu7o5wMl2fw (147 kbps)';
      expect(LogSanitizer.sanitize(text), text);
    });
  });
}
