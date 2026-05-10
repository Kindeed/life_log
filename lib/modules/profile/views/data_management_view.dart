import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../common/db/backup_service.dart';
import '../../../common/layout/constrained_page.dart';
import '../../../common/theme/app_spacing.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../common/widgets/app_section_header.dart';

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
                        onTap: _handleBackup,
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
                        onTap: _handleRestore,
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

  Future<void> _handleBackup() async {
    try {
      await BackupService.exportBackup();
    } catch (e) {
      Get.snackbar("导出失败", e.toString());
    }
  }

  Future<void> _handleRestore() async {
    try {
      final file = await BackupService.pickBackupFile();
      if (file == null) return;

      final confirmed = await AppConfirmDialog.show(
        title: "恢复确认",
        message:
            "导入备份将覆盖当前本地数据库。备份文件不包含照片和凭证文件本体，恢复后缺失的本地文件无法自动还原。建议先导出当前数据，再继续恢复。",
        confirmLabel: "恢复",
        destructive: true,
      );

      if (confirmed) {
        await BackupService.restoreFromBackup(file);
        Get.offAllNamed('/');
        Get.snackbar("恢复成功", "数据已恢复，应用已刷新。");
      }
    } catch (e) {
      Get.snackbar("恢复失败", e.toString());
    }
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
