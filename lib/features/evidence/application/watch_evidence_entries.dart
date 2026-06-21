import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

final class WatchEvidenceEntries {
  final EvidenceRepositoryPort _repository;

  const WatchEvidenceEntries(this._repository);

  Stream<void> call() => _repository.watchEntries();
}
