import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: _appBarTheme(Brightness.light),
        navigationBarTheme: _navBarTheme(Brightness.light),
        cardTheme: _cardTheme(),
        filledButtonTheme: _filledButtonTheme(),
        iconButtonTheme: _iconButtonTheme(),
        dividerTheme: const DividerThemeData(
          color: AppColors.outlineVariant,
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
        navigationBarTheme: _navBarTheme(Brightness.dark),
        cardTheme: _cardTheme(),
        filledButtonTheme: _filledButtonTheme(),
        iconButtonTheme: _iconButtonTheme(),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkOutlineVariant,
          thickness: 0.5,
        ),
        pageTransitionsTheme: _pageTransitions,
      );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.onInverseSurface,
    inversePrimary: AppColors.inversePrimary,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.inversePrimary,
    onPrimary: AppColors.onPrimaryContainer,
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimaryContainer: AppColors.darkOnPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondaryContainer,
    secondaryContainer: AppColors.darkSecondaryContainer,
    onSecondaryContainer: AppColors.darkOnSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiaryContainer,
    tertiaryContainer: AppColors.darkTertiaryContainer,
    onTertiaryContainer: AppColors.darkOnTertiaryContainer,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.darkInverseSurface,
    onInverseSurface: AppColors.darkOnInverseSurface,
    inversePrimary: AppColors.primary,
  );

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

  static NavigationBarThemeData _navBarTheme(Brightness brightness) =>
      NavigationBarThemeData(
        elevation: 0,
        backgroundColor: brightness == Brightness.light
            ? AppColors.surface
            : AppColors.darkSurface,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );

  static CardThemeData _cardTheme() => CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    },
  );
}
