import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

final class SignOutProfileAccount {
  final ProfileAccountRepositoryPort _repository;

  const SignOutProfileAccount(this._repository);

  Future<AppResult<void>> call() async {
    try {
      await _repository.signOut();
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'profile/sign-out',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
