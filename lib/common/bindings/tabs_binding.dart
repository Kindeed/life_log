import 'dart:async';

import 'package:life_log/features/shell/presentation/tabs_controller.dart';
import 'package:life_log/features/work_log/application/initialize_work_log_feature.dart';
import 'package:life_log/core/di/service_locator.dart';
import '../services/log_service.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';

void configurePresentationDependencies() {
  if (!serviceLocator.isRegistered<TabsController>()) {
    serviceLocator.registerLazySingleton<TabsController>(TabsController.new);
  }
  if (!serviceLocator.isRegistered<StatisticsController>()) {
    serviceLocator.registerLazySingleton<StatisticsController>(
      () => StatisticsController()..start(),
      dispose: (controller) => controller.dispose(),
    );
  }
  if (serviceLocator.isRegistered<InitializeWorkLogFeature>()) {
    unawaited(
      _initializeWorkLogFeature(serviceLocator<InitializeWorkLogFeature>()),
    );
  }
}

Future<void> _initializeWorkLogFeature(
  InitializeWorkLogFeature initialize,
) async {
  try {
    await initialize();
  } catch (error, stackTrace) {
    if (serviceLocator.isRegistered<LogService>()) {
      LogService.to.error('WorkLog', '启动归并重复工时失败: $error', stackTrace);
    }
  }
}
