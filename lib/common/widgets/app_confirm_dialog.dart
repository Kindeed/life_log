import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              if (destructive) HapticFeedback.heavyImpact();
              Get.back(result: true);
            },
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Get.theme.colorScheme.errorContainer,
                    foregroundColor: Get.theme.colorScheme.onErrorContainer,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
