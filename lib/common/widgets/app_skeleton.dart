import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
