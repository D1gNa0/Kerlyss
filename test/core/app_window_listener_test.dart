import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/app_window_listener.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  test('AppWindowListener inherits WindowListener', () {
    final listener = AppWindowListener();
    expect(listener, isA<WindowListener>());
  });
}
