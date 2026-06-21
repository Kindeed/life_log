import 'package:get_it/get_it.dart';
import 'package:life_log/core/errors/app_failure_mapper.dart';

final GetIt serviceLocator = GetIt.instance;

Future<GetIt> configureCoreDependencies({GetIt? locator}) async {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<AppFailureMapper>()) {
    activeLocator.registerLazySingleton<AppFailureMapper>(
      () => const AppFailureMapper(),
    );
  }

  return activeLocator;
}
