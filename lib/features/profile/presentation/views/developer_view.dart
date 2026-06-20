import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/services/cloud_config_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/theme/custom_colors.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:share_plus/share_plus.dart';

/// 开发者选项页面
class DeveloperView extends StatelessWidget {
  const DeveloperView({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = serviceLocator<LogService>();
    final cloudConfig = serviceLocator<CloudConfigService>();
    final theme = Theme.of(context);
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
            onPressed: () => _confirmClearLogs(context, logService),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '导出日志',
            onPressed: () => _exportLogs(logService),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([logService, cloudConfig]),
        builder: (context, _) {
          final logs = logService.logs;
          return Column(
            children: [
              _buildSettingsSection(
                context,
                logService,
                cloudConfig,
                textPrimary,
                textSecondary,
                theme,
              ),
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
                    Text(
                      '共 ${logs.length} 条',
                      style: TextStyle(fontSize: 12.sp, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? Center(
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
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[logs.length - 1 - index];
                          return _buildLogItem(
                            log,
                            theme,
                            textPrimary,
                            textSecondary,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    LogService logService,
    CloudConfigService cloudConfig,
    Color textPrimary,
    Color textSecondary,
    ThemeData theme,
  ) {
    final isDebugEnabled = logService.enableDebug;
    final settingsCard = AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              '调试日志',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              isDebugEnabled ? '已开启：记录详细调试信息' : '已关闭：仅记录重要信息',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDebugEnabled ? AppColors.green : textSecondary,
                fontWeight: isDebugEnabled
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            value: isDebugEnabled,
            onChanged: logService.setDebugEnabled,
            activeThumbColor: Colors.white,
            activeTrackColor:
                theme.extension<LogColors>()?.success ?? AppColors.green,
            inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
          _buildDivider(theme),
          ListTile(
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
              cloudConfig.isConfigured ? '已配置' : '未配置，本地模式',
              style: TextStyle(fontSize: 12.sp, color: textSecondary),
            ),
          ),
          _buildDivider(theme),
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
            onTap: () => _copyLogs(context, logService),
          ),
          _buildDivider(theme),
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
            onTap: () => _copyDiagnostics(context, logService),
          ),
        ],
      ),
    );
    return Padding(padding: EdgeInsets.all(16.w), child: settingsCard);
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16.w,
      endIndent: 16.w,
      color: theme.dividerColor,
    );
  }

  Widget _buildLogItem(
    LogEntry log,
    ThemeData theme,
    Color textPrimary,
    Color textSecondary,
  ) {
    final colorScheme = theme.colorScheme;
    final levelColor = switch (log.level) {
      LogLevel.debug => colorScheme.onSurfaceVariant,
      LogLevel.info => colorScheme.primary,
      LogLevel.warning => AppColors.orange,
      LogLevel.error => colorScheme.error,
    };

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

  Future<void> _confirmClearLogs(
    BuildContext context,
    LogService logService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清空日志'),
          content: const Text('确定要清空所有日志吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    logService.clearLogs();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('所有日志已清空')));
  }

  Future<void> _copyLogs(BuildContext context, LogService logService) async {
    final text = logService.exportLogs();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('日志已复制到剪贴板')));
  }

  Future<void> _copyDiagnostics(
    BuildContext context,
    LogService logService,
  ) async {
    final text = logService.exportDiagnostics();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('诊断信息已复制')));
  }

  Future<void> _exportLogs(LogService logService) async {
    final text = logService.exportLogs();
    await Share.share(text, subject: 'LifeLog 应用日志');
  }
}
