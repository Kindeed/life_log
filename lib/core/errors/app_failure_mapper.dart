import 'package:life_log/core/errors/app_failure.dart';

class AppFailureMapper {
  const AppFailureMapper();

  AppFailure fromObject(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    return AppFailure(
      code: 'app/unexpected',
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
