import 'package:life_log/features/photo/domain/entities/photo_entry.dart';

abstract interface class PhotoStageRepositoryPort {
  Future<int> assignStage(List<PhotoEntry> entries, String? stageName);
}
