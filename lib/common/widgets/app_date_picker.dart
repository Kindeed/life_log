import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';

Future<DateTime?> showLifeLogDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: const Locale('zh', 'CN'),
    helpText: '选择日期',
    cancelText: '取消',
    confirmText: '确定',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (dialogContext, child) {
      final theme = Theme.of(dialogContext);
      final colorScheme = theme.colorScheme;
      final semantic = theme.semanticColors;
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      );

      return DatePickerTheme(
        data: DatePickerThemeData(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: colorScheme.primary,
          headerForegroundColor: colorScheme.onPrimary,
          dividerColor: semantic.border,
          shape: shape,
          todayBorder: BorderSide(color: colorScheme.primary, width: 1.4),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Theme(
          data: theme.copyWith(
            dialogTheme: theme.dialogTheme.copyWith(shape: shape),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );

  return picked == null ? null : dateOnlyLocal(picked);
}
