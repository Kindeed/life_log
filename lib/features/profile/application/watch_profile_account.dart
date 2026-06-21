import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

final class WatchProfileAccount {
  final ProfileAccountRepositoryPort _repository;

  const WatchProfileAccount(this._repository);

  Stream<ProfileAccountSnapshot> call() => _repository.watchAccount();
}
