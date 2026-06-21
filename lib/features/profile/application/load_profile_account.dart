import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

final class LoadProfileAccount {
  final ProfileAccountRepositoryPort _repository;

  const LoadProfileAccount(this._repository);

  Future<AppResult<ProfileAccountSnapshot>> call() async {
    try {
      return AppResult.success(_repository.loadAccount());
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'profile/load-account',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
