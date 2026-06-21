import 'package:flutter/material.dart';

import 'app_page.dart';
import 'app_safe_bottom_bar.dart';

class AppFormPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottomBar;
  final bool scrollable;

  const AppFormPage({
    super.key,
    required this.title,
    required this.child,
    this.bottomBar,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      padding: EdgeInsets.zero,
      scrollable: false,
      body: Column(
        children: [
          Expanded(
            child: AppPageBody(scrollable: scrollable, child: child),
          ),
          if (bottomBar != null) AppSafeBottomBar(child: bottomBar!),
        ],
      ),
    );
  }
}

class AppPageBody extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const AppPageBody({super.key, required this.child, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    if (!scrollable) return child;
    return SingleChildScrollView(child: child);
  }
}
