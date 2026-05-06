import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/layout/constrained_page.dart';
import '../../common/theme/app_spacing.dart';
import '../../common/utils/formatters.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_confirm_dialog.dart';
import '../../common/widgets/app_metric_tile.dart';
import '../../common/widgets/app_section_header.dart';
import '../statistics/statistics_controller.dart';
import '../statistics/statistics_view.dart';
import 'profile_controller.dart';
import 'views/about_view.dart';
import 'views/appearance_view.dart';
import 'views/data_management_view.dart';
import 'views/developer_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<ProfileController>();
    final semantic = Theme.of(context).semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 36.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountCard(semantic: semantic),
                SizedBox(height: 22.h),
                _StatsSummaryCard(semantic: semantic),
                SizedBox(height: 22.h),
                _SettingsGroup(
                  title: '数据',
                  children: [
                    _SettingsTile(
                      icon: Icons.storage_outlined,
                      iconColor: semantic.work,
                      title: '数据管理',
                      subtitle: '备份、恢复、本地数据安全',
                      onTap: () => Get.to(() => const DataManagementView()),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _SettingsGroup(
                  title: '偏好',
                  children: [
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      iconColor: semantic.expense,
                      title: '外观设置',
                      subtitle: '主题、深色模式',
                      onTap: () => Get.to(() => const AppearanceView()),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _SettingsGroup(
                  title: '关于',
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: semantic.success,
                      title: '关于',
                      subtitle: '版本信息',
                      onTap: () => Get.to(() => const AboutView()),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _SettingsGroup(
                  title: '开发者',
                  muted: true,
                  children: [
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: semantic.warning,
                      title: '开发者选项',
                      subtitle: '日志、调试、UI Gallery',
                      onTap: () => Get.to(() => const DeveloperView()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AppSemanticColors semantic;

  const _AccountCard({required this.semantic});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Obx(() {
      final isLoggedIn = controller.isLoggedIn.value;
      final isCloudConfigured = controller.isCloudConfigured.value;
      final userName = controller.userName.value;

      return AppCard(
        onTap: isLoggedIn || !isCloudConfigured
            ? null
            : () => Get.toNamed('/login'),
        padding: EdgeInsets.all(18.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    color: semantic.work.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 30.sp,
                    color: semantic.work,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn || !isCloudConfigured ? userName : '点击登录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        !isCloudConfigured
                            ? '云同步未配置，本地数据可正常使用'
                            : isLoggedIn
                            ? '已登录，数据可同步到云端'
                            : '登录后可同步数据',
                        style: TextStyle(fontSize: 13.sp, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!isLoggedIn && isCloudConfigured)
                  Icon(Icons.chevron_right_rounded, color: textSecondary),
              ],
            ),
            if (isLoggedIn) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _AccountAction(
                      icon: Icons.sync_rounded,
                      label: '立即同步',
                      color: semantic.work,
                      onTap: () => _sync(controller),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _AccountAction(
                      icon: Icons.logout_rounded,
                      label: '退出登录',
                      color: Theme.of(context).colorScheme.error,
                      onTap: () => _logout(controller),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _sync(ProfileController controller) async {
    final success = await controller.syncData();
    if (success) {
      Get.snackbar('同步完成', '数据已与云端同步');
    } else {
      Get.snackbar('同步失败', '请检查网络或查看日志获取详情');
    }
  }

  Future<void> _logout(ProfileController controller) async {
    final confirmed = await AppConfirmDialog.show(
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      confirmLabel: '退出',
      destructive: true,
    );
    if (confirmed) {
      await controller.logout();
    }
  }
}

class _AccountAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccountAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  final AppSemanticColors semantic;

  const _StatsSummaryCard({required this.semantic});

  @override
  Widget build(BuildContext context) {
    final stats = Get.find<StatisticsController>();
    return AppCard(
      onTap: () => Get.to(() => const StatisticsView()),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '数据总览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: AppMetricTile(
                    label: '本月工时',
                    value: stats.workHours.value.toStringAsFixed(1),
                    icon: Icons.timelapse_rounded,
                    color: semantic.work,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppMetricTile(
                    label: '本月支出',
                    value: formatMoney(
                      stats.selectedMonthSubCost.value +
                          stats.selectedMonthExpenseRecordCost.value,
                    ),
                    icon: Icons.payments_rounded,
                    color: semantic.expense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool muted;

  const _SettingsGroup({
    required this.title,
    required this.children,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.88 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
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
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
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
                      fontWeight: FontWeight.w600,
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
