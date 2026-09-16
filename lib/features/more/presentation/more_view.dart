import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/profile/presentation/profile_account_cubit.dart';
import 'package:life_log/features/profile/presentation/profile_view.dart';
import 'package:life_log/features/profile/presentation/views/about_view.dart';
import 'package:life_log/features/profile/presentation/views/appearance_view.dart';
import 'package:life_log/features/profile/presentation/views/data_management_view.dart';
import 'package:life_log/features/statistics/presentation/statistics_view.dart';
import 'package:life_log/features/subscription/presentation/subscription_view.dart';
import 'package:life_log/features/telemetry_calc/presentation/telemetry_calc_view.dart';
import 'package:life_log/features/timeline/presentation/timeline_view.dart';

class MoreView extends StatefulWidget {
  const MoreView({super.key});

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  ProfileAccountCubit? _profileAccountCubit;

  @override
  void initState() {
    super.initState();
    if (serviceLocator.isRegistered<ProfileAccountCubit>()) {
      _profileAccountCubit = serviceLocator<ProfileAccountCubit>()..start();
    }
  }

  @override
  void dispose() {
    _profileAccountCubit?.close();
    super.dispose();
  }

  void _openPage(Widget page) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 个人与账户
                const AppSectionHeader(title: '个人与账户'),
                SizedBox(height: 6.h),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (_profileAccountCubit != null)
                        BlocBuilder<ProfileAccountCubit, ProfileAccountState>(
                          bloc: _profileAccountCubit,
                          builder: (context, state) {
                            return _buildAccountTile(
                              context,
                              userName:
                                  state.isLoggedIn || !state.isCloudConfigured
                                  ? state.userName
                                  : '点击登录',
                              subtitle: !state.isCloudConfigured
                                  ? '云同步未配置 · 本地数据模式'
                                  : state.isLoggedIn
                                  ? '已登录 · 查看同步状态'
                                  : '登录后可开启多端云同步',
                              onTap: () => _openPage(const ProfileView()),
                            );
                          },
                        )
                      else
                        _buildAccountTile(
                          context,
                          userName: '个人信息',
                          subtitle: '查看个人账户与同步偏好',
                          onTap: () => _openPage(const ProfileView()),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // 二级功能只在“更多”目录出现一次，账户与同步由 ProfileView 负责。
                _MoreGroup(
                  title: '记录与分析',
                  destinations: [
                    _MoreDestination(
                      icon: Icons.receipt_long_outlined,
                      iconColor: semantic.warning,
                      title: '全部记录',
                      subtitle: '工时、支出、凭证与订阅时间线',
                      page: const TimelineView(),
                    ),
                    _MoreDestination(
                      icon: Icons.analytics_outlined,
                      iconColor: semantic.stats,
                      title: '统计面板',
                      subtitle: '工时结构、月度支出与项目投入透视',
                      page: const StatisticsView(),
                    ),
                    _MoreDestination(
                      icon: Icons.subscriptions_outlined,
                      iconColor: semantic.expense,
                      title: '订阅管理',
                      subtitle: '固定支出、周期扣费与续费提醒',
                      page: const SubscriptionView(),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _MoreGroup(
                  title: '工具',
                  destinations: [
                    _MoreDestination(
                      icon: Icons.settings_input_antenna_rounded,
                      iconColor: semantic.work,
                      title: '遥测计算器',
                      subtitle: '链路预算、码率与 PCM 专业参数计算',
                      page: const TelemetryCalcView(),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _MoreGroup(
                  title: '应用',
                  destinations: [
                    _MoreDestination(
                      icon: Icons.palette_outlined,
                      iconColor: semantic.expense,
                      title: '外观设置',
                      subtitle: '主题风格、深色模式与动态取色',
                      page: const AppearanceView(),
                    ),
                    _MoreDestination(
                      icon: Icons.storage_outlined,
                      iconColor: semantic.work,
                      title: '数据备份与恢复',
                      subtitle: '本地数据库备份、恢复与数据安全',
                      page: const DataManagementView(),
                    ),
                    _MoreDestination(
                      icon: Icons.info_outline_rounded,
                      iconColor: semantic.success,
                      title: '关于应用',
                      subtitle: '版本信息、技术架构与开源说明',
                      page: const AboutView(),
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

  Widget _buildAccountTile(
    BuildContext context, {
    required String userName,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: semantic.work.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 24.sp,
                color: semantic.work,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItemTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreItemTile({
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
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreDestination {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget page;

  const _MoreDestination({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.page,
  });
}

class _MoreGroup extends StatelessWidget {
  final String title;
  final List<_MoreDestination> destinations;

  const _MoreGroup({required this.title, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = theme.semanticColors.border.withValues(
      alpha: isDark ? 0.35 : 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        SizedBox(height: 6.h),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < destinations.length; index++) ...[
                _buildDestinationTile(context, destinations[index]),
                if (index < destinations.length - 1)
                  Divider(
                    height: 1,
                    indent: 58.w,
                    endIndent: 14.w,
                    color: dividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationTile(
    BuildContext context,
    _MoreDestination destination,
  ) {
    return _MoreItemTile(
      icon: destination.icon,
      iconColor: destination.iconColor,
      title: destination.title,
      subtitle: destination.subtitle,
      onTap: () => Navigator.of(
        context,
      ).push<void>(MaterialPageRoute<void>(builder: (_) => destination.page)),
    );
  }
}
