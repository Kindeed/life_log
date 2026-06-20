import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class LoadPhotoEntries {
  final PhotoRepositoryPort _repository;

  const LoadPhotoEntries(this._repository);

  Future<AppResult<List<PhotoEntry>>> call() async {
    try {
      return AppResult.success(await _repository.getAllEntries());
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'photo/load-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
