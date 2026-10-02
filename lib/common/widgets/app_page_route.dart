import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

Route<T> appPageRoute<T>(BuildContext context, Widget page) =>
    PageRouteBuilder<T>(
      transitionDuration: AppMotion.duration(context, AppMotion.normal),
      reverseTransitionDuration: AppMotion.duration(context, AppMotion.normal),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final eased = animation.drive(CurveTween(curve: AppMotion.standard));
        return FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: eased.drive(
              Tween(begin: const Offset(0.06, 0), end: Offset.zero),
            ),
            child: child,
          ),
        );
      },
    );
