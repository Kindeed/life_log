import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

final class WatchWorkLogEntries {
  final WorkLogRepositoryPort _repository;

  const WatchWorkLogEntries(this._repository);

  Stream<void> call() {
    return _repository.watchEntries();
  }
}
