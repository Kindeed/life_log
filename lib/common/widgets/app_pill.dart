import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_status_colors.dart';

class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.fromTint(
      Theme.of(context),
      color,
      selected: selected,
    );
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.standardDecelerate,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: selected
            ? Border.all(color: colors.foreground.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
