import 'package:life_log/core/errors/app_failure.dart';

String profileAuthErrorMessage(Object error) {
  if (error is AppFailure) {
    return error.message;
  }
  return error.toString();
}
