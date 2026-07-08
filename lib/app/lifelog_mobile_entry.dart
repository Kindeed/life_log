import 'dart:async';
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/common/bindings/tabs_binding.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/db/local_data_migration_service.dart';
import 'package:life_log/common/db/local_data_migration_summary.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/cloud_config_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/theme/theme_controller.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/routing/app_router.dart';
import 'package:life_log/core/routing/app_routes.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/evidence/evidence_feature_di.dart';
import 'package:life_log/features/evidence/presentation/evidence_lost_data_recovery.dart';
import 'package:life_log/features/expense/expense_feature_di.dart';
import 'package:life_log/features/photo/photo_feature_di.dart';
import 'package:life_log/features/photo/presentation/photo_lost_data_recovery.dart';
import 'package:life_log/features/profile/presentation/views/login_view.dart';
import 'package:life_log/features/profile/profile_feature_di.dart';
import 'package:life_log/features/project/project_feature_di.dart';
import 'package:life_log/features/shell/presentation/tabs_view.dart';
import 'package:life_log/features/subscription/subscription_feature_di.dart';
import 'package:life_log/features/sync_center/sync_center_feature_di.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _appStarted = false;
String? _cloudStartupWarning;
bool _cloudStartupWarningShown = false;
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final Set<String> _localDataMigrationPromptedUsers = <String>{};
bool _localDataMigrationPromptInFlight = false;

enum _LocalDataMigrationDecision {
  migrate,
  keepLocal,
  exportBackup,
  deleteLocal,
}

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

  final cloudConfig = CloudConfigService().init();
  final logService = await LogService().init();
  _registerCoreRuntimeServices(
    cloudConfig: cloudConfig,
    logService: logService,
  );
  _installGlobalErrorHandlers(logService);

  logService.info('Startup', '本地存储已初始化');
  logService.info('Startup', '云配置状态: ${cloudConfig.statusLabel}');

  await initializeDateFormatting('zh_CN', null);
  logService.info('Startup', '日期格式已初始化');

  final dbService = await DbService().init();
  final localDataMigrationService = LocalDataMigrationService(dbService);
  _registerCoreRuntimeServices(
    cloudConfig: cloudConfig,
    logService: logService,
    dbService: dbService,
    isarDatabase: dbService.database,
    localDataMigrationService: localDataMigrationService,
  );
  logService.info('Startup', '本地数据库已初始化');

  final themeController = ThemeController();
  logService.info('Startup', '主题服务已注册');

  if (cloudConfig.isConfigured) {
    await _initializeCloudServices(cloudConfig, logService);
  } else {
    logService.warning('Startup', '云同步未配置，已进入本地模式');
  }

  await configureCoreDependencies();
  _registerCoreRuntimeServices(
    cloudConfig: cloudConfig,
    logService: logService,
    themeController: themeController,
  );
  _configureFeatureDependencies();
  configurePresentationDependencies();
  logService.info('Startup', '应用依赖已配置');

  logService.info('Startup', '启动应用');
  _appStarted = true;
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runStartupMaintenance(dbService, logService));
    unawaited(recoverLostPhotoData(_rootNavigatorKey));
    unawaited(recoverLostEvidenceData(_rootNavigatorKey));
  });
}

void _configureFeatureDependencies() {
  configureWorkLogFeatureDependencies();
  configureSubscriptionFeatureDependencies();
  configureProjectFeatureDependencies();
  configureExpenseFeatureDependencies();
  configurePhotoFeatureDependencies();
  configureEvidenceFeatureDependencies();
  configureProfileFeatureDependencies();
  configureSyncCenterFeatureDependencies();
}

Future<void> _runStartupMaintenance(
  DbService dbService,
  LogService logService,
) async {
  try {
    logService.info('Startup', '启动后维护任务开始');
    await dbService.runStartupMaintenance();
    logService.info('Startup', '启动后维护任务完成');
  } catch (error, stackTrace) {
    logService.error('Startup', '启动后维护任务失败: $error', stackTrace);
  }
}

void _registerCoreRuntimeServices({
  required CloudConfigService cloudConfig,
  required LogService logService,
  ThemeController? themeController,
  DbService? dbService,
  IsarDatabase? isarDatabase,
  LocalDataMigrationService? localDataMigrationService,
  AuthService? authService,
  SyncService? syncService,
}) {
  if (!serviceLocator.isRegistered<CloudConfigService>()) {
    serviceLocator.registerSingleton<CloudConfigService>(cloudConfig);
  }
  if (!serviceLocator.isRegistered<LogService>()) {
    serviceLocator.registerSingleton<LogService>(logService);
  }
  if (themeController != null &&
      !serviceLocator.isRegistered<ThemeController>()) {
    serviceLocator.registerSingleton<ThemeController>(themeController);
  }
  if (dbService != null && !serviceLocator.isRegistered<DbService>()) {
    serviceLocator.registerSingleton<DbService>(dbService);
  }
  if (isarDatabase != null && !serviceLocator.isRegistered<IsarDatabase>()) {
    serviceLocator.registerSingleton<IsarDatabase>(isarDatabase);
  }
  if (localDataMigrationService != null &&
      !serviceLocator.isRegistered<LocalDataMigrationService>()) {
    serviceLocator.registerSingleton<LocalDataMigrationService>(
      localDataMigrationService,
    );
  }
  if (authService != null && !serviceLocator.isRegistered<AuthService>()) {
    serviceLocator.registerSingleton<AuthService>(authService);
  }
  if (syncService != null && !serviceLocator.isRegistered<SyncService>()) {
    serviceLocator.registerSingleton<SyncService>(syncService);
  }
  if (syncService != null && !serviceLocator.isRegistered<SyncScheduler>()) {
    serviceLocator.registerSingleton<SyncScheduler>(
      SyncScheduler(runSync: syncService.syncAll),
    );
  }
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
    logService.info(
      'Startup',
      'Supabase 初始化成功: ${cloudConfig.maskedSupabaseUrl}',
    );
    final authService = AuthService().start();
    _registerCoreRuntimeServices(
      cloudConfig: cloudConfig,
      logService: logService,
      authService: authService,
    );
    _installLocalDataMigrationPrompt(authService, logService);
    final syncService = SyncService();
    _registerCoreRuntimeServices(
      cloudConfig: cloudConfig,
      logService: logService,
      syncService: syncService,
    );
    syncService.start();
    logService.info('Startup', '云服务已注册');
  } catch (error, stackTrace) {
    _cloudStartupWarning = '云同步初始化失败，当前已进入本地模式';
    logService.error('Startup', '${_cloudStartupWarning!}: $error', stackTrace);
  }
}

void _installLocalDataMigrationPrompt(
  AuthService authService,
  LogService logService,
) {
  void handleAuthChange() {
    final user = authService.currentUser.value;
    if (user == null) return;
    if (_localDataMigrationPromptedUsers.contains(user.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptLocalDataMigration(user.id, logService);
    });
  }

  authService.currentUser.addListener(handleAuthChange);
  handleAuthChange();
}

Future<void> _maybePromptLocalDataMigration(
  String userId,
  LogService logService,
) async {
  if (_localDataMigrationPromptInFlight) return;
  if (_localDataMigrationPromptedUsers.contains(userId)) return;
  if (!serviceLocator.isRegistered<LocalDataMigrationService>()) return;

  final context = _rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  _localDataMigrationPromptInFlight = true;
  try {
    final migration = serviceLocator<LocalDataMigrationService>();
    final summary = await migration.loadSummary();
    if (!summary.hasData) {
      _localDataMigrationPromptedUsers.add(userId);
      return;
    }

    if (!context.mounted) return;
    final decision = await _showLocalDataMigrationDialog(context, summary);
    _localDataMigrationPromptedUsers.add(userId);
    if (decision == null || !context.mounted) return;

    switch (decision) {
      case _LocalDataMigrationDecision.migrate:
        await migration.migrateToCurrentAccountWithBackup();
        if (serviceLocator.isRegistered<SyncService>()) {
          await serviceLocator<SyncService>().syncAll(
            reason: 'local-data-migration',
            forceNew: true,
          );
        }
        if (context.mounted) {
          _showLocalDataMigrationSnack(context, '本地数据已迁移到当前账号并开始同步');
        }
        break;
      case _LocalDataMigrationDecision.keepLocal:
        _showLocalDataMigrationSnack(context, '已保留为本地数据，不会自动上传');
        break;
      case _LocalDataMigrationDecision.exportBackup:
        await migration.exportBackup();
        if (context.mounted) {
          _showLocalDataMigrationSnack(context, '本地数据备份已导出');
        }
        break;
      case _LocalDataMigrationDecision.deleteLocal:
        final confirmed = await _confirmDeleteUnownedLocalData(context);
        if (!confirmed) return;
        await migration.deleteUnownedRecords();
        if (context.mounted) {
          _showLocalDataMigrationSnack(context, '未归属本地数据已删除');
        }
        break;
    }
  } catch (error, stackTrace) {
    logService.error('LocalDataMigration', error.toString(), stackTrace);
    if (context.mounted) {
      _showLocalDataMigrationSnack(context, '本地数据迁移处理失败: $error');
    }
  } finally {
    _localDataMigrationPromptInFlight = false;
  }
}

Future<_LocalDataMigrationDecision?> _showLocalDataMigrationDialog(
  BuildContext context,
  LocalDataMigrationSummary summary,
) {
  return showDialog<_LocalDataMigrationDecision>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final total = summary.totalCount;
      return AlertDialog(
        title: const Text('检测到未绑定账号的本地数据'),
        content: Text('共有 $total 条本地数据尚未绑定账号。迁移会先导出数据库备份，再把这些数据归属到当前账号并同步。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_LocalDataMigrationDecision.keepLocal),
            child: const Text('保留本地'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_LocalDataMigrationDecision.exportBackup),
            child: const Text('导出备份'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_LocalDataMigrationDecision.deleteLocal),
            child: const Text('删除'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_LocalDataMigrationDecision.migrate),
            child: const Text('迁移并同步'),
          ),
        ],
      );
    },
  );
}

Future<bool> _confirmDeleteUnownedLocalData(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: const Text('删除未归属本地数据'),
        content: const Text('删除后这些未绑定账号的数据将无法从云端恢复。建议先导出备份。'),
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
            child: const Text('删除'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void _showLocalDataMigrationSnack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
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
  if (serviceLocator.isRegistered<LogService>()) {
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _router = buildCoreRouter(
    navigatorKey: _rootNavigatorKey,
    rootBuilder: (context, state) => const TabsView(),
    loginBuilder: (context, state) => const LoginView(),
  );

  @override
  void initState() {
    super.initState();
    if (serviceLocator.isRegistered<AuthService>()) {
      serviceLocator<AuthService>().setSessionExpiredHandler(() {
        _router.go(AppRoutes.login);
      });
    }
  }

  @override
  void dispose() {
    if (serviceLocator.isRegistered<AuthService>()) {
      serviceLocator<AuthService>().setSessionExpiredHandler(null);
    }
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = serviceLocator<ThemeController>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return AnimatedBuilder(
              animation: themeController,
              builder: (context, _) {
                final useDynamic = themeController.dynamicColorEnabled;
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'LifeLog',
                  theme: AppTheme.lightWith(useDynamic ? lightDynamic : null),
                  darkTheme: AppTheme.darkWith(useDynamic ? darkDynamic : null),
                  themeMode: themeController.flutterThemeMode,
                  locale: const Locale('zh', 'CN'),
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  supportedLocales: const [Locale('zh', 'CN')],
                  routerConfig: _router,
                  builder: (context, child) {
                    final warning = _cloudStartupWarning;
                    if (warning != null && !_cloudStartupWarningShown) {
                      _cloudStartupWarningShown = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.maybeOf(
                          context,
                        )?.showSnackBar(SnackBar(content: Text(warning)));
                      });
                    }
                    return child ?? const SizedBox.shrink();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
