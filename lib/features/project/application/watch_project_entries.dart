import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';

final class WatchProjectEntries {
  final ProjectRepositoryPort _repository;

  const WatchProjectEntries(this._repository);

  Stream<void> call() => _repository.watchEntries();
}
