import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/profile/application/load_profile_account.dart';
import 'package:life_log/features/profile/application/watch_profile_account.dart';
import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';
import 'package:life_log/features/profile/presentation/profile_account_cubit.dart';

void main() {
  group('ProfileAccountCubit', () {
    test('loads local-mode account snapshot', () async {
      final repository = _FakeProfileAccountRepository(
        const ProfileAccountSnapshot(isCloudConfigured: false, userEmail: null),
      );
      final cubit = ProfileAccountCubit(
        loadAccount: LoadProfileAccount(repository),
        watchAccount: WatchProfileAccount(repository),
      );

      await cubit.loadAccount();

      expect(cubit.state.status, ProfileAccountStatus.ready);
      expect(cubit.state.isCloudConfigured, isFalse);
      expect(cubit.state.isLoggedIn, isFalse);
      expect(cubit.state.userName, '本地模式');

      await cubit.close();
      await repository.close();
    });

    test('updates account state when repository emits auth changes', () async {
      final repository = _FakeProfileAccountRepository(
        const ProfileAccountSnapshot(isCloudConfigured: true, userEmail: null),
      );
      final cubit = ProfileAccountCubit(
        loadAccount: LoadProfileAccount(repository),
        watchAccount: WatchProfileAccount(repository),
      );

      cubit.start();
      await Future<void>.delayed(Duration.zero);
      repository.emit(
        const ProfileAccountSnapshot(
          isCloudConfigured: true,
          userEmail: 'wzh@example.com',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isCloudConfigured, isTrue);
      expect(cubit.state.isLoggedIn, isTrue);
      expect(cubit.state.userName, 'wzh@example.com');

      await cubit.close();
      await repository.close();
    });
  });
}

final class _FakeProfileAccountRepository
    implements ProfileAccountRepositoryPort {
  final _controller = StreamController<ProfileAccountSnapshot>.broadcast();
  ProfileAccountSnapshot snapshot;

  _FakeProfileAccountRepository(this.snapshot);

  @override
  bool get isCloudAvailable => snapshot.isCloudConfigured;

  @override
  ProfileAccountSnapshot loadAccount() => snapshot;

  @override
  Stream<ProfileAccountSnapshot> watchAccount() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    snapshot = ProfileAccountSnapshot(
      isCloudConfigured: snapshot.isCloudConfigured,
      userEmail: email,
    );
    emit(snapshot);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    snapshot = ProfileAccountSnapshot(
      isCloudConfigured: snapshot.isCloudConfigured,
      userEmail: null,
    );
    emit(snapshot);
  }

  @override
  Future<bool> syncNow() async => true;

  void emit(ProfileAccountSnapshot next) {
    snapshot = next;
    _controller.add(next);
  }

  Future<void> close() => _controller.close();
}
