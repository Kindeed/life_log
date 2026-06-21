import 'package:flutter/material.dart';

class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final primary = colorScheme.onSurface;
    final secondary = colorScheme.onSurfaceVariant;

    return TextTheme(
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 17, letterSpacing: 0),
      bodyMedium: TextStyle(color: primary, fontSize: 15, letterSpacing: 0),
      bodySmall: TextStyle(color: secondary, fontSize: 13, letterSpacing: 0),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}
