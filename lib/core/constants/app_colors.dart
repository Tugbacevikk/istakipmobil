import 'package:flutter/material.dart';

class AppColors {
  // Brand Red Palette (Matching Web Login & Header Theme)
  static const Color brandRedDark = Color(0xFFC0001A);
  static const Color brandRedLight = Color(0xFFE30613);

  // Primary Dark Slate Palette
  static const Color primary = Color(0xFF0F172A);       // Slate 900
  static const Color primaryLight = Color(0xFF1E293B);  // Slate 800
  static const Color cardDark = Color(0xFF1E293B);      // Slate 800
  static const Color cardBorder = Color(0xFF334155);    // Slate 700

  // Accents
  static const Color cyanAccent = Color(0xFF06B6D4);    // Video Analiz / Highlight
  static const Color accent = Color(0xFFE30613);        // Primary Red Accent

  // Status Colors
  static const Color working = Color(0xFF10B981);       // Emerald 500 (Çalışıyor)
  static const Color idle = Color(0xFFF59E0B);          // Amber 500 (Duruşta)
  static const Color welding = Color(0xFF8B5CF6);       // Purple 500 (Kaynak Yapıyor)
  static const Color alarm = Color(0xFFEF4444);         // Red 500 (Alarm / İhlal)

  // Background & Surface
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bgLight = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Dynamic Theme Helpers
  static Color getBg(bool isDark) => isDark ? bgDark : bgLight;
  static Color getCard(bool isDark) => isDark ? cardDark : Colors.white;
  static Color getText(bool isDark) => isDark ? textPrimary : const Color(0xFF0F172A);
  static Color getSubText(bool isDark) => isDark ? textSecondary : const Color(0xFF64748B);
  static Color getBorder(bool isDark) => isDark ? cardBorder : const Color(0xFFCBD5E1);
}
