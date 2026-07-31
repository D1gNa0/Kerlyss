import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aether_colors.dart';

class AetherTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AetherColors.deepMatteBlack,
      primaryColor: AetherColors.primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: AetherColors.primaryAccent,
        secondary: AetherColors.secondaryAccent,
        surface: AetherColors.ultraDarkGray,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AetherColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 32,
            letterSpacing: 2,
          ),
          displayMedium: TextStyle(
            color: AetherColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 4,
          ),
          titleLarge: TextStyle(
            color: AetherColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          bodyLarge: TextStyle(
            color: AetherColors.textPrimary,
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: AetherColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AetherColors.glassWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AetherColors.glassBorder),
        ),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(
        color: AetherColors.textPrimary,
        size: 24,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AetherColors.textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AetherColors.primaryAccent,
          foregroundColor: AetherColors.textPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AetherColors.primaryAccent.withValues(alpha: 0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AetherColors.primaryAccent,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AetherColors.primaryAccent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AetherColors.textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      useMaterial3: true,
    );
  }
}
