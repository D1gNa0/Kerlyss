import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/presentation/theme/aether_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('AetherColors defines dark obsidian backdrop, electric indigo primary accent, emerald green success, and crimson error', () {
    expect(AetherColors.deepMatteBlack.value, equals(0xFF0A0A0E));
    expect(AetherColors.primaryAccent.value, equals(0xFF6366F1)); // Tier 3: Electric Indigo Slate
    expect(AetherColors.success.value, equals(0xFF10B981)); // Tier 2: Emerald Green
    expect(AetherColors.error.value, equals(0xFFE11D48)); // Tier 1: Crimson Red
    expect(AetherColors.textPrimary.value, equals(0xFFF9FAFB)); // Cream Off-White
  });

  test('AetherTheme builds darkTheme with Outfit textTheme and deepMatteBlack scaffold', () {
    final theme = AetherTheme.darkTheme;
    expect(theme.scaffoldBackgroundColor, equals(AetherColors.deepMatteBlack));
    expect(theme.useMaterial3, isTrue);
  });
}
