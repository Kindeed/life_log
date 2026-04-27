import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
