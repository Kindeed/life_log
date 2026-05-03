import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class AppSafeBottomBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppSafeBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return SafeArea(
      top: false,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: semantic.border)),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}
