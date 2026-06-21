import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:life_log/common/db/backup_service.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/routing/app_routes.dart';

class DataManagementView extends StatelessWidget {
  const DataManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(title: '备份与恢复'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _DataActionTile(
                        icon: Icons.backup_outlined,
                        iconColor: semantic.work,
                        title: '导出备份',
                        subtitle: '仅导出数据库，不含照片/凭证文件',
                        onTap: () => _handleBackup(context),
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      _DataActionTile(
                        icon: Icons.restore_rounded,
                        iconColor: semantic.warning,
                        title: '恢复数据',
                        subtitle: '从备份文件覆盖当前本地数据',
                        onTap: () => _handleRestore(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: semantic.warning,
                        size: 22.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '恢复备份会覆盖当前本地数据库。请先确认备份文件来源可靠，必要时先导出当前数据。',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.exportBackup();
    } catch (e, stackTrace) {
      _logFailure('导出备份失败: $e', stackTrace);
      messenger.showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await BackupService.pickBackupFile();
      if (file == null) return;
      if (!context.mounted) return;

      final confirmed = await _confirmRestore(context);
      if (!confirmed) return;
      if (!context.mounted) return;

      _showRestoreProgress(context);
      try {
        await BackupService.restoreFromBackup(file);
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (!context.mounted) return;
      context.go(AppRoutes.root);
      messenger.showSnackBar(
        const SnackBar(content: Text('恢复成功，数据已恢复，应用已刷新。')),
      );
    } catch (e, stackTrace) {
      _logFailure('恢复备份失败: $e', stackTrace);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('恢复失败: $e')));
    }
  }

  void _logFailure(String message, StackTrace stackTrace) {
    if (serviceLocator.isRegistered<LogService>()) {
      LogService.to.error('DataManagement', message, stackTrace);
    }
  }

  Future<bool> _confirmRestore(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('恢复确认'),
          content: const Text(
            '导入备份将覆盖当前本地数据库。备份文件不包含照片和凭证文件本体，恢复后缺失的本地文件无法自动还原。建议先导出当前数据，再继续恢复。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('恢复'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showRestoreProgress(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2.5),
                    SizedBox(height: 16),
                    Text('正在恢复数据，请勿操作'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DataActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DataActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary),
          ],
        ),
      ),
    );
  }
}
