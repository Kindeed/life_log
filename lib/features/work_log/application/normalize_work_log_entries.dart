import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class NormalizeWorkLogEntries {
  final WorkLogRepositoryPort _repository;

  const NormalizeWorkLogEntries(this._repository);

  Future<void> call() {
    return _repository.normalizeDuplicateDays();
  }
}
