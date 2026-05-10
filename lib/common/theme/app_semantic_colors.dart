import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color work;
  final Color expense;
  final Color project;
  final Color stats;
  final Color success;
  final Color warning;
  final Color mutedSurface;
  final Color border;

  const AppSemanticColors({
    required this.work,
    required this.expense,
    required this.project,
    required this.stats,
    required this.success,
    required this.warning,
    required this.mutedSurface,
    required this.border,
  });

  static const light = AppSemanticColors(
    work: Color(0xFF007AFF),
    expense: Color(0xFF9B5CFF),
    project: Color(0xFF0F8F7A),
    stats: Color(0xFF0A84FF),
    success: Color(0xFF248A3D),
    warning: Color(0xFFFF9F0A),
    mutedSurface: Color(0xFFF2F2F7),
    border: Color(0xFFE0E0E6),
  );

  static const dark = AppSemanticColors(
    work: AppColors.primaryBlue,
    expense: Color(0xFFBF8CFF),
    project: Color(0xFF40C8B4),
    stats: Color(0xFF64D2FF),
    success: AppColors.successGreen,
    warning: Color(0xFFFF9F0A),
    mutedSurface: AppColors.darkMutedSurface,
    border: AppColors.darkDivider,
  );

  @override
  AppSemanticColors copyWith({
    Color? work,
    Color? expense,
    Color? project,
    Color? stats,
    Color? success,
    Color? warning,
    Color? mutedSurface,
    Color? border,
  }) {
    return AppSemanticColors(
      work: work ?? this.work,
      expense: expense ?? this.expense,
      project: project ?? this.project,
      stats: stats ?? this.stats,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      border: border ?? this.border,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      work: Color.lerp(work, other.work, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      project: Color.lerp(project, other.project, t)!,
      stats: Color.lerp(stats, other.stats, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
