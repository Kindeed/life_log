import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'custom_colors.dart';

/// 应用主题配置
class AppTheme {
  // --- 浅色主题 ---
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: const [LogColors.light, AppSemanticColors.light],
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.standard,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      surface: AppColors.lightCard,
      surfaceContainerHighest: AppColors.lightMutedSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      error: AppColors.errorLight,
      onError: AppColors.onErrorLight,
      errorContainer: AppColors.errorContainerLight,
      onErrorContainer: AppColors.onErrorContainerLight,
      // Map success to tertiary or custom? M3 standard uses tertiary for "custom" roles sometimes.
      // But we have extension, so we rely on extension for business logic.
      // We can map Success to TertiaryContainer if we want standard widgets to pick it up,
      // but let's stick to extension for explicit business logic.
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    dividerColor: AppColors.lightDivider,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.lightTextPrimary,
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.lightTextSecondary,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.lightTextPrimary,
        shape: const CircleBorder(),
      ),
    ),
    textTheme: _textTheme(Brightness.light),
  );

  // --- 深色主题 ---
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    extensions: const [LogColors.dark, AppSemanticColors.dark],
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.standard,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      surface: AppColors.darkCard,
      surfaceContainerHighest: AppColors.darkMutedSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: AppColors.errorDark,
      onError: AppColors.onErrorDark,
      errorContainer: AppColors.errorContainerDark,
      onErrorContainer: AppColors.onErrorContainerDark,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkDivider,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.darkTextSecondary,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        shape: const CircleBorder(),
      ),
    ),
    textTheme: _textTheme(Brightness.dark),
  );

  static TextTheme _textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondary = brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return TextTheme(
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.08,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 17),
      bodyMedium: TextStyle(color: primary, fontSize: 15),
      bodySmall: TextStyle(color: secondary, fontSize: 13),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
