import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'custom_colors.dart';

/// 应用主题配置
class AppTheme {
  // --- 浅色主题 ---
  static ThemeData get light => lightWith();

  static ThemeData lightWith([ColorScheme? dynamicScheme]) {
    final colorScheme =
        dynamicScheme?.copyWith(
          onPrimary: Colors.white,
          error: AppColors.errorLight,
          onError: AppColors.onErrorLight,
          errorContainer: AppColors.errorContainerLight,
          onErrorContainer: AppColors.onErrorContainerLight,
        ) ??
        ColorScheme.fromSeed(
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
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: const [LogColors.light, AppSemanticColors.light],
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: const CircleBorder(),
        ),
      ),
      textTheme: AppTypography.textTheme(colorScheme),
    );
  }

  // --- 深色主题 ---
  static ThemeData get dark => darkWith();

  static ThemeData darkWith([ColorScheme? dynamicScheme]) {
    final colorScheme =
        dynamicScheme?.copyWith(
          onPrimary: Colors.white,
          error: AppColors.errorDark,
          onError: AppColors.onErrorDark,
          errorContainer: AppColors.errorContainerDark,
          onErrorContainer: AppColors.onErrorContainerDark,
        ) ??
        ColorScheme.fromSeed(
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
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const [LogColors.dark, AppSemanticColors.dark],
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: const CircleBorder(),
        ),
      ),
      textTheme: AppTypography.textTheme(colorScheme),
    );
  }
}
