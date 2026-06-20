import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';

abstract interface class ProfileAccountRepositoryPort {
  bool get isCloudAvailable;

  ProfileAccountSnapshot loadAccount();

  Stream<ProfileAccountSnapshot> watchAccount();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({required String email, required String password});

  Future<void> signOut();

  Future<bool> syncNow();
}
