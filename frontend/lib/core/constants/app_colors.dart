import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Civic Palette (Deep Civic Teal)
  static const Color primary = Color(0xFF0F766E);       // Teal 700
  static const Color primaryHover = Color(0xFF0D9488);  // Teal 600
  static const Color primaryLight = Color(0xFFCCFBF1);  // Teal 100
  static const Color primaryDark = Color(0xFF115E59);   // Teal 800

  // Backgrounds (Clean White & Neutral Surfaces)
  static const Color background = Color(0xFFFFFFFF);     // Pure White
  static const Color surface = Color(0xFFFFFFFF);        // White Card Surface
  static const Color surfaceVariant = Color(0xFFF8FAFC); // Slate 50 Neutral Surface
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);        // Slate 200
  static const Color borderFocused = Color(0xFF0F766E); // Primary Focus Border
  static const Color divider = Color(0xFFF1F5F9);       // Slate 100

  // Typography / Text Colors
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900 High Contrast
  static const Color textSecondary = Color(0xFF475569); // Slate 600 Subtitle/Labels
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400 Placeholder
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on Teal

  // Feedback & Status
  static const Color error = Color(0xFFDC2626);         // Red 600
  static const Color errorBackground = Color(0xFFFEF2F2); // Red 50
  static const Color errorBorder = Color(0xFFFCA5A5);   // Red 300

  static const Color success = Color(0xFF16A34A);       // Green 600
  static const Color successBackground = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFF86EFAC);

  static const Color warning = Color(0xFFD97706);       // Amber 600
  static const Color warningBackground = Color(0xFFFFFBEB);

  static const Color info = Color(0xFF2563EB);          // Blue 600
  static const Color infoBackground = Color(0xFFEFF6FF);
}
