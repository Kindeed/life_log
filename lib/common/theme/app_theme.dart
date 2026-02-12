import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'custom_colors.dart';

/// 应用主题配置
class AppTheme {
  // --- 浅色主题 ---
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: const [LogColors.light], // 注册自定义颜色扩展
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      surface: AppColors.lightCard,
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
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Color(0xFF1C1B1F),
      titleTextStyle: TextStyle(
        color: Color(0xFF1C1B1F),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
  );

  // --- 深色主题 ---
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    extensions: const [LogColors.dark], // 注册自定义颜色扩展
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      primary: AppColors.primaryBlue,
      surface: AppColors.darkCard,
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
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkCard,
    ),
  );
}
