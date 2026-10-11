import 'package:flutter/material.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/theme_controller.dart';
import 'package:life_log/common/widgets/app_settings.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/presentation/photo_display_preferences.dart';

class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = serviceLocator<ThemeController>();
    final photoDisplayPreferences = serviceLocator<PhotoDisplayPreferences>();
    return Scaffold(
      appBar: AppBar(title: const Text('外观设置')),
      body: SafeArea(
        child: ConstrainedPage(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              themeController,
              photoDisplayPreferences,
            ]),
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: Column(
                children: [
                  AppSettingsGroup(
                    title: '主题模式',
                    children: [
                      for (final entry in [
                        (
                          AppThemeMode.system,
                          '跟随系统',
                          Icons.brightness_auto_rounded,
                        ),
                        (AppThemeMode.light, '浅色模式', Icons.light_mode_rounded),
                        (AppThemeMode.dark, '深色模式', Icons.dark_mode_rounded),
                      ])
                        AppSettingsTile(
                          icon: entry.$3,
                          title: entry.$2,
                          selected: themeController.themeMode == entry.$1,
                          onTap: () => themeController.setThemeMode(entry.$1),
                          trailing: themeController.themeMode == entry.$1
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : const SizedBox(width: 22),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppSettingsGroup(
                    title: '颜色',
                    children: [
                      AppSettingsTile(
                        icon: Icons.auto_awesome_rounded,
                        title: '动态取色',
                        subtitle: 'Android 12 及以上跟随系统壁纸颜色，其他平台使用默认主题色。',
                        onTap: () => themeController.setDynamicColorEnabled(
                          !themeController.dynamicColorEnabled,
                        ),
                        trailing: Switch(
                          value: themeController.dynamicColorEnabled,
                          onChanged: themeController.setDynamicColorEnabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppSettingsGroup(
                    title: '照片信息',
                    children: [
                      AppSettingsTile(
                        icon: Icons.location_on_outlined,
                        title: '显示 GPS',
                        subtitle: '在照片预览中显示已读取的经纬度；缺少 GPS 的照片不显示。',
                        onTap: () => photoDisplayPreferences.setShowGpsMetadata(
                          !photoDisplayPreferences.showGpsMetadata,
                        ),
                        trailing: Switch(
                          value: photoDisplayPreferences.showGpsMetadata,
                          onChanged: photoDisplayPreferences.setShowGpsMetadata,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
