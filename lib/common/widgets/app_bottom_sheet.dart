import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Shares timing without changing a sheet's dismissal, layout or focus policy.
/// Flutter owns the animation controller unless one is explicitly supplied.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  bool? requestFocus,
}) {
  final enter = AppMotion.duration(context, AppMotion.sheet);
  final exit = AppMotion.duration(context, AppMotion.normal);
  // A caller-owned controller takes precedence in Flutter. Keep the same
  // timing contract without taking ownership of its disposal.
  transitionAnimationController
    ?..duration = enter
    ..reverseDuration = exit;
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
    sheetAnimationStyle: AnimationStyle(duration: enter, reverseDuration: exit),
  );
}
