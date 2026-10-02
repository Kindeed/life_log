import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/app_motion.dart';
import 'app_press_feedback.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.height = 48,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;
    final callback = isLoading || onPressed == null
        ? null
        : () {
            if (variant == AppButtonVariant.destructive) {
              HapticFeedback.heavyImpact();
            }
            onPressed!();
          };

    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    final minimumSize = Size.fromHeight(height);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return AppPressFeedback(
          enabled: callback != null,
          child: FilledButton(
            onPressed: callback,
            style: FilledButton.styleFrom(
              minimumSize: minimumSize,
              disabledBackgroundColor: semantic.mutedSurface,
              disabledForegroundColor: Theme.of(context).disabledColor,
              shape: shape,
              textStyle: textStyle,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.secondary:
        return AppPressFeedback(
          enabled: callback != null,
          child: FilledButton.tonal(
            onPressed: callback,
            style: FilledButton.styleFrom(
              minimumSize: minimumSize,
              shape: shape,
              textStyle: textStyle,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.text:
        return AppPressFeedback(
          enabled: callback != null,
          child: TextButton(
            onPressed: callback,
            style: TextButton.styleFrom(
              minimumSize: minimumSize,
              shape: shape,
              textStyle: textStyle,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.destructive:
        return AppPressFeedback(
          enabled: callback != null,
          child: FilledButton(
            onPressed: callback,
            style: FilledButton.styleFrom(
              minimumSize: minimumSize,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              shape: shape,
              textStyle: textStyle,
            ),
            child: child,
          ),
        );
    }
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final labelContent = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: AppMotion.duration(context, AppMotion.fast),
          opacity: isLoading ? 0 : 1,
          child: labelContent,
        ),
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
