import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/widgets/app_button.dart';

Future<bool> confirmWorkLogDelete(
  BuildContext context, {
  String title = '删除记录',
  String message = '确定清空这一天的记录吗？删除后无法恢复。',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton.text(
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(false),
            height: 42,
          ),
          AppButton(
            label: '删除',
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(dialogContext).pop(true);
            },
            variant: AppButtonVariant.destructive,
            height: 42,
          ),
        ],
      );
    },
  );
  return result ?? false;
}
