import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/load_evidence_edit_draft.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/data/evidence_parse_service.dart';
import 'package:life_log/features/evidence/data/evidence_repository.dart';
import 'package:life_log/features/evidence/data/legacy_evidence_repository_adapter.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';

GetIt configureEvidenceFeatureDependencies({
  GetIt? locator,
  EvidenceRepositoryPort? repository,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<EvidenceRepository>()) {
    activeLocator.registerLazySingleton<EvidenceRepository>(
      EvidenceRepository.new,
    );
  }

  if (!activeLocator.isRegistered<EvidenceParseService>()) {
    activeLocator.registerLazySingleton<EvidenceParseService>(
      EvidenceParseService.new,
    );
  }

  if (!activeLocator.isRegistered<EvidenceRepositoryPort>()) {
    activeLocator.registerLazySingleton<EvidenceRepositoryPort>(
      () =>
          repository ??
          LegacyEvidenceRepositoryAdapter(activeLocator<EvidenceRepository>()),
    );
  }

  if (!activeLocator.isRegistered<WatchEvidenceEntries>()) {
    activeLocator.registerLazySingleton<WatchEvidenceEntries>(
      () => WatchEvidenceEntries(activeLocator<EvidenceRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadEvidenceEntries>()) {
    activeLocator.registerLazySingleton<LoadEvidenceEntries>(
      () => LoadEvidenceEntries(activeLocator<EvidenceRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<LoadEvidenceEditDraft>()) {
    activeLocator.registerLazySingleton<LoadEvidenceEditDraft>(
      () => LoadEvidenceEditDraft(activeLocator<EvidenceRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SaveEvidenceEntry>()) {
    activeLocator.registerLazySingleton<SaveEvidenceEntry>(
      () => SaveEvidenceEntry(activeLocator<EvidenceRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<DeleteEvidenceEntry>()) {
    activeLocator.registerLazySingleton<DeleteEvidenceEntry>(
      () => DeleteEvidenceEntry(activeLocator<EvidenceRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<EvidenceCubit>()) {
    activeLocator.registerFactory<EvidenceCubit>(
      () => EvidenceCubit(
        loadEntries: activeLocator<LoadEvidenceEntries>(),
        watchEntries: activeLocator<WatchEvidenceEntries>(),
      ),
    );
  }

  return activeLocator;
}
