import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class AppFilterChipItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppFilterChipItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppFilterChipBar<T> extends StatelessWidget {
  final T value;
  final List<AppFilterChipItem<T>> items;
  final ValueChanged<T> onChanged;

  const AppFilterChipBar({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final selected = item.value == value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(item.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : theme.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? theme.colorScheme.primary : semantic.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.check_rounded
                      : item.icon ?? Icons.tune_rounded,
                  size: 15,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
