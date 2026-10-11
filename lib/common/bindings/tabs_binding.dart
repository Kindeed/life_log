import 'dart:async';

import 'package:life_log/features/shell/presentation/tabs_controller.dart';
import 'package:life_log/features/work_log/application/initialize_work_log_feature.dart';
import 'package:life_log/core/di/service_locator.dart';
import '../services/log_service.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

void configurePresentationDependencies() {
  if (!serviceLocator.isRegistered<TabsController>()) {
    serviceLocator.registerLazySingleton<TabsController>(TabsController.new);
  }
  if (!serviceLocator.isRegistered<StatisticsController>()) {
    serviceLocator.registerLazySingleton<StatisticsController>(
      () => StatisticsController(watchScope: _watchStatisticsScope)..start(),
      dispose: (controller) => controller.dispose(),
    );
  }
  if (serviceLocator.isRegistered<InitializeWorkLogFeature>()) {
    unawaited(
      _initializeWorkLogFeature(serviceLocator<InitializeWorkLogFeature>()),
    );
  }
}

Stream<void> _watchStatisticsScope() {
  if (!serviceLocator.isRegistered<ProfileAccountRepositoryPort>()) {
    return const Stream.empty();
  }
  final account = serviceLocator<ProfileAccountRepositoryPort>();
  final initial = account.loadAccount();
  var first = true;
  return account
      .watchAccount()
      .where((snapshot) {
        if (first) {
          first = false;
          return snapshot != initial;
        }
        // This port exposes no durable owner id. Every later auth notification
        // therefore invalidates cached aggregates conservatively.
        return true;
      })
      .map((_) {});
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
