import 'package:flutter/widgets.dart';

enum AppLayoutClass { compact, phone, tablet }

class AppBreakpoints {
  static const double compactMax = 359;
  static const double tabletMin = 600;

  static AppLayoutClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= compactMax) return AppLayoutClass.compact;
    if (width >= tabletMin) return AppLayoutClass.tablet;
    return AppLayoutClass.phone;
  }

  static bool isTablet(BuildContext context) =>
      of(context) == AppLayoutClass.tablet;
}
