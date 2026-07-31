import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/presentation/theme/aether_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('AetherColors defines dark obsidian backdrop, warm crimson coral accent, and cream text', () {
    expect(AetherColors.deepMatteBlack.value, equals(0xFF0A0A0E));
    expect(AetherColors.primaryAccent.value, equals(0xFFF43F5E)); // Warm Crimson Coral
    expect(AetherColors.secondaryAccent.value, equals(0xFFFB7185)); // Crimson Glow Highlight
    expect(AetherColors.textPrimary.value, equals(0xFFF9FAFB)); // Cream Off-White
  });

  test('AetherTheme builds darkTheme with Outfit textTheme and deepMatteBlack scaffold', () {
    final theme = AetherTheme.darkTheme;
    expect(theme.scaffoldBackgroundColor, equals(AetherColors.deepMatteBlack));
    expect(theme.useMaterial3, isTrue);
  });
}
