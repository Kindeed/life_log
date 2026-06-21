import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

/// 主题模式枚举
enum AppThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  final _storage = GetStorage();
  static const _key = 'theme_mode';
  static const _dynamicColorKey = 'dynamic_color_enabled';

  AppThemeMode themeMode = AppThemeMode.system;
  bool dynamicColorEnabled = true;

  ThemeController() {
    _loadThemeMode();
    _loadDynamicColor();
  }

  /// 从本地存储加载主题模式
  void _loadThemeMode() {
    final savedMode = _storage.read<int>(_key);
    if (savedMode != null &&
        savedMode >= 0 &&
        savedMode < AppThemeMode.values.length) {
      themeMode = AppThemeMode.values[savedMode];
    }
  }

  void _loadDynamicColor() {
    dynamicColorEnabled = _storage.read<bool>(_dynamicColorKey) ?? true;
  }

  /// 设置主题模式
  void setThemeMode(AppThemeMode mode) {
    if (themeMode == mode) return;
    themeMode = mode;
    _storage.write(_key, mode.index);
    notifyListeners();
  }

  void setDynamicColorEnabled(bool enabled) {
    if (dynamicColorEnabled == enabled) return;
    dynamicColorEnabled = enabled;
    _storage.write(_dynamicColorKey, enabled);
    notifyListeners();
  }

  /// 获取 Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
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
    switch (themeMode) {
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
    final currentIndex = themeMode.index;
    final nextIndex = (currentIndex + 1) % AppThemeMode.values.length;
    setThemeMode(AppThemeMode.values[nextIndex]);
  }
}
