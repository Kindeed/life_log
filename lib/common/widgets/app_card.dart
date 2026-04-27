import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: semantic.border),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: content,
      ),
    );
  }
}
