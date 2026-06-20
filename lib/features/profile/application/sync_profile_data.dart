import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

final class SyncProfileData {
  final ProfileAccountRepositoryPort _repository;

  const SyncProfileData(this._repository);

  Future<AppResult<bool>> call() async {
    try {
      return AppResult.success(await _repository.syncNow());
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'profile/sync-data',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
