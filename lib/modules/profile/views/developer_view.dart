import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/theme/custom_colors.dart';
import '../../../common/services/cloud_config_service.dart';
import '../../../common/services/log_service.dart';
import '../../../common/widgets/app_card.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import 'design_gallery_view.dart';

/// 开发者选项页面
class DeveloperView extends StatelessWidget {
  const DeveloperView({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = Get.find<LogService>();
    final cloudConfig = Get.find<CloudConfigService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('开发者选项'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空日志',
            onPressed: () => _confirmClearLogs(logService),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '导出日志',
            onPressed: () => _exportLogs(logService),
          ),
        ],
      ),
      body: Column(
        children: [
          // 设置区域
          _buildSettingsSection(
            logService,
            cloudConfig,
            isDark,
            textPrimary,
            textSecondary,
            theme,
          ),

          // 日志列表标题
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '应用日志',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Obx(
                  () => Text(
                    '共 ${logService.logs.length} 条',
                    style: TextStyle(fontSize: 12.sp, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // 日志列表
          Expanded(
            child: Obx(() {
              if (logService.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48.sp,
                        color: textSecondary,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '暂无日志',
                        style: TextStyle(fontSize: 14.sp, color: textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: logService.logs.length,
                itemBuilder: (context, index) {
                  // 显示最新的日志在顶部
                  final log =
                      logService.logs[logService.logs.length - 1 - index];
                  return _buildLogItem(log, theme, textPrimary, textSecondary);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    LogService logService,
    CloudConfigService cloudConfig,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    ThemeData theme,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Debug 日志开关
          Obx(() {
            final isEnabled = logService.enableDebug.value;
            return SwitchListTile(
              title: Text(
                'Debug 日志',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                isEnabled ? '已开启：记录详细调试信息' : '已关闭：仅记录重要信息',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isEnabled ? AppColors.green : textSecondary,
                  fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              value: isEnabled,
              onChanged: (value) => logService.enableDebug.value = value,
              activeThumbColor: Colors.white,
              activeTrackColor:
                  theme.extension<LogColors>()?.success ?? AppColors.green,
              inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            );
          }),
          Divider(
            height: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: theme.dividerColor,
          ),
          Obx(
            () => ListTile(
              leading: Icon(Icons.cloud_outlined, color: textSecondary),
              title: Text(
                '云同步状态',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                cloudConfig.isConfigured.value ? '已配置' : '未配置，本地模式',
                style: TextStyle(fontSize: 12.sp, color: textSecondary),
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: theme.dividerColor,
          ),
          // 复制日志
          ListTile(
            leading: Icon(Icons.copy_outlined, color: textSecondary),
            title: Text(
              '复制全部日志',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
            onTap: () => _copyLogs(logService),
          ),
          Divider(
            height: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: theme.dividerColor,
          ),
          ListTile(
            leading: Icon(
              Icons.health_and_safety_outlined,
              color: textSecondary,
            ),
            title: Text(
              '复制诊断信息',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
            onTap: () => _copyDiagnostics(logService),
          ),
          Divider(
            height: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: theme.dividerColor,
          ),
          ListTile(
            leading: Icon(Icons.palette_outlined, color: textSecondary),
            title: Text(
              'UI Gallery',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              '查看设计 Token 和公共组件',
              style: TextStyle(fontSize: 12.sp, color: textSecondary),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
            onTap: () => Get.to(() => const DesignGalleryView()),
          ),
        ],
      ),
    ).paddingAll(16.w);
  }

  Widget _buildLogItem(
    LogEntry log,
    ThemeData theme,
    Color textPrimary,
    Color textSecondary,
  ) {
    final colorScheme = theme.colorScheme;
    Color levelColor;
    switch (log.level) {
      case LogLevel.debug:
        levelColor = colorScheme.onSurfaceVariant;
      case LogLevel.info:
        levelColor = colorScheme.primary;
      case LogLevel.warning:
        levelColor = AppColors.orange;
      case LogLevel.error:
        levelColor = colorScheme.error;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3.w, color: levelColor),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(log.levelIcon, style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        log.tag,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: levelColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10.sp, color: textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  log.message,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
                if (log.stackTrace != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: SelectableText(
                      log.stackTrace!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearLogs(LogService logService) {
    AppConfirmDialog.show(
      title: '清空日志',
      message: '确定要清空所有日志吗？',
      destructive: true,
    ).then((confirmed) {
      if (!confirmed) return;
      logService.clearLogs();
      Get.snackbar('已清空', '所有日志已清空', snackPosition: SnackPosition.BOTTOM);
    });
  }

  void _copyLogs(LogService logService) {
    final text = logService.exportLogs();
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('已复制', '日志已复制到剪贴板', snackPosition: SnackPosition.BOTTOM);
  }

  void _copyDiagnostics(LogService logService) {
    final text = logService.exportDiagnostics();
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('已复制', '诊断信息已复制', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _exportLogs(LogService logService) async {
    final text = logService.exportLogs();
    await Share.share(text, subject: 'LifeLog 应用日志');
  }
}
