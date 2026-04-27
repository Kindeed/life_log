import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class AppSafeBottomBar extends StatelessWidget {
  final Widget child;

  const AppSafeBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: semantic.border)),
        ),
        child: child,
      ),
    );
  }
}
