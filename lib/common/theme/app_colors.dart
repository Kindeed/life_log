import 'package:flutter/material.dart';

/// 应用颜色定义
/// 统一管理所有颜色常量，支持浅色/深色模式
class AppColors {
  // --- 语义化主色调 (两种模式共用) ---
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color orange = Color(0xFFFF6D00);
  static const Color purple = Color(0xFF65558F);
  static const Color green = Color(0xFF2E7D32);

  // --- 浅色模式 ---
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xDD000000); // black87
  static const Color lightTextSecondary = Color(0x99000000); // black60
  static const Color lightDivider = Color(0xFFE0E0E0);

  // --- 深色模式 ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // white70
  static const Color darkDivider = Color(0xFF2C2C2C);

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
  static const Color successGreen = Color(0xFF2E7D32); // Keep widely used green
  static const Color successContainerLight = Color(0xFFE8F5E9);
  static const Color onSuccessContainerLight = Color(0xFF1B5E20);
  static const Color successContainerDark = Color(0xFF1B5E20);
  static const Color onSuccessContainerDark = Color(0xFFE8F5E9);
}
