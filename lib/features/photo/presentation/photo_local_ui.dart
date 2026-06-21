import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_button.dart';

class PhotoActionSheetItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const PhotoActionSheetItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
}

Future<void> showPhotoActionSheet(
  BuildContext context, {
  String? title,
  required List<PhotoActionSheetItem> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final semantic = theme.semanticColors;
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
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
                    color: semantic.border.withValues(alpha: 0.9),
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
                  minTileHeight: 56,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  leading: Icon(
                    action.icon,
                    color: action.destructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  title: Text(
                    action.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: action.subtitle == null
                      ? null
                      : Text(action.subtitle!),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    action.onTap();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> confirmPhotoAction(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool destructive = false,
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
            label: cancelLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            height: 42,
          ),
          AppButton(
            label: confirmLabel,
            onPressed: () {
              if (destructive) HapticFeedback.heavyImpact();
              Navigator.of(dialogContext).pop(true);
            },
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            height: 42,
          ),
        ],
      );
    },
  );
  return result ?? false;
}
