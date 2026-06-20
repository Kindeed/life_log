import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:life_log/core/routing/app_routes.dart';

typedef CoreRouteBuilder =
    Widget Function(BuildContext context, GoRouterState state);

GoRouter buildCoreRouter({
  required CoreRouteBuilder rootBuilder,
  required CoreRouteBuilder loginBuilder,
  String initialLocation = AppRoutes.root,
  GlobalKey<NavigatorState>? navigatorKey,
  List<RouteBase> extraRoutes = const [],
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        name: AppRouteNames.root,
        builder: rootBuilder,
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: loginBuilder,
      ),
      ...extraRoutes,
    ],
  );
}
