import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class ExportPhotoEntries {
  final PhotoRepositoryPort _repository;

  const ExportPhotoEntries(this._repository);

  Future<AppResult<int>> call(
    List<PhotoEntry> entries,
    String targetDirectory,
  ) async {
    try {
      final exportedCount = await _repository.exportEntries(
        entries,
        targetDirectory,
      );
      return AppResult.success(exportedCount);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'photo/export-entries',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
