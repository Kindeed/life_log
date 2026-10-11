import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_tab_header.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/widgets/app_settings.dart';
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
    Navigator.of(context).push<void>(appPageRoute<void>(context, page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ConstrainedPage(
              child: AppTabHeader(title: '更多', eyebrow: '记录、工具与应用设置'),
            ),
            Expanded(
              child: ConstrainedPage(
                child: SingleChildScrollView(
                  key: const PageStorageKey('more-scroll'),
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 个人与账户
                      AppCard(
                        radius: AppRadius.group,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            if (_profileAccountCubit != null)
                              BlocBuilder<
                                ProfileAccountCubit,
                                ProfileAccountState
                              >(
                                bloc: _profileAccountCubit,
                                builder: (context, state) {
                                  return _buildAccountTile(
                                    context,
                                    userName:
                                        state.isLoggedIn ||
                                            !state.isCloudConfigured
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
                                userName: '账户与同步',
                                subtitle: '查看账户信息与同步状态',
                                onTap: () => _openPage(const ProfileView()),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 二级功能只在“更多”目录出现一次，账户与同步由 ProfileView 负责。
                      _MoreGroup(
                        title: '记录与分析',
                        destinations: [
                          _MoreDestination(
                            icon: Icons.receipt_long_outlined,
                            iconColor: semantic.warning,
                            title: '全部记录',
                            subtitle: '历史工时、支出、凭证与下次扣费',
                            page: const TimelineView(),
                          ),
                          _MoreDestination(
                            icon: Icons.subscriptions_outlined,
                            iconColor: semantic.expense,
                            title: '订阅管理',
                            subtitle: '周期费用、下次扣费与提醒',
                            page: const SubscriptionView(),
                          ),
                          _MoreDestination(
                            icon: Icons.analytics_outlined,
                            iconColor: semantic.stats,
                            title: '统计面板',
                            subtitle: '工时、订阅估算与各币种支出',
                            page: const StatisticsView(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _MoreGroup(
                        title: '应用设置',
                        destinations: [
                          _MoreDestination(
                            icon: Icons.palette_outlined,
                            iconColor: semantic.expense,
                            title: '外观设置',
                            subtitle: '主题模式、动态取色与照片信息',
                            page: const AppearanceView(),
                          ),
                          _MoreDestination(
                            icon: Icons.storage_outlined,
                            iconColor: semantic.work,
                            title: '数据备份与恢复',
                            subtitle: '仅备份数据库，不含照片和凭证文件',
                            page: const DataManagementView(),
                          ),
                          _MoreDestination(
                            icon: Icons.info_outline_rounded,
                            iconColor: semantic.success,
                            title: '关于与诊断',
                            subtitle: '应用版本、日志与诊断信息',
                            page: const AboutView(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _MoreGroup(
                        title: '专业工具',
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required String userName,
    required String subtitle,
    required VoidCallback onTap,
  }) => AppSettingsTile(
    icon: Icons.person_rounded,
    title: userName,
    subtitle: subtitle,
    onTap: onTap,
  );
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
  Widget build(BuildContext context) => AppSettingsGroup(
    title: title,
    children: [
      for (final destination in destinations)
        AppSettingsTile(
          icon: destination.icon,
          iconColor: destination.iconColor,
          title: destination.title,
          subtitle: destination.subtitle,
          onTap: () => Navigator.of(
            context,
          ).push<void>(appPageRoute<void>(context, destination.page)),
        ),
    ],
  );
}
