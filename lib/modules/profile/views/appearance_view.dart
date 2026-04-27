import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/theme/theme_controller.dart';

/// 外观设置页面
class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('外观设置'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主题模式选择
            _buildSectionTitle('主题模式', textPrimary),
            SizedBox(height: 12.h),
            _buildThemeSelector(
              themeController,
              isDark,
              cardColor,
              textPrimary,
              textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    ThemeController controller,
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
      child: Obx(
        () => Column(
          children: [
            _buildThemeOption(
              icon: Icons.brightness_auto_rounded,
              title: '跟随系统',
              isSelected: controller.themeMode.value == AppThemeMode.system,
              onTap: () => controller.setThemeMode(AppThemeMode.system),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildDivider(isDark),
            _buildThemeOption(
              icon: Icons.light_mode_rounded,
              title: '浅色模式',
              isSelected: controller.themeMode.value == AppThemeMode.light,
              onTap: () => controller.setThemeMode(AppThemeMode.light),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildDivider(isDark),
            _buildThemeOption(
              icon: Icons.dark_mode_rounded,
              title: '深色模式',
              isSelected: controller.themeMode.value == AppThemeMode.dark,
              onTap: () => controller.setThemeMode(AppThemeMode.dark),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required bool isSelected,
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
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : textSecondary,
              size: 24.sp,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primaryBlue : textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: AppColors.primaryBlue,
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
