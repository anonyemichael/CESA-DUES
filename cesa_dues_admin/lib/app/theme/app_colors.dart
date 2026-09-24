import 'package:flutter/material.dart';

/// CESA DUES Official Institutional & Fintech Palette.
class AppColors {
  AppColors._();

  // Brand Primaries
  static const Color primary = Color(0xFF0F172A);      // Deep Slate Navy
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color primaryDark = Color(0xFF020617);  // Slate 950
  
  // Brand Accent (Institutional Academic Blue & Gold)
  static const Color accent = Color(0xFF1E40AF);       // Cobalt Blue
  static const Color accentLight = Color(0xFF3B82F6);  // Blue 500
  static const Color secondary = accent;
  static const Color gold = Color(0xFFF59E0B);         // Amber Gold
  static const Color goldLight = Color(0xFFFEF3C7);    // Amber 100

  // Surface & Canvas
  static const Color background = Color(0xFFF8FAFC);  // Crisp Canvas Slate 50
  static const Color surface = Color(0xFFFFFFFF);     // Pure White Card
  static const Color inputFill = Color(0xFFF1F5F9);   // Subtle Slate 100
  static const Color cardAlt = Color(0xFFF8FAFC);
  static const Color chipBackground = Color(0xFFF1F5F9);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8);      // Slate 400
  static const Color textMuted = Color(0xFF94A3B8);

  // Semantic Status Colors
  static const Color success = Color(0xFF047857);       // Emerald 700
  static const Color successLight = Color(0xFFECFDF5);  // Emerald 50
  static const Color successBorder = Color(0xFFA7F3D0); // Emerald 200

  static const Color warning = Color(0xFFB45309);       // Amber 700
  static const Color warningLight = Color(0xFFFFFBEB);  // Amber 50
  static const Color warningBorder = Color(0xFFFDE68A); // Amber 200

  static const Color error = Color(0xFFB91C1C);         // Rose 700
  static const Color errorLight = Color(0xFFFEF2F2);    // Rose 50
  static const Color errorBorder = Color(0xFFFECACA);   // Rose 200

  static const Color info = Color(0xFF1D4ED8);          // Blue 700
  static const Color infoLight = Color(0xFFEFF6FF);     // Blue 50
  static const Color infoBorder = Color(0xFFBFDBFE);    // Blue 200

  // Payment Status Aliases
  static const Color paid = success;
  static const Color paidBackground = successLight;
  static const Color unpaid = error;
  static const Color unpaidBackground = errorLight;
  static const Color pending = warning;
  static const Color pendingBackground = warningLight;
  static const Color failed = error;
  static const Color failedBackground = errorLight;

  // Hairlines & Elevation
  static const Color border = Color(0xFFE2E8F0);        // 1px Slate 200
  static const Color borderStrong = Color(0xFFCBD5E1);  // Slate 300
  static const Color divider = Color(0xFFE2E8F0);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
}
