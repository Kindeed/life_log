import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_status_colors.dart';
import '../theme/app_radius.dart';
import '../theme/theme_extensions.dart';

enum AppFeedbackKind { success, info, error }

/// Capture before closing an editor; the handle does not retain its context.
class AppFeedback {
  final ScaffoldMessengerState? _messenger;
  final ThemeData _theme;
  final TextScaler _textScaler;
  final TextDirection _direction;
  final double _availableWidth;

  AppFeedback.capture(BuildContext context)
    : _messenger = ScaffoldMessenger.maybeOf(context),
      _theme = Theme.of(context),
      _textScaler = MediaQuery.textScalerOf(context),
      _direction = Directionality.of(context),
      _availableWidth =
          MediaQuery.sizeOf(context).width -
          MediaQuery.paddingOf(context).horizontal -
          32;

  void success(String message) => show(message, kind: AppFeedbackKind.success);
  void info(String message) => show(message);
  void error(String message) => show(message, kind: AppFeedbackKind.error);

  void show(String message, {AppFeedbackKind kind = AppFeedbackKind.info}) {
    final messenger = _messenger;
    if (messenger == null || !messenger.mounted) return;
    final scheme = _theme.colorScheme;
    final colors = switch (kind) {
      AppFeedbackKind.success => AppStatusColors.fromTint(
        _theme,
        _theme.semanticColors.success,
      ),
      AppFeedbackKind.info => AppStatusColors(
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      AppFeedbackKind.error => AppStatusColors(
        scheme.onErrorContainer,
        scheme.errorContainer,
      ),
    };
    final style = _theme.textTheme.bodyMedium!.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w500,
    );
    final text = TextPainter(
      text: TextSpan(text: message, style: style),
      textScaler: _textScaler,
      textDirection: _direction,
    )..layout();
    final maximum = math.max(1.0, math.min(420.0, _availableWidth));
    final width = math.min(maximum, math.max(136.0, text.width + 60));
    text.dispose();

    messenger
      ..clearSnackBars()
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.container,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: colors.foreground.withValues(alpha: 0.12)),
          ),
          duration: kind == AppFeedbackKind.error
              ? const Duration(seconds: 4)
              : const Duration(seconds: 2),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (kind) {
                  AppFeedbackKind.success => Icons.check_circle_outline_rounded,
                  AppFeedbackKind.info => Icons.info_outline_rounded,
                  AppFeedbackKind.error => Icons.error_outline_rounded,
                },
                color: colors.foreground,
                size: 18,
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(message, style: style)),
            ],
          ),
        ),
      );
  }
}
