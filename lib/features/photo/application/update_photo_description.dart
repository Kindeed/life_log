import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class UpdatePhotoDescription {
  final PhotoRepositoryPort _repository;

  const UpdatePhotoDescription(this._repository);

  Future<AppResult<String?>> call(PhotoEntry entry, String description) async {
    try {
      final oldPathToEvict = await _repository.updateEntryDescription(
        entry,
        description,
      );
      return AppResult.success(oldPathToEvict);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'photo/update-description',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
