import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
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
  final int? columns;

  const AppFilterChipBar({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.columns,
  }) : assert(columns == null || columns > 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final chips = items.map((item) {
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
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : semantic.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_rounded
                    : item.icon ?? Icons.tune_rounded,
                size: 15,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    final fixedColumns = columns;
    if (fixedColumns != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final totalGap = AppSpacing.sm * (fixedColumns - 1);
          final itemWidth = (constraints.maxWidth - totalGap) / fixedColumns;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final chip in chips) SizedBox(width: itemWidth, child: chip),
            ],
          );
        },
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }
}
