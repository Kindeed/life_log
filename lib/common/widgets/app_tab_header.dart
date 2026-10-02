import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_press_feedback.dart';

/// Shared title, baseline and action geometry for all three primary tabs.
class AppTabHeader extends StatelessWidget {
  final String title;
  final String eyebrow;
  final Widget action;

  const AppTabHeader({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackAction =
              constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          if (stackAction) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: AppSpacing.md),
                action,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heading),
              const SizedBox(width: AppSpacing.md),
              action,
            ],
          );
        },
      ),
    );
  }
}

class AppTabAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AppTabAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => AppPressFeedback(
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    ),
  );
}

class AppTabIconAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AppTabIconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => AppPressFeedback(
    child: IconButton.filledTonal(
      tooltip: label,
      icon: Icon(icon),
      onPressed: onPressed,
      style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
    ),
  );
}
