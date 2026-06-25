import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: _appBarTheme(Brightness.light),
        bottomNavigationBarTheme: _bottomNavTheme(Brightness.light),
        cardTheme: _cardTheme(AppColors.surface),
        filledButtonTheme: _filledButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        iconButtonTheme: _iconButtonTheme(),
        chipTheme: _chipTheme(Brightness.light),
        dividerTheme: const DividerThemeData(
          color: AppColors.outline,
          thickness: 0.5,
        ),
        pageTransitionsTheme: _pageTransitions,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: _appBarTheme(Brightness.dark),
        bottomNavigationBarTheme: _bottomNavTheme(Brightness.dark),
        cardTheme: _cardTheme(AppColors.darkSurface),
        filledButtonTheme: _filledButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        iconButtonTheme: _iconButtonTheme(),
        chipTheme: _chipTheme(Brightness.dark),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkOutline,
          thickness: 0.5,
        ),
        pageTransitionsTheme: _pageTransitions,
      );

  // ── Color Schemes ────────────────────────────────────────────────────────────

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.violet,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surfaceSelected,
    onSecondaryContainer: AppColors.primary,
    tertiary: AppColors.coral,
    onTertiary: AppColors.onCoral,
    tertiaryContainer: Color(0xFFFFEDE8),
    onTertiaryContainer: Color(0xFF7A2B10),
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFFFFEDED),
    onErrorContainer: Color(0xFF7A1010),
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.onSurface,
    onInverseSurface: AppColors.surface,
    inversePrimary: Color(0xFFBBB7FF),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFBBB7FF),
    onPrimary: Color(0xFF1A1A6E),
    primaryContainer: Color(0xFF3B3BAA),
    onPrimaryContainer: Color(0xFFEEEEFF),
    secondary: AppColors.violet,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF2A2A50),
    onSecondaryContainer: Color(0xFFCCBFFF),
    tertiary: AppColors.coral,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF5C2A1A),
    onTertiaryContainer: Color(0xFFFFCCB8),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF5A0000),
    errorContainer: Color(0xFF3A1010),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: Color(0xFF2E2E4A),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.darkOnSurface,
    onInverseSurface: AppColors.darkSurface,
    inversePrimary: AppColors.primary,
  );

  // ── Component Themes ─────────────────────────────────────────────────────────

  static AppBarTheme _appBarTheme(Brightness brightness) => AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
      );

  static BottomNavigationBarThemeData _bottomNavTheme(Brightness brightness) =>
      BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: brightness == Brightness.light
            ? AppColors.surface
            : AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: AppTypography.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  static CardThemeData _cardTheme(Color color) => CardThemeData(
        elevation: 0,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTypography.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.muted,
          textStyle: AppTypography.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  static IconButtonThemeData _iconButtonTheme() => IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ChipThemeData _chipTheme(Brightness brightness) => ChipThemeData(
        labelStyle: AppTypography.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    },
  );
}
