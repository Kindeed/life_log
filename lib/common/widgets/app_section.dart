import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_section_header.dart';

class AppSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final double gap;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.gap = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, trailing: trailing),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}
