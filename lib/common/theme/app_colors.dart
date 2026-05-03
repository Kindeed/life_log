import 'package:flutter/material.dart';

/// 应用颜色定义
/// 统一管理所有颜色常量，支持浅色/深色模式
class AppColors {
  // --- 语义化主色调 (两种模式共用) ---
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color orange = Color(0xFFFF9500);
  static const Color purple = Color(0xFFAF52DE);
  static const Color green = Color(0xFF34C759);

  // --- 浅色模式 ---
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightDivider = Color(0xFFD1D1D6);

  // --- 深色模式 ---
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF98989D);
  static const Color darkDivider = Color(0xFF2C2C2E);

  // --- 语义化颜色 (Material 3 Standard) ---
  // Error - Light
  static const Color errorLight = Color(0xFFB3261E);
  static const Color onErrorLight = Colors.white;
  static const Color errorContainerLight = Color(0xFFF9DEDC);
  static const Color onErrorContainerLight = Color(0xFF410E0B);

  // Error - Dark
  static const Color errorDark = Color(0xFFF2B8B5);
  static const Color onErrorDark = Color(0xFF601410);
  static const Color errorContainerDark = Color(0xFF8C1D18);
  static const Color onErrorContainerDark = Color(0xFFF9DEDC);

  // Success (Custom)
  static const Color successGreen = green;
  static const Color successContainerLight = Color(0xFFE7F8EC);
  static const Color onSuccessContainerLight = Color(0xFF0B5D22);
  static const Color successContainerDark = Color(0xFF123D20);
  static const Color onSuccessContainerDark = Color(0xFFD7F6DF);
}
