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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
