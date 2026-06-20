import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/profile/application/profile_auth_error_message.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

final class SignUpProfileAccount {
  final ProfileAccountRepositoryPort _repository;

  const SignUpProfileAccount(this._repository);

  Future<AppResult<void>> call({
    required String email,
    required String password,
  }) async {
    try {
      await _repository.signUp(email: email, password: password);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'profile/sign-up',
          message: profileAuthErrorMessage(error),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
