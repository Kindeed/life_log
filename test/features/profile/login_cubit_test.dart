import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/profile/application/sign_in_profile_account.dart';
import 'package:life_log/features/profile/application/sign_up_profile_account.dart';
import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';
import 'package:life_log/features/profile/presentation/login_cubit.dart';

void main() {
  group('LoginCubit', () {
    test('rejects submit when cloud auth is unavailable', () async {
      final repository = _FakeProfileAuthRepository(isCloudAvailable: false);
      final cubit = _cubit(repository);

      final result = await cubit.submit(
        email: 'wzh@example.com',
        password: '123456',
        confirmPassword: '',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.code, 'profile/cloud-unavailable');

      await cubit.close();
      await repository.close();
    });

    test(
      'rejects mismatched registration passwords before auth call',
      () async {
        final repository = _FakeProfileAuthRepository(isCloudAvailable: true);
        final cubit = _cubit(repository)..toggleMode();

        final result = await cubit.submit(
          email: 'wzh@example.com',
          password: '123456',
          confirmPassword: 'abcdef',
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull!.code, 'profile/password-mismatch');
        expect(repository.signUpCalls, 0);

        await cubit.close();
        await repository.close();
      },
    );

    test('submits sign in through the profile auth command', () async {
      final repository = _FakeProfileAuthRepository(isCloudAvailable: true);
      final cubit = _cubit(repository);

      final result = await cubit.submit(
        email: 'wzh@example.com',
        password: '123456',
        confirmPassword: '',
      );

      expect(result.valueOrNull, LoginSubmitOutcome.signedIn);
      expect(repository.signInCalls, 1);
      expect(repository.lastEmail, 'wzh@example.com');
      expect(cubit.state.isLoading, isFalse);

      await cubit.close();
      await repository.close();
    });
  });
}

LoginCubit _cubit(_FakeProfileAuthRepository repository) {
  return LoginCubit(
    signIn: SignInProfileAccount(repository),
    signUp: SignUpProfileAccount(repository),
    isCloudAvailable: repository.isCloudAvailable,
  );
}

final class _FakeProfileAuthRepository implements ProfileAccountRepositoryPort {
  final _controller = StreamController<ProfileAccountSnapshot>.broadcast();

  @override
  final bool isCloudAvailable;

  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastEmail;

  _FakeProfileAuthRepository({required this.isCloudAvailable});

  @override
  ProfileAccountSnapshot loadAccount() {
    return ProfileAccountSnapshot(
      isCloudConfigured: isCloudAvailable,
      userEmail: null,
    );
  }

  @override
  Stream<ProfileAccountSnapshot> watchAccount() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUpCalls++;
    lastEmail = email;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> syncNow() async => true;

  Future<void> close() => _controller.close();
}
