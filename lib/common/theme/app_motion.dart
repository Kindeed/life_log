import 'package:flutter/material.dart';

class AppMotion {
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration sheet = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Easing.standard;
  static const Curve standardDecelerate = Easing.standardDecelerate;
  static const Curve emphasized = Easing.emphasizedDecelerate;
  static const Curve emphasizedDecelerate = Easing.emphasizedDecelerate;
}
