import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';

final class WatchProjectNoteEntries {
  final ProjectNoteRepositoryPort _repository;
  final Stream<void> Function()? _watchScope;

  const WatchProjectNoteEntries(
    this._repository, {
    Stream<void> Function()? watchScope,
  }) : _watchScope = watchScope;

  Stream<void> call() => _repository.watchEntries();

  Stream<void> watchScope() =>
      _watchScope?.call() ?? const Stream<void>.empty();
}
