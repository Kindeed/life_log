import 'package:flutter/material.dart';

import '../layout/constrained_page.dart';
import '../theme/app_spacing.dart';

class AppPage extends StatelessWidget {
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool safeArea;
  final bool scrollable;
  final bool constrained;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const AppPage({
    super.key,
    this.title,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.safeArea = true,
    this.scrollable = false,
    this.constrained = true,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (constrained) {
      content = ConstrainedPage(
        maxWidth: maxWidth,
        padding: padding,
        scrollable: scrollable,
        child: content,
      );
    } else if (padding != EdgeInsets.zero) {
      content = Padding(padding: padding, child: content);
    }

    if (safeArea) content = SafeArea(child: content);

    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar ?? (title == null ? null : AppBar(title: Text(title!))),
      body: content,
      floatingActionButton: floatingActionButton,
    );
  }
}
