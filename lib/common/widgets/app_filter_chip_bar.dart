import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final selected = item.value == value;
        return FilterChip(
          label: Text(item.label),
          avatar: Icon(
            selected ? Icons.check_rounded : item.icon ?? Icons.tune_rounded,
            size: 16,
          ),
          showCheckmark: false,
          selected: selected,
          onSelected: (_) {
            HapticFeedback.lightImpact();
            onChanged(item.value);
          },
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
