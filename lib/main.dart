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
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. 基础设施：存储和国际化
  // Supabase Init — 通过 --dart-define 注入密钥，避免硬编码
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ikaoktfmytsnximtijjg.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_SnUTjnXNxYUGXBqSrzBqfw_SR-eLNTG',
  );
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await GetStorage.init();
  await initializeDateFormatting('zh_CN', null);

  // 1. 核心服务（必须在启动时初始化）
  await Get.putAsync(() => DbService().init());
  Get.put(ThemeController());
  await Get.putAsync(() => LogService().init());
  Get.put(AuthService());
  Get.put(SyncService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(
          () => GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LifeLog',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.flutterThemeMode,
            initialBinding: AppBinding(),
            initialRoute: '/',
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
          ),
        );
      },
    );
  }
}
