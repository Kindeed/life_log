import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class AppSheetScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? bottomBar;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool showGrabber;
  final bool scrollable;

  const AppSheetScaffold({
    super.key,
    this.title,
    required this.child,
    this.bottomBar,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    this.showGrabber = true,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final content = Padding(padding: padding, child: child);

    return Container(
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (showGrabber) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: semantic.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          if (title != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (height == null)
            scrollable
                ? Flexible(child: SingleChildScrollView(child: content))
                : content
          else
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(child: content)
                  : content,
            ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}
