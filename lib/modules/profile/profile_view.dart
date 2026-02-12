import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';
import 'views/appearance_view.dart';
import 'views/data_management_view.dart';
import 'views/developer_view.dart';
import 'views/about_view.dart';
import 'views/login_view.dart';
import '../../common/theme/app_colors.dart';

/// "我的"页面主视图
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          children: [
            // 1. 用户信息区域（预留）
            _buildUserCard(isDark, cardColor, textPrimary, textSecondary),

            SizedBox(height: 20.h),

            // 2. 设置列表
            _buildSettingsSection(
              context,
              isDark,
              cardColor,
              textPrimary,
              textSecondary,
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  /// 用户信息卡片
  Widget _buildUserCard(
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final controller = ProfileController.to;

    return Obx(() {
      final isLoggedIn = controller.isLoggedIn.value;
      final userName = controller.userName.value;

      return GestureDetector(
        onTap: isLoggedIn ? null : () => Get.to(() => const LoginView()),
        child: Container(
          padding: EdgeInsets.all(20.w),
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
          child: Row(
            children: [
              // 头像
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 32.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              SizedBox(width: 16.w),
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? userName : '点击登录',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isLoggedIn ? '已登录，数据自动同步' : '登录后可同步数据',
                      style: TextStyle(fontSize: 13.sp, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isLoggedIn)
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 24.sp,
                ),
            ],
          ),
        ),
      );
    });
  }

  /// 设置列表区域
  Widget _buildSettingsSection(
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
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            iconColor: AppColors.purple,
            title: '外观设置',
            subtitle: '主题、深色模式',
            onTap: () => Get.to(() => const AppearanceView()),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildDivider(isDark),
          _buildSettingsTile(
            icon: Icons.storage_outlined,
            iconColor: AppColors.primaryBlue,
            title: '数据管理',
            subtitle: '备份与恢复',
            onTap: () => Get.to(() => const DataManagementView()),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildDivider(isDark),
          _buildSettingsTile(
            icon: Icons.bug_report_outlined,
            iconColor: AppColors.orange,
            title: '开发者选项',
            subtitle: '日志、调试',
            onTap: () => Get.to(() => const DeveloperView()),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildDivider(isDark),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.green,
            title: '关于',
            subtitle: '版本信息',
            onTap: () => Get.to(() => const AboutView()),
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            showDivider: false,
          ),
          Obx(() {
            if (ProfileController.to.isLoggedIn.value) {
              return Column(
                children: [
                  _buildDivider(isDark),
                  _buildSettingsTile(
                    icon: Icons.sync_rounded,
                    iconColor: AppColors.primaryBlue,
                    title: '立即同步',
                    subtitle: '手动触发云端数据同步',
                    onTap: () async {
                      final success = await ProfileController.to.syncData();
                      if (success) {
                        Get.snackbar(
                          '同步完成',
                          '数据已与云端同步',
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          colorText: Colors.green,
                        );
                      } else {
                        Get.snackbar(
                          '同步失败',
                          '请检查网络或查看日志获取详情',
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          colorText: Colors.red,
                        );
                      }
                    },
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildDivider(isDark),
                  _buildSettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    title: '退出登录',
                    subtitle: '解除账号绑定',
                    onTap: () {
                      Get.defaultDialog(
                        title: '退出登录',
                        middleText: '确定要退出当前账号吗？',
                        textConfirm: '确定',
                        textCancel: '取消',
                        confirmTextColor: Colors.white,
                        onConfirm: () async {
                          await ProfileController.to.logout();
                          Get.back();
                        },
                      );
                    },
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    showDivider: false,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// 单个设置项
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool showDivider = true,
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
}
