import 'package:life_log/features/photo/domain/repositories/photo_stage_repository_port.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';

final class AssignPhotoStage {
  final PhotoStageRepositoryPort repository;
  const AssignPhotoStage(this.repository);
  Future<AppResult<int>> call(
    List<PhotoEntry> entries,
    String? stageName,
  ) async {
    try {
      return AppResult.success(
        await repository.assignStage(entries, stageName),
      );
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'photo/assign-stage',
          message: '设置照片阶段失败，请重试',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
