import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/theme_controller.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/core/di/service_locator.dart';

/// 外观设置页面
class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = serviceLocator<ThemeController>();
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('外观设置'), centerTitle: true),
      body: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('主题模式', textPrimary),
                SizedBox(height: 12.h),
                _buildThemeSelector(
                  themeController,
                  theme,
                  textPrimary,
                  textSecondary,
                ),
                SizedBox(height: 22.h),
                _buildSectionTitle('颜色', textPrimary),
                SizedBox(height: 12.h),
                _buildDynamicColorOption(themeController, theme, textSecondary),
              ],
            ),
          );
        },
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
    ThemeData theme,
    Color textPrimary,
    Color textSecondary,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildThemeOption(
            icon: Icons.brightness_auto_rounded,
            title: '跟随系统',
            isSelected: controller.themeMode == AppThemeMode.system,
            onTap: () => controller.setThemeMode(AppThemeMode.system),
            theme: theme,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildDivider(theme),
          _buildThemeOption(
            icon: Icons.light_mode_rounded,
            title: '浅色模式',
            isSelected: controller.themeMode == AppThemeMode.light,
            onTap: () => controller.setThemeMode(AppThemeMode.light),
            theme: theme,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildDivider(theme),
          _buildThemeOption(
            icon: Icons.dark_mode_rounded,
            title: '深色模式',
            isSelected: controller.themeMode == AppThemeMode.dark,
            onTap: () => controller.setThemeMode(AppThemeMode.dark),
            theme: theme,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final selectedColor = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : textSecondary,
              size: 24.sp,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? selectedColor : textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: selectedColor, size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicColorOption(
    ThemeController controller,
    ThemeData theme,
    Color textSecondary,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: controller.dynamicColorEnabled,
        onChanged: controller.setDynamicColorEnabled,
        secondary: Icon(
          Icons.auto_awesome_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text('动态取色'),
        subtitle: Text(
          'Android 12 及以上跟随系统壁纸颜色，其他平台自动使用默认主题色。',
          style: TextStyle(color: textSecondary),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(height: 1, color: theme.dividerColor),
    );
  }
}
