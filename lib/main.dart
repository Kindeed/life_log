import 'dart:async';
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/modules/tabs/tabs_view.dart';
import 'package:life_log/common/bindings/app_binding.dart';
import 'package:life_log/common/bindings/tabs_binding.dart';
import 'package:life_log/common/bindings/login_binding.dart';
import 'package:life_log/modules/profile/views/login_view.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/theme/theme_controller.dart';
import 'package:life_log/common/services/cloud_config_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/sync_service.dart';

bool _appStarted = false;
String? _cloudStartupWarning;
bool _cloudStartupWarningShown = false;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _bootstrap();
    },
    (error, stackTrace) {
      _logUnhandled('Zone', error, stackTrace);
    },
  );
}

Future<void> _bootstrap() async {
  await GetStorage.init();

  final cloudConfig = Get.put(CloudConfigService().init(), permanent: true);
  final logService = await Get.putAsync(
    () => LogService().init(),
    permanent: true,
  );
  _installGlobalErrorHandlers(logService);

  logService.info('Startup', '本地存储已初始化');
  logService.info('Startup', '云配置状态: ${cloudConfig.statusLabel}');

  await initializeDateFormatting('zh_CN', null);
  logService.info('Startup', '日期格式已初始化');

  await Get.putAsync(() => DbService().init(), permanent: true);
  logService.info('Startup', '本地数据库已初始化');

  Get.put(ThemeController(), permanent: true);
  logService.info('Startup', '主题服务已注册');

  if (cloudConfig.isConfigured.value) {
    await _initializeCloudServices(cloudConfig, logService);
  } else {
    logService.warning('Startup', '云同步未配置，已进入本地模式');
  }

  logService.info('Startup', '启动应用');
  _appStarted = true;
  runApp(const MyApp());
}

Future<void> _initializeCloudServices(
  CloudConfigService cloudConfig,
  LogService logService,
) async {
  try {
    await Supabase.initialize(
      url: cloudConfig.supabaseUrl,
      anonKey: cloudConfig.supabaseAnonKey,
    );
    logService.info('Startup', 'Supabase 初始化成功: ${cloudConfig.supabaseUrl}');
    Get.put(AuthService(), permanent: true);
    Get.put(SyncService(), permanent: true);
    logService.info('Startup', '云服务已注册');
  } catch (error, stackTrace) {
    _cloudStartupWarning = '云同步初始化失败，当前已进入本地模式';
    logService.error('Startup', '${_cloudStartupWarning!}: $error', stackTrace);
  }
}

void _installGlobalErrorHandlers(LogService logService) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logService.error(
      'FlutterError',
      details.exceptionAsString(),
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logService.error('Platform', error.toString(), stackTrace);
    return true;
  };
}

void _logUnhandled(String tag, Object error, StackTrace stackTrace) {
  if (Get.isRegistered<LogService>()) {
    LogService.to.error(tag, error.toString(), stackTrace);
  } else if (kDebugMode) {
    debugPrint('[$tag] $error\n$stackTrace');
  }

  if (!_appStarted) {
    _appStarted = true;
    runApp(StartupFailureApp(message: error.toString()));
  }
}

class StartupFailureApp extends StatelessWidget {
  final String message;

  const StartupFailureApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '应用启动失败',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text('请导出日志或连接调试工具查看详细错误。'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return GetBuilder<ThemeController>(
              id: ThemeController.appThemeBuilderId,
              builder: (themeController) {
                final useDynamic = themeController.dynamicColorEnabled.value;
                return GetMaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'LifeLog',
                  theme: AppTheme.lightWith(useDynamic ? lightDynamic : null),
                  darkTheme: AppTheme.darkWith(useDynamic ? darkDynamic : null),
                  themeMode: themeController.flutterThemeMode,
                  initialBinding: AppBinding(),
                  initialRoute: '/',
                  builder: (context, child) {
                    final warning = _cloudStartupWarning;
                    if (warning != null && !_cloudStartupWarningShown) {
                      _cloudStartupWarningShown = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Get.snackbar('本地模式', warning);
                      });
                    }
                    return child ?? const SizedBox.shrink();
                  },
                  getPages: [
                    GetPage(
                      name: '/',
                      page: () => const TabsView(),
                      binding: TabsBinding(),
                    ),
                    GetPage(
                      name: '/login',
                      page: () => const LoginView(),
                      binding: LoginBinding(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
