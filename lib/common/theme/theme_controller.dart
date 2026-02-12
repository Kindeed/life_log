import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 主题模式枚举
enum AppThemeMode { system, light, dark }

/// 主题控制器
/// 管理主题切换和持久化存储
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _storage = GetStorage();
  static const _key = 'theme_mode';

  // 当前主题模式
  final Rx<AppThemeMode> themeMode = AppThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  /// 从本地存储加载主题模式
  void _loadThemeMode() {
    final savedMode = _storage.read<int>(_key);
    if (savedMode != null && savedMode < AppThemeMode.values.length) {
      themeMode.value = AppThemeMode.values[savedMode];
    }
  }

  /// 设置主题模式
  void setThemeMode(AppThemeMode mode) {
    themeMode.value = mode;
    _storage.write(_key, mode.index);

    // 应用主题
    switch (mode) {
      case AppThemeMode.system:
        Get.changeThemeMode(ThemeMode.system);
        break;
      case AppThemeMode.light:
        Get.changeThemeMode(ThemeMode.light);
        break;
      case AppThemeMode.dark:
        Get.changeThemeMode(ThemeMode.dark);
        break;
    }
  }

  /// 获取 Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode.value) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// 获取当前模式的显示名称
  String get currentModeName {
    switch (themeMode.value) {
      case AppThemeMode.system:
        return '跟随系统';
      case AppThemeMode.light:
        return '浅色模式';
      case AppThemeMode.dark:
        return '深色模式';
    }
  }

  /// 循环切换主题（用于快捷切换）
  void toggleTheme() {
    final currentIndex = themeMode.value.index;
    final nextIndex = (currentIndex + 1) % AppThemeMode.values.length;
    setThemeMode(AppThemeMode.values[nextIndex]);
  }
}
