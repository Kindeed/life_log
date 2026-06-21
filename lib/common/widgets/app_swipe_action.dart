import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppSwipeAction extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Alignment alignment;
  final String? label;

  const AppSwipeAction({
    super.key,
    required this.color,
    required this.icon,
    this.alignment = Alignment.centerRight,
    this.label,
  });

  const AppSwipeAction.delete({super.key, required this.color})
    : icon = Icons.delete_outline_rounded,
      alignment = Alignment.centerRight,
      label = null;

  @override
  Widget build(BuildContext context) {
    final alignRight = alignment.x > 0;
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: alignRight ? AppSpacing.lg : AppSpacing.xl,
        right: alignRight ? AppSpacing.xl : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!alignRight && label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Icon(icon, color: Colors.white),
          if (alignRight && label != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              label!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
