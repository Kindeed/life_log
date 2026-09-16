import 'package:flutter/material.dart';

class AppMotion {
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Easing.standard;
  static const Curve standardDecelerate = Easing.standardDecelerate;
  static const Curve emphasized = Easing.emphasizedDecelerate;
  static const Curve emphasizedDecelerate = Easing.emphasizedDecelerate;
}
