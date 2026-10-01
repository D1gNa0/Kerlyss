import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeveloperMessage JSON Schema & Parsing Tests', () {
    test('parses full developer message payload accurately', () {
      const jsonStr = '''
      {
        "id": "msg_2026_01",
        "showMessage": true,
        "title": "Important Update",
        "message": "We have added new features.",
        "actionLabel": "Read More",
        "actionUrl": "https://d1gna0.github.io/Kerlyss/",
        "dismissable": true,
        "priority": "warning"
      }
      ''';

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(data['id'], equals('msg_2026_01'));
      expect(data['showMessage'], isTrue);
      expect(data['title'], equals('Important Update'));
      expect(data['message'], equals('We have added new features.'));
      expect(data['actionLabel'], equals('Read More'));
      expect(data['actionUrl'], equals('https://d1gna0.github.io/Kerlyss/'));
      expect(data['dismissable'], isTrue);
      expect(data['priority'], equals('warning'));
    });

    test('handles default fallback values safely when fields are omitted', () {
      const jsonStr = '''
      {
        "showMessage": false
      }
      ''';

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final showMessage = (data['showMessage'] as bool?) ?? false;
      final id = (data['id'] as String?) ?? 'default_msg';
      final title = (data['title'] as String?) ?? 'Developer Message';
      final dismissable = (data['dismissable'] as bool?) ?? true;
      final priority = (data['priority'] as String?) ?? 'info';

      expect(showMessage, isFalse);
      expect(id, equals('default_msg'));
      expect(title, equals('Developer Message'));
      expect(dismissable, isTrue);
      expect(priority, equals('info'));
      expect(data['actionUrl'], isNull);
    });
  });
}
