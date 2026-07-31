import 'package:flutter/material.dart';

class AetherColors {
  // Primary Backdrop (Dark Charcoal Obsidian)
  static const Color deepMatteBlack = Color(0xFF0A0A0E);
  static const Color ultraDarkGray = Color(0xFF14141C);

  // Glass Elements
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white hairline
  static const Color glassShadow = Color(0x4D000000); // 30% black

  // 3-Tiered Color System (Color Theory)
  // Tier 3: Primary Neutral Actions (Electric Indigo)
  static const Color primaryAccent = Color(0xFF6366F1); 
  static const Color secondaryAccent = Color(0xFF818CF8);

  // Tier 2: Downloads & Offline Sync (Emerald Green)
  static const Color success = Color(0xFF10B981);
  static const Color downloadAccent = Color(0xFF10B981);

  // Tier 1: Caution & Destructive Actions (Crimson Red)
  static const Color error = Color(0xFFE11D48);
  static const Color cautionAccent = Color(0xFFE11D48);

  // Legacy compatibility tokens
  static const Color accentCyan = Color(0xFF6366F1);
  static const Color accentAmber = Color(0xFFF59E0B);

  // Text & Typography
  static const Color textPrimary = Color(0xFFF9FAFB); // Cream Off-White
  static const Color textSecondary = Color(0xFF9CA3AF); // Soft Slate Gray

  // Status & Notifications
  static const Color warning = Color(0xFFF59E0B);

  // Network Configuration
  static const String androidUserAgent = 'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36';
  static const String iosUserAgent = 'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)';
}
