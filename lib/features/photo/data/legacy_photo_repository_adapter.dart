import 'package:life_log/features/photo/data/photo_model.dart';
import 'package:life_log/features/photo/data/photo_repository.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

final class LegacyPhotoRepositoryAdapter implements PhotoRepositoryPort {
  final PhotoRepository _repository;

  const LegacyPhotoRepositoryAdapter(this._repository);

  @override
  Future<List<PhotoEntry>> getAllEntries() async {
    final photos = await _repository.getAllPhotos();
    return photos.map((photo) => photo.toPhotoEntry()).toList();
  }

  @override
  Stream<void> watchEntries() => _repository.watchPhotos();

  @override
  Future<PhotoEntry> saveEntryFromPath({
    required String tempPath,
    required String projectName,
    required String description,
    required String deviceName,
    required bool deleteSource,
    DateTime? capturedAt,
    String? capturedAtSource,
    double? gpsLatitude,
    double? gpsLongitude,
  }) async {
    final photo = await _repository.processAndSavePhoto(
      tempPath: tempPath,
      projectName: projectName,
      description: description,
      deviceName: deviceName,
      deleteSource: deleteSource,
      capturedAt: capturedAt,
      capturedAtSource: capturedAtSource,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
    );
    return photo.toPhotoEntry();
  }

  @override
  Future<void> deleteEntries(List<PhotoEntry> entries) {
    return _repository.deletePhotos(entries.map(_photoItemFromEntry).toList());
  }

  @override
  Future<String?> updateEntryDescription(PhotoEntry entry, String description) {
    return _repository.updatePhotoDescription(
      _photoItemFromEntry(entry),
      description,
    );
  }

  @override
  Future<int> exportEntries(List<PhotoEntry> entries, String targetDirectory) {
    return _repository.exportPhotos(
      entries.map(_photoItemFromEntry).toList(),
      targetDirectory,
    );
  }
}

extension PhotoEntryMapper on PhotoItem {
  PhotoEntry toPhotoEntry() {
    return PhotoEntry(
      id: id,
      ownerUserId: ownerUserId,
      createdAt: createdAt,
      capturedAt: capturedAt,
      capturedAtSource: capturedAtSource,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      fileName: fileName,
      filePath: filePath,
      description: description,
      deviceName: deviceName,
      projectName: projectName,
      projectId: projectId,
      dateIndexed: dateIndexed,
    );
  }
}

PhotoItem _photoItemFromEntry(PhotoEntry entry) {
  return PhotoItem()
    ..id = entry.id
    ..ownerUserId = entry.ownerUserId
    ..createdAt = entry.createdAt
    ..capturedAt = entry.capturedAt
    ..capturedAtSource = entry.capturedAtSource
    ..gpsLatitude = entry.gpsLatitude
    ..gpsLongitude = entry.gpsLongitude
    ..fileName = entry.fileName
    ..filePath = entry.filePath
    ..description = entry.description
    ..deviceName = entry.deviceName
    ..projectName = entry.projectName
    ..projectId = entry.projectId
    ..dateIndexed = entry.dateIndexed;
}
