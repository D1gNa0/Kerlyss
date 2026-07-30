import 'package:flutter/material.dart';

class AetherColors {
  // Primary Backdrop
  static const Color deepMatteBlack = Color(0xFF0C0C0C);
  static const Color ultraDarkGray = Color(0xFF121212);

  // Glass Elements
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white (thinner)
  static const Color glassBorder = Color(0x0DFFFFFF); // 5% white (subtle)
  static const Color glassShadow = Color(0x4D000000); // 30% black

  // Accent (Dynamic placeholder)
  static const Color primaryAccent = Color(0xFFA855F7); // Lucid Purple
  static const Color secondaryAccent = Color(0xFF3B82F6); // Electric Blue
  static const Color accentCyan = Color(0xFF22D3EE); // Vibrant Cyan


  // Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Status & Notifications (Centralized error/warning)
  static const Color error = Color(0xFFEF4444); // Red Accent
  static const Color warning = Color(0xFFF59E0B); // Amber Warning

  // Network Configuration
  static const String androidUserAgent = 'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36';
  static const String iosUserAgent = 'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)';
}
