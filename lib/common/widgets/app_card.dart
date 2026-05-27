import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.lg);
    final color = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.025),
      theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.36 : 0.52,
      ),
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: semantic.border.withValues(alpha: isDark ? 0.5 : 0.72),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
