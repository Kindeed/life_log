import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_radius.dart';
import 'app_button.dart';

class AppConfirmDialog {
  static Future<bool> show({
    required String title,
    required String message,
    String cancelLabel = '取消',
    String confirmLabel = '确定',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton.text(
            label: cancelLabel,
            onPressed: () => Get.back(result: false),
            height: 42,
          ),
          AppButton(
            label: confirmLabel,
            onPressed: () {
              if (destructive) HapticFeedback.heavyImpact();
              Get.back(result: true);
            },
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            height: 42,
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
