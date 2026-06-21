import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_page.dart';

class AppDetailPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppDetailPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(title: Text(title), actions: actions),
      scrollable: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }
}
