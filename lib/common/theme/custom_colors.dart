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

  final Color work;
  final Color rest;
  final Color businessTrip;
  final Color leave;
  final Color overtime;
  final Color success; // Additional success color if needed outside of standard

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
      work: Color.lerp(work, other.work, t) ?? work,
      rest: Color.lerp(rest, other.rest, t) ?? rest,
      businessTrip:
          Color.lerp(businessTrip, other.businessTrip, t) ?? businessTrip,
      leave: Color.lerp(leave, other.leave, t) ?? leave,
      overtime: Color.lerp(overtime, other.overtime, t) ?? overtime,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }

  // 预定义浅色模式配色
  static const light = LogColors(
    work: Color(0xFF1A73E8), // Primary Blue
    rest: Color(0xFF248A3D), // Green
    businessTrip: Color(0xFFE77917), // Orange
    leave: Color(0xFF7D5FB2), // Purple
    overtime: Color(0xFFD70015), // Red for overtime emphasis
    success: Color(0xFF248A3D),
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
