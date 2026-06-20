import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class SavePhotoFromPath {
  final PhotoRepositoryPort _repository;

  const SavePhotoFromPath(this._repository);

  Future<AppResult<PhotoEntry>> call({
    required String tempPath,
    required String projectName,
    required String description,
    required String deviceName,
    required bool deleteSource,
  }) async {
    try {
      final entry = await _repository.saveEntryFromPath(
        tempPath: tempPath,
        projectName: projectName,
        description: description,
        deviceName: deviceName,
        deleteSource: deleteSource,
      );
      return AppResult.success(entry);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'photo/save-from-path',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
