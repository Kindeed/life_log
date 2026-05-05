import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'custom_colors.dart';

extension LifeLogThemeExtensions on ThemeData {
  AppSemanticColors get semanticColors =>
      extension<AppSemanticColors>() ??
      (brightness == Brightness.dark
          ? AppSemanticColors.dark
          : AppSemanticColors.light);

  LogColors get logColors =>
      extension<LogColors>() ??
      (brightness == Brightness.dark ? LogColors.dark : LogColors.light);
}
