import 'package:flutter/material.dart';

class AppColors {
  // Primary Industrial Palette
  static const Color primary = Color(0xFF1E293B);      // Slate Dark 800
  static const Color primaryLight = Color(0xFF334155); // Slate 700
  static const Color accent = Color(0xFF0EA5E9);       // Sky Blue 500
  
  // Status Colors
  static const Color working = Color(0xFF10B981);      // Emerald 500 (Çalışıyor)
  static const Color idle = Color(0xFFF59E0B);         // Amber 500 (Duruşta)
  static const Color welding = Color(0xFF8B5CF6);      // Purple 500 (Kaynak Yapıyor)
  static const Color alarm = Color(0xFFEF4444);        // Red 500 (Alarm / İhlal)

  // Surface & Background Colors
  static const Color bgDark = Color(0xFF0F172A);       // Slate 900
  static const Color cardDark = Color(0xFF1E293B);     // Slate 800
  static const Color cardBorder = Color(0xFF334155);   // Slate 700

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);  // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);// Slate 400
}
