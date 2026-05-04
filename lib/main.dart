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

bool _supabaseInitialized = false;
bool _storageInitialized = false;
bool _localeInitialized = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

Future<void> _initializeApp() async {
  // 0. 基础设施：存储和国际化
  // Supabase Init — 通过 --dart-define 注入密钥，避免硬编码
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
      'Pass them with --dart-define.',
    );
  }
  if (!_supabaseInitialized) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _supabaseInitialized = true;
  }

  if (!_storageInitialized) {
    await GetStorage.init();
    _storageInitialized = true;
  }
  if (!_localeInitialized) {
    await initializeDateFormatting('zh_CN', null);
    _localeInitialized = true;
  }

  // 1. 核心服务（必须在启动时初始化）
  if (!Get.isRegistered<DbService>()) {
    await Get.putAsync(() => DbService().init());
  }
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController());
  }
  if (!Get.isRegistered<LogService>()) {
    await Get.putAsync(() => LogService().init());
  }
  if (!Get.isRegistered<AuthService>()) {
    Get.put(AuthService());
  }
  if (!Get.isRegistered<SyncService>()) {
    Get.put(SyncService());
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _initializeApp();
  }

  void _retry() {
    setState(() {
      _startup = _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          return _BootstrapShell(
            child: _BootstrapErrorView(error: snapshot.error!, onRetry: _retry),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return const _BootstrapShell(child: _BootstrapLoadingView());
      },
    );
  }
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeLog',
      home: child,
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorText = error.toString();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '启动失败',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorText,
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重试'),
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
