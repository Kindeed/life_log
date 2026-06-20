import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/profile/application/sign_in_profile_account.dart';
import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

void main() {
  group('Profile application boundary', () {
    test('does not import provider, data, common service, or GetX layers', () {
      final applicationFiles = Directory('lib/features/profile/application')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in applicationFiles) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains("package:supabase_flutter/supabase_flutter.dart")),
          reason: '${file.path} must not know Supabase provider types.',
        );
        expect(
          source,
          isNot(contains("package:get/get.dart")),
          reason: '${file.path} must not depend on GetX.',
        );
        expect(
          source,
          isNot(contains('/common/services/')),
          reason: '${file.path} must depend on profile ports, not services.',
        );
        expect(
          source,
          isNot(contains('/features/profile/data/')),
          reason: '${file.path} must not import profile data adapters.',
        );
      }
    });

    test(
      'uses repository-provided AppFailure messages without provider types',
      () async {
        const repository = _ThrowingProfileRepository(
          failure: AppFailure(
            code: 'profile/auth-invalid-credentials',
            message: '邮箱或密码错误。',
          ),
        );
        const signIn = SignInProfileAccount(repository);

        final result = await signIn(
          email: 'wzh@example.com',
          password: 'wrong-password',
        );

        expect(result.failureOrNull?.code, 'profile/sign-in');
        expect(result.failureOrNull?.message, '邮箱或密码错误。');
      },
    );
  });
}

final class _ThrowingProfileRepository implements ProfileAccountRepositoryPort {
  final AppFailure failure;

  const _ThrowingProfileRepository({required this.failure});

  @override
  bool get isCloudAvailable => true;

  @override
  ProfileAccountSnapshot loadAccount() {
    return const ProfileAccountSnapshot(
      isCloudConfigured: true,
      userEmail: null,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw failure;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> syncNow() async => false;

  @override
  Stream<ProfileAccountSnapshot> watchAccount() => const Stream.empty();
}
