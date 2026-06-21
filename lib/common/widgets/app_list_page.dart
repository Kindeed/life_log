import 'package:flutter/material.dart';

import '../layout/constrained_page.dart';
import '../theme/app_spacing.dart';

typedef AppSliverBuilder = Widget Function(BuildContext context);

class AppListPage extends StatelessWidget {
  final String title;
  final Widget? overview;
  final AppSliverBuilder sliverBuilder;
  final bool isLoading;
  final bool isEmpty;
  final Widget? loading;
  final Widget? empty;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry overviewPadding;
  final Color? backgroundColor;

  const AppListPage({
    super.key,
    required this.title,
    required this.sliverBuilder,
    this.overview,
    this.isLoading = false,
    this.isEmpty = false,
    this.loading,
    this.empty,
    this.onRefresh,
    this.floatingActionButton,
    this.overviewPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(child: _body(context));

    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading && loading != null) {
      return loading!;
    }

    if (isEmpty && empty != null) {
      return empty!;
    }

    final scrollView = CustomScrollView(
      slivers: [
        if (overview != null)
          SliverToBoxAdapter(
            child: ConstrainedPage(padding: overviewPadding, child: overview!),
          ),
        sliverBuilder(context),
      ],
    );

    if (onRefresh == null) return scrollView;
    return RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
  }
}
