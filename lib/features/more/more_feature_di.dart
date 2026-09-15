import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';

/// 配置“更多”（More）特性的依赖注入。
GetIt configureMoreFeatureDependencies({GetIt? locator}) {
  final activeLocator = locator ?? serviceLocator;
  return activeLocator;
}
