import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class DeletePhotoEntries {
  final PhotoRepositoryPort _repository;

  const DeletePhotoEntries(this._repository);

  Future<AppResult<void>> call(List<PhotoEntry> entries) async {
    try {
      await _repository.deleteEntries(entries);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'photo/delete-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
