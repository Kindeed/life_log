import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

T responsiveValue<T>(
  BuildContext context, {
  required T compact,
  required T phone,
  T? tablet,
}) {
  switch (AppBreakpoints.of(context)) {
    case AppLayoutClass.compact:
      return compact;
    case AppLayoutClass.phone:
      return phone;
    case AppLayoutClass.tablet:
      return tablet ?? phone;
  }
}
