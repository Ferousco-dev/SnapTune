import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // Outfit — used for all display, headline, and title text
  static TextStyle outfit({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  // DM Sans — used for body and label text
  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  static TextTheme get textTheme => TextTheme(
        // Display — Outfit
        displayLarge: outfit(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12),
        displayMedium: outfit(fontSize: 45, fontWeight: FontWeight.w400, height: 1.15),
        displaySmall: outfit(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),

        // Headline — Outfit bold
        headlineLarge: outfit(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.25),
        headlineMedium: outfit(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.28),
        headlineSmall: outfit(fontSize: 24, fontWeight: FontWeight.w700, height: 1.33),

        // Title — Outfit semibold
        titleLarge: outfit(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
        titleMedium: outfit(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.5),
        titleSmall: outfit(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43),

        // Body — DM Sans
        bodyLarge: dmSans(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5),
        bodyMedium: dmSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
        bodySmall: dmSans(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33),

        // Label — DM Sans medium
        labelLarge: dmSans(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43),
        labelMedium: dmSans(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33),
        labelSmall: dmSans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45),
      );
}
