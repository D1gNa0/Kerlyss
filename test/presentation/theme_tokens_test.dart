import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/presentation/theme/aether_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('AetherColors defines deep charcoal black backdrop, burgundy, khaki, and cream text', () {
    expect(AetherColors.deepMatteBlack.value, equals(0xFF0A090A));
    expect(AetherColors.primaryAccent.value, equals(0xFF8B1E3F)); // Velvet Burgundy
    expect(AetherColors.secondaryAccent.value, equals(0xFFC3B091)); // Warm Khaki
    expect(AetherColors.textPrimary.value, equals(0xFFF5F2EB)); // Cream White
  });

  test('AetherTheme builds darkTheme with Outfit textTheme and deepMatteBlack scaffold', () {
    final theme = AetherTheme.darkTheme;
    expect(theme.scaffoldBackgroundColor, equals(AetherColors.deepMatteBlack));
    expect(theme.useMaterial3, isTrue);
  });
}
