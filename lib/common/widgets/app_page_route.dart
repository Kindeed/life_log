import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Keeps Material's platform transitions, including predictive back and the
/// previous route's delegated transition, while sharing application timings.
Route<T> appPageRoute<T>(
  BuildContext context,
  Widget page, {
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) => AppMaterialPageRoute<T>(
  builder: (_) => page,
  reducedMotion: MediaQuery.disableAnimationsOf(context),
  settings: settings,
  fullscreenDialog: fullscreenDialog,
);

class AppMaterialPageRoute<T> extends MaterialPageRoute<T> {
  final bool reducedMotion;

  AppMaterialPageRoute({
    required super.builder,
    required this.reducedMotion,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
    super.allowSnapshotting,
    super.requestFocus,
  });

  @override
  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : AppMotion.normal;

  @override
  Duration get reverseTransitionDuration =>
      reducedMotion ? Duration.zero : AppMotion.pageExit;
}
