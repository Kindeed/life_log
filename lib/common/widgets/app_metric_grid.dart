import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppMetricGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double gap;

  const AppMetricGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.gap = AppSpacing.sm,
  }) : assert(columns > 0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = <Widget>[];
        for (var index = 0; index < children.length; index += columns) {
          final rowChildren = children.skip(index).take(columns).toList();
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var itemIndex = 0; itemIndex < columns; itemIndex++) ...[
                  if (itemIndex > 0) SizedBox(width: gap),
                  Expanded(
                    child: itemIndex < rowChildren.length
                        ? rowChildren[itemIndex]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) SizedBox(height: gap),
              rows[index],
            ],
          ],
        );
      },
    );
  }
}
