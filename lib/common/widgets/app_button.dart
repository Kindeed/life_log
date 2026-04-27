import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';

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
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    final minimumSize = Size.fromHeight(height);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            shape: shape,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            minimumSize: minimumSize,
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: semantic.border),
            shape: shape,
          ),
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(minimumSize: minimumSize, shape: shape),
          child: child,
        );
      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            elevation: 0,
            shape: shape,
          ),
          child: child,
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
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
    );
  }
}
