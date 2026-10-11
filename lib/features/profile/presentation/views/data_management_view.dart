import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_log/common/db/backup_service.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/services/log_service.dart';

import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_settings.dart';
import 'package:life_log/common/widgets/app_feedback.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/routing/app_routes.dart';

class DataManagementView extends StatelessWidget {
  const DataManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('数据备份与恢复')),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSettingsGroup(
                  children: [
                    AppSettingsTile(
                      icon: Icons.backup_outlined,
                      iconColor: semantic.work,
                      title: '导出备份',
                      subtitle: '仅导出数据库，不含照片/凭证文件',
                      onTap: () => _handleBackup(context),
                    ),

                    AppSettingsTile(
                      icon: Icons.restore_rounded,
                      iconColor: semantic.warning,
                      title: '恢复数据',
                      subtitle: '从备份文件覆盖当前本地数据',
                      onTap: () => _handleRestore(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: semantic.warning,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '恢复备份会覆盖当前本地数据库。请先确认备份文件来源可靠，必要时先导出当前数据。',
                          style: TextStyle(
                            fontSize: 13,
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
    final feedback = AppFeedback.capture(context);
    try {
      await BackupService.exportBackup();
    } catch (e, stackTrace) {
      _logFailure('导出备份失败: $e', stackTrace);
      feedback.error('导出失败: $e');
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final feedback = AppFeedback.capture(context);
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
      feedback.success('恢复成功，数据已恢复，应用已刷新。');
    } catch (e, stackTrace) {
      _logFailure('恢复备份失败: $e', stackTrace);
      if (!context.mounted) return;
      feedback.error('恢复失败: $e');
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
