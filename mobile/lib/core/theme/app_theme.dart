import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Berry Pink to Crimson Red Palette (Matching Reference UI)
  static const Color primaryBerry = Color(0xFFB80046);
  static const Color darkBerry = Color(0xFF880E4F);
  static const Color vividPink = Color(0xFFE91E63);
  static const Color softRose = Color(0xFFF06292);
  static const Color blushPink = Color(0xFFF8BBD0);
  static const Color lightBlush = Color(0xFFFCE4EC);
  static const Color ultraLightBlush = Color(0xFFFFF0F5);

  // Background and Surface
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFFAFAFB);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Compatibility aliases for legacy and sub-components
  static const Color primaryRed = primaryBerry;
  static const Color accentPink = lightBlush;
  static const Color textPrimary = textDark;
  static const Color backgroundLight = bgLight;
  static const Color borderLight = borderSubtle;
  static const Color womenPurple = Color(0xFF9333EA);
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color cardDarkElevated = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFFFFFFFF);

  // Text & Accents
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Status Colors
  static const Color policeBlue = Color(0xFF1E40AF);
  static const Color safeGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBerry,
        primary: primaryBerry,
        secondary: vividPink,
        surface: bgWhite,
        onSurface: textDark,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontFamily: GoogleFonts.poppins().fontFamily,
          color: textDark,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontFamily: GoogleFonts.poppins().fontFamily,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }
}
