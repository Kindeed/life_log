import 'package:flutter/material.dart';

/// 业务逻辑自定义颜色扩展
/// 用于定义工时类型、状态等非标准 Material 颜色的语义化名称
@immutable
class LogColors extends ThemeExtension<LogColors> {
  const LogColors({
    required this.work,
    required this.rest,
    required this.businessTrip,
    required this.leave,
    required this.overtime,
    required this.success,
  });

  final Color? work;
  final Color? rest;
  final Color? businessTrip;
  final Color? leave;
  final Color? overtime;
  final Color?
  success; // Additional success color if needed outside of standard

  @override
  LogColors copyWith({
    Color? work,
    Color? rest,
    Color? businessTrip,
    Color? leave,
    Color? overtime,
    Color? success,
  }) {
    return LogColors(
      work: work ?? this.work,
      rest: rest ?? this.rest,
      businessTrip: businessTrip ?? this.businessTrip,
      leave: leave ?? this.leave,
      overtime: overtime ?? this.overtime,
      success: success ?? this.success,
    );
  }

  @override
  LogColors lerp(ThemeExtension<LogColors>? other, double t) {
    if (other is! LogColors) {
      return this;
    }
    return LogColors(
      work: Color.lerp(work, other.work, t),
      rest: Color.lerp(rest, other.rest, t),
      businessTrip: Color.lerp(businessTrip, other.businessTrip, t),
      leave: Color.lerp(leave, other.leave, t),
      overtime: Color.lerp(overtime, other.overtime, t),
      success: Color.lerp(success, other.success, t),
    );
  }

  // 预定义浅色模式配色
  static const light = LogColors(
    work: Color(0xFF1A73E8), // Primary Blue
    rest: Color(0xFF2E7D32), // Green
    businessTrip: Color(0xFFFF6D00), // Orange
    leave: Color(0xFF65558F), // Purple
    overtime: Color(0xFFD32F2F), // Red for overtime emphasis
    success: Color(0xFF2E7D32),
  );

  // 预定义深色模式配色
  static const dark = LogColors(
    work: Color(0xFF8AB4F8), // Lighter Blue
    rest: Color(0xFF81C995), // Lighter Green
    businessTrip: Color(0xFFFFCC80), // Lighter Orange
    leave: Color(0xFFD0BCFF), // Lighter Purple
    overtime: Color(0xFFF2B8B5), // Light Red
    success: Color(0xFF81C995),
  );
}
