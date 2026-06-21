import 'package:life_log/features/photo/domain/entities/photo_entry.dart';

abstract interface class PhotoRepositoryPort {
  Future<List<PhotoEntry>> getAllEntries();

  Stream<void> watchEntries();

  Future<PhotoEntry> saveEntryFromPath({
    required String tempPath,
    required String projectName,
    required String description,
    required String deviceName,
    required bool deleteSource,
  });

  Future<void> deleteEntries(List<PhotoEntry> entries);

  Future<String?> updateEntryDescription(PhotoEntry entry, String description);

  Future<int> exportEntries(List<PhotoEntry> entries, String targetDirectory);
}
