import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class WatchPhotoEntries {
  final PhotoRepositoryPort _repository;

  const WatchPhotoEntries(this._repository);

  Stream<void> call() => _repository.watchEntries();
}
