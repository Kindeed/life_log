import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/export_photo_entries.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';
import 'package:life_log/features/photo/application/update_photo_description.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/data/legacy_photo_repository_adapter.dart';
import 'package:life_log/features/photo/data/photo_repository.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';

GetIt configurePhotoFeatureDependencies({
  GetIt? locator,
  PhotoRepositoryPort? repository,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<PhotoRepository>()) {
    activeLocator.registerLazySingleton<PhotoRepository>(PhotoRepository.new);
  }

  if (!activeLocator.isRegistered<PhotoRepositoryPort>()) {
    activeLocator.registerLazySingleton<PhotoRepositoryPort>(
      () =>
          repository ??
          LegacyPhotoRepositoryAdapter(activeLocator<PhotoRepository>()),
    );
  }

  if (!activeLocator.isRegistered<WatchPhotoEntries>()) {
    activeLocator.registerLazySingleton<WatchPhotoEntries>(
      () => WatchPhotoEntries(activeLocator<PhotoRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadPhotoEntries>()) {
    activeLocator.registerLazySingleton<LoadPhotoEntries>(
      () => LoadPhotoEntries(activeLocator<PhotoRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<DeletePhotoEntries>()) {
    activeLocator.registerLazySingleton<DeletePhotoEntries>(
      () => DeletePhotoEntries(activeLocator<PhotoRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SavePhotoFromPath>()) {
    activeLocator.registerLazySingleton<SavePhotoFromPath>(
      () => SavePhotoFromPath(activeLocator<PhotoRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<UpdatePhotoDescription>()) {
    activeLocator.registerLazySingleton<UpdatePhotoDescription>(
      () => UpdatePhotoDescription(activeLocator<PhotoRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<ExportPhotoEntries>()) {
    activeLocator.registerLazySingleton<ExportPhotoEntries>(
      () => ExportPhotoEntries(activeLocator<PhotoRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<PhotoCubit>()) {
    activeLocator.registerFactory<PhotoCubit>(
      () => PhotoCubit(
        loadEntries: activeLocator<LoadPhotoEntries>(),
        watchEntries: activeLocator<WatchPhotoEntries>(),
      ),
    );
  }

  return activeLocator;
}
