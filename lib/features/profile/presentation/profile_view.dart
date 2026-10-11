import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/widgets/app_settings.dart';
import 'package:life_log/common/widgets/app_feedback.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';

import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/routing/app_routes.dart';
import 'package:life_log/features/profile/application/sign_out_profile_account.dart';
import 'package:life_log/features/profile/application/sync_profile_data.dart';
import 'package:life_log/features/profile/presentation/profile_account_cubit.dart';

import 'package:life_log/features/sync_center/presentation/sync_center_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileAccountCubit profileAccountCubit;

  @override
  void initState() {
    super.initState();
    profileAccountCubit = serviceLocator<ProfileAccountCubit>()..start();
  }

  @override
  void dispose() {
    profileAccountCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('账户与同步')),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 36.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<ProfileAccountCubit, ProfileAccountState>(
                  bloc: profileAccountCubit,
                  builder: (context, accountState) {
                    return _AccountCard(
                      semantic: semantic,
                      state: accountState,
                      reloadAccount: profileAccountCubit.loadAccount,
                    );
                  },
                ),
                SizedBox(height: 22.h),
                AppSettingsGroup(
                  title: '同步',
                  children: [
                    AppSettingsTile(
                      icon: Icons.sync_problem_rounded,
                      iconColor: semantic.warning,
                      title: '同步状态',
                      subtitle: '冲突、失败任务、附件同步状态',
                      onTap: () =>
                          _openProfilePage(context, const SyncCenterView()),
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
  final ProfileAccountState state;
  final Future<void> Function() reloadAccount;

  const _AccountCard({
    required this.semantic,
    required this.state,
    required this.reloadAccount,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final isLoggedIn = state.isLoggedIn;
    final isCloudConfigured = state.isCloudConfigured;
    final userName = state.userName;

    return AppCard(
      onTap: isLoggedIn || !isCloudConfigured
          ? null
          : () => context.go(AppRoutes.login),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                    onTap: () => _sync(context),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _AccountAction(
                    icon: Icons.logout_rounded,
                    label: '退出登录',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => _logout(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context) async {
    final feedback = AppFeedback.capture(context);
    final result = await serviceLocator<SyncProfileData>().call();
    final failure = result.failureOrNull;
    if (failure != null) {
      feedback.error(failure.message);
      return;
    }

    if (result.valueOrNull == true) {
      feedback.success('数据已与云端同步');
    } else {
      feedback.info('请检查网络或查看日志获取详情');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final feedback = AppFeedback.capture(context);
    final confirmed = await _confirmLogout(context);
    if (confirmed) {
      final result = await serviceLocator<SignOutProfileAccount>().call();
      final failure = result.failureOrNull;
      if (failure != null) {
        feedback.error(failure.message);
        return;
      }

      await reloadAccount();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    }
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
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
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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

Future<void> _openProfilePage(BuildContext context, Widget page) {
  return Navigator.of(context).push(appPageRoute<void>(context, page));
}
