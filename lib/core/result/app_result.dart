import 'package:life_log/core/errors/app_failure.dart';

sealed class AppResult<T> {
  const AppResult();

  const factory AppResult.success(T value) = AppSuccess<T>;

  const factory AppResult.failure(AppFailure failure) = AppFailureResult<T>;

  bool get isSuccess => this is AppSuccess<T>;

  bool get isFailure => this is AppFailureResult<T>;

  T? get valueOrNull {
    return switch (this) {
      AppSuccess<T>(:final value) => value,
      AppFailureResult<T>() => null,
    };
  }

  AppFailure? get failureOrNull {
    return switch (this) {
      AppSuccess<T>() => null,
      AppFailureResult<T>(:final failure) => failure,
    };
  }

  T valueOr(T fallback) {
    return switch (this) {
      AppSuccess<T>(:final value) => value,
      AppFailureResult<T>() => fallback,
    };
  }

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      AppSuccess<T>(:final value) => success(value),
      AppFailureResult<T>(failure: final appFailure) => failure(appFailure),
    };
  }
}

final class AppSuccess<T> extends AppResult<T> {
  final T value;

  const AppSuccess(this.value);
}

final class AppFailureResult<T> extends AppResult<T> {
  final AppFailure failure;

  const AppFailureResult(this.failure);
}
