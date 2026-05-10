import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';

import '../theme/app_elevations.dart';
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
    final semantic = theme.semanticColors;
    return SafeArea(
      top: false,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(color: semantic.border.withValues(alpha: 0.8)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.2 : 0.055,
              ),
              blurRadius: AppElevations.shadowBlurHigh,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
