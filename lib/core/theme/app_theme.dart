import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1D4ED8); // Royal Tekzivo Blue (matching Web app header)
  static const Color secondary = Color(0xFF0F172A); // Dark slate
  static const Color accent = Color(0xFFD97706); // Warm Amber/Gold (matching Web app "Book Service" button)
  static const Color accentHover = Color(0xFFB45309);
  static const Color badgeBg = Color(0xFFEFF6FF); // Soft pastel blue icon container (Blue-50)
  static const Color background = Color(0xFFF8FAFC); // Clean off-white
  static const Color cardBg = Colors.white;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFAF8E00);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        background: background,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
