import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/capture/application/capture_coordinator.dart';
import 'package:life_log/features/capture/data/app_commit_port.dart';
import 'package:life_log/features/capture/data/image_picker_acquisition_port.dart';
import 'package:life_log/features/capture/data/local_capture_journal.dart';
import 'package:life_log/features/capture/data/sandbox_staging_manager.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';

/// 配置 LifeLog 采集（Capture）特性的依赖注入。
///
/// 注册：
/// - [LocalCaptureJournal] 及 [CaptureJournalPort]（存储在应用私有文档目录下的 `capture_journal.json`）
/// - [SandboxStagingManager] 及 [StagingPort]（存储在应用私有文档目录下的 `staging/`）
/// - [ImagePickerAcquisitionPort] 及 [AcquisitionPort]
/// - [AppCommitPort] 及 [CommitPort]
/// - [CaptureCoordinator] 采集生命周期协调器
Future<GetIt> configureCaptureFeatureDependencies({
  GetIt? locator,
  Directory? documentsDirectory,
  CaptureJournalPort? journalPort,
  StagingPort? stagingPort,
  AcquisitionPort? acquisitionPort,
  CommitPort? commitPort,
}) async {
  final activeLocator = locator ?? serviceLocator;

  Directory docsDir;
  if (documentsDirectory != null) {
    docsDir = documentsDirectory;
  } else {
    try {
      docsDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      docsDir = Directory.systemTemp;
    }
  }

  if (!activeLocator.isRegistered<LocalCaptureJournal>()) {
    activeLocator.registerLazySingleton<LocalCaptureJournal>(
      () => LocalCaptureJournal(docsDir, fileName: 'capture_journal.json'),
    );
  }

  if (!activeLocator.isRegistered<CaptureJournalPort>()) {
    activeLocator.registerLazySingleton<CaptureJournalPort>(
      () => journalPort ?? activeLocator<LocalCaptureJournal>(),
    );
  }

  if (!activeLocator.isRegistered<SandboxStagingManager>()) {
    activeLocator.registerLazySingleton<SandboxStagingManager>(
      () => SandboxStagingManager(docsDir),
    );
  }

  if (!activeLocator.isRegistered<StagingPort>()) {
    activeLocator.registerLazySingleton<StagingPort>(
      () => stagingPort ?? activeLocator<SandboxStagingManager>(),
    );
  }

  if (!activeLocator.isRegistered<ImagePickerAcquisitionPort>()) {
    activeLocator.registerLazySingleton<ImagePickerAcquisitionPort>(
      ImagePickerAcquisitionPort.new,
    );
  }

  if (!activeLocator.isRegistered<AcquisitionPort>()) {
    activeLocator.registerLazySingleton<AcquisitionPort>(
      () => acquisitionPort ?? activeLocator<ImagePickerAcquisitionPort>(),
    );
  }

  if (!activeLocator.isRegistered<AppCommitPort>()) {
    activeLocator.registerLazySingleton<AppCommitPort>(
      () => AppCommitPort(
        savePhotoFromPath: activeLocator<SavePhotoFromPath>(),
        saveEvidenceEntry: activeLocator<SaveEvidenceEntry>(),
        evidenceRepository: activeLocator.isRegistered<EvidenceRepositoryPort>()
            ? activeLocator<EvidenceRepositoryPort>()
            : null,
      ),
    );
  }

  if (!activeLocator.isRegistered<CommitPort>()) {
    activeLocator.registerLazySingleton<CommitPort>(
      () => commitPort ?? activeLocator<AppCommitPort>(),
    );
  }

  if (!activeLocator.isRegistered<CaptureCoordinator>()) {
    activeLocator.registerLazySingleton<CaptureCoordinator>(
      () => CaptureCoordinator(
        journalPort: activeLocator<CaptureJournalPort>(),
        stagingPort: activeLocator<StagingPort>(),
        acquisitionPort: activeLocator<AcquisitionPort>(),
        commitPort: activeLocator<CommitPort>(),
      ),
    );
  }

  return activeLocator;
}
