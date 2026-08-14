import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get darkLuxury {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.base,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold, onPrimary: Color(0xFF1A1407), secondary: AppColors.gold,
        surface: AppColors.surface, onSurface: AppColors.ink, error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.base, elevation: 0, scrolledUnderElevation: 0),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.surface, selectedItemColor: AppColors.gold, unselectedItemColor: AppColors.muted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.surfaceHi,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gold, width: 1.4)),
        labelStyle: const TextStyle(color: AppColors.muted), hintStyle: const TextStyle(color: AppColors.muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF1A1407), elevation: 0,
        minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      )),
    );
  }
  static TextStyle display([double size = 28, Color? color]) => GoogleFonts.playfairDisplay(fontSize: size, fontWeight: FontWeight.w600, color: color ?? AppColors.ink, letterSpacing: -0.02);
  static TextStyle monoNum([double size = 15]) => TextStyle(fontFamily: 'monospace', fontSize: size, fontFeatures: const [FontFeature.tabularFigures()], color: AppColors.ink);
}
