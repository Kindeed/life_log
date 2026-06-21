import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/data/photo_model.dart';

abstract interface class PhotoLocalDataSource {
  Future<List<PhotoItem>> getAllPhotos();
  Stream<void> watchPhotos();
  Future<void> addPhoto(PhotoItem photo);
  Future<PhotoItem?> getPhoto(int id);
  Future<void> deletePhoto(int id);
}

final class DbPhotoLocalDataSource implements PhotoLocalDataSource {
  const DbPhotoLocalDataSource();

  @override
  Future<void> addPhoto(PhotoItem photo) {
    return serviceLocator<DbService>().addPhoto(photo);
  }

  @override
  Future<void> deletePhoto(int id) =>
      serviceLocator<DbService>().deletePhoto(id);

  @override
  Future<List<PhotoItem>> getAllPhotos() {
    return serviceLocator<DbService>().getAllPhotos();
  }

  @override
  Future<PhotoItem?> getPhoto(int id) {
    return serviceLocator<DbService>().getPhoto(id);
  }

  @override
  Stream<void> watchPhotos() => serviceLocator<DbService>().watchPhotos();
}
