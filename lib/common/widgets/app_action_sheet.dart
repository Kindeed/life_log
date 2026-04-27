import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppActionSheetItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const AppActionSheetItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
}

class AppActionSheet {
  static Future<void> show({
    String? title,
    required List<AppActionSheetItem> actions,
  }) {
    return Get.bottomSheet<void>(
      SafeArea(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  ...actions.map(
                    (action) => ListTile(
                      leading: Icon(
                        action.icon,
                        color: action.destructive
                            ? theme.colorScheme.error
                            : null,
                      ),
                      title: Text(action.title),
                      subtitle: action.subtitle == null
                          ? null
                          : Text(action.subtitle!),
                      onTap: () {
                        Get.back();
                        action.onTap();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}
