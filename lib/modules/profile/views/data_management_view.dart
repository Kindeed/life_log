import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/db/backup_service.dart';
import 'package:get/get.dart';

/// 数据管理页面
class DataManagementView extends StatelessWidget {
  const DataManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('数据管理'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 备份恢复卡片
            _buildBackupCard(
              context,
              isDark,
              cardColor,
              textPrimary,
              textSecondary,
            ),

            SizedBox(height: 20.h),

            // 提示信息
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '备份文件将保存到手机的 "文档" 文件夹中，请定期备份以防数据丢失。',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: textSecondary,
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
    );
  }

  Widget _buildBackupCard(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.backup_outlined,
            iconColor: AppColors.primaryBlue,
            title: '导出备份',
            subtitle: '将所有数据导出为备份文件',
            onTap: () => _handleBackup(context),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildDivider(isDark),
          _buildActionTile(
            icon: Icons.restore_rounded,
            iconColor: AppColors.green,
            title: '恢复数据',
            subtitle: '从备份文件恢复数据',
            onTap: () => _handleRestore(context),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.sp, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        height: 1,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      await BackupService.exportBackup();
    } catch (e) {
      Get.snackbar("导出失败", e.toString());
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final file = await BackupService.pickBackupFile();
      if (file == null) return;

      final confirmed = await Get.defaultDialog<bool>(
        title: "恢复确认",
        middleText: "导入备份将覆盖当前所有数据，此操作不可撤销。是否继续？",
        textConfirm: "确认",
        textCancel: "取消",
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
      );

      if (confirmed == true) {
        await BackupService.restoreFromBackup(file);
        Get.offAllNamed('/');
        Get.snackbar("恢复成功", "数据已恢复，应用已刷新。");
      }
    } catch (e) {
      Get.snackbar("恢复失败", e.toString());
    }
  }
}
