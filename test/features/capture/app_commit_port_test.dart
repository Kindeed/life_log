import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/features/capture/application/capture_coordinator.dart';
import 'package:life_log/features/capture/capture_feature_di.dart';
import 'package:life_log/features/capture/data/app_commit_port.dart';
import 'package:life_log/features/capture/data/image_picker_acquisition_port.dart';
import 'package:life_log/features/capture/data/local_capture_journal.dart';
import 'package:life_log/features/capture/data/sandbox_staging_manager.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';

// ================= Fakes =================

class _FakePhotoRepository implements PhotoRepositoryPort {
  bool shouldFail = false;
  String failureMessage = 'Photo save failed';

  String? lastTempPath;
  String? lastProjectName;
  String? lastDescription;
  String? lastDeviceName;
  bool? lastDeleteSource;
  DateTime? lastCapturedAt;
  String? lastCapturedAtSource;
  double? lastGpsLatitude;
  double? lastGpsLongitude;

  int nextId = 101;
  final List<PhotoEntry> entries = [];

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
    if (shouldFail) {
      throw Exception(failureMessage);
    }
    lastTempPath = tempPath;
    lastProjectName = projectName;
    lastDescription = description;
    lastDeviceName = deviceName;
    lastDeleteSource = deleteSource;
    lastCapturedAt = capturedAt;
    lastCapturedAtSource = capturedAtSource;
    lastGpsLatitude = gpsLatitude;
    lastGpsLongitude = gpsLongitude;

    final entry = PhotoEntry(
      id: nextId++,
      ownerUserId: 'user-1',
      createdAt: DateTime(2026, 6, 18),
      capturedAt: capturedAt,
      capturedAtSource: capturedAtSource,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      fileName: 'test_photo.jpg',
      filePath: '/data/user/0/photos/test_photo.jpg',
      description: description,
      deviceName: deviceName,
      projectName: projectName,
      projectId: 1,
      dateIndexed: DateTime(2026, 6, 18),
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<List<PhotoEntry>> getAllEntries() async => entries;

  @override
  Future<void> deleteEntries(List<PhotoEntry> entries) async {}

  @override
  Future<int> exportEntries(
    List<PhotoEntry> entries,
    String targetDirectory,
  ) async => 0;

  @override
  Future<String?> updateEntryDescription(
    PhotoEntry entry,
    String description,
  ) async => null;

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

class _FakeEvidenceRepository implements EvidenceRepositoryPort {
  bool shouldFail = false;
  String failureMessage = 'Evidence save failed';

  EvidenceEntry? lastSavedEntry;
  bool? lastMarkDirty;
  String? lastSourcePath;
  String? lastSourceExtension;

  int nextId = 201;
  final List<EvidenceEntry> entries = [];

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    if (shouldFail) {
      throw Exception(failureMessage);
    }
    lastMarkDirty = markDirty;
    lastSourcePath = sourcePath;
    lastSourceExtension = sourceExtension;

    final resolvedId = entry.id == 0 ? nextId++ : entry.id;
    final saved = EvidenceEntry(
      id: resolvedId,
      projectName: entry.projectName,
      projectId: entry.projectId,
      projectSyncId: entry.projectSyncId,
      projectStageName: entry.projectStageName,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      evidenceDate: entry.evidenceDate,
      amount: entry.amount,
      currency: entry.currency,
      category: entry.category,
      status: entry.status,
      merchant: entry.merchant,
      note: entry.note,
      localFilePath: sourcePath,
      tripDate: entry.tripDate,
    );
    lastSavedEntry = saved;
    final existingIndex = entries.indexWhere((e) => e.id == resolvedId);
    if (existingIndex >= 0) {
      entries[existingIndex] = saved;
    } else {
      entries.add(saved);
    }
  }

  @override
  Future<List<EvidenceEntry>> getAllEntries() async => entries;

  @override
  Future<void> deleteEntry(int id) async {
    entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async => null;

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

class _FakeImagePicker extends ImagePicker {
  String? pickImagePathToReturn;
  bool shouldThrowOnPick = false;
  List<XFile>? lostFilesToReturn;
  PlatformException? lostDataException;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (shouldThrowOnPick) {
      throw Exception('Picker error');
    }
    if (pickImagePathToReturn == null) return null;
    return XFile(pickImagePathToReturn!);
  }

  @override
  Future<LostDataResponse> retrieveLostData() async {
    if (lostDataException != null) {
      return LostDataResponse(
        file: null,
        exception: lostDataException,
        type: RetrieveType.image,
      );
    }
    if (lostFilesToReturn != null) {
      return LostDataResponse(
        files: lostFilesToReturn,
        file: lostFilesToReturn!.isNotEmpty ? lostFilesToReturn!.first : null,
        type: RetrieveType.image,
      );
    }
    return LostDataResponse.empty();
  }
}

// ================= Tests =================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePhotoRepository photoRepo;
  late _FakeEvidenceRepository evidenceRepo;
  late SavePhotoFromPath savePhotoFromPath;
  late SaveEvidenceEntry saveEvidenceEntry;
  late AppCommitPort commitPort;

  const testOwner = CaptureOwnerContext(
    ownerUserId: 'user-001',
    sessionEpoch: 1,
  );

  setUp(() {
    photoRepo = _FakePhotoRepository();
    evidenceRepo = _FakeEvidenceRepository();
    savePhotoFromPath = SavePhotoFromPath(photoRepo);
    saveEvidenceEntry = SaveEvidenceEntry(evidenceRepo);
    commitPort = AppCommitPort(
      savePhotoFromPath: savePhotoFromPath,
      saveEvidenceEntry: saveEvidenceEntry,
      evidenceRepository: evidenceRepo,
    );
  });

  group('AppCommitPort - Photo commit', () {
    test(
      'successfully commits photo draft with deleteSource = false',
      () async {
        final draft = CaptureDraft.create(
          taskId: 'task-photo-1',
          ownerContext: testOwner,
          purpose: CapturePurpose.photo,
          stagedPaths: const ['/sandbox/staging/task-photo-1_image.jpg'],
          draftValues: const {
            'projectName': 'LifeLog App',
            'description': '现场拍摄第一张',
            'deviceName': 'Pixel 8',
            'capturedAt': '2026-06-18T10:00:00.000',
            'capturedAtSource': 'exif',
            'gpsLatitude': 31.2304,
            'gpsLongitude': 121.4737,
          },
        );

        final result = await commitPort.commit(draft);

        expect(result.taskId, 'task-photo-1');
        expect(result.purpose, CapturePurpose.photo);
        expect(result.committedId, 101);
        expect(result.isUpdate, isFalse);
        expect(result.metadata['fileName'], 'test_photo.jpg');
        expect(result.metadata['projectName'], 'LifeLog App');

        // 验证核心约束：deleteSource 必须为 false
        expect(photoRepo.lastDeleteSource, isFalse);
        expect(
          photoRepo.lastTempPath,
          '/sandbox/staging/task-photo-1_image.jpg',
        );
        expect(photoRepo.lastProjectName, 'LifeLog App');
        expect(photoRepo.lastDescription, '现场拍摄第一张');
        expect(photoRepo.lastDeviceName, 'Pixel 8');
        expect(
          photoRepo.lastCapturedAt,
          DateTime.parse('2026-06-18T10:00:00.000'),
        );
        expect(photoRepo.lastGpsLatitude, 31.2304);
        expect(photoRepo.lastGpsLongitude, 121.4737);

        // 验证 findCommitted 幂等缓存
        final cached = await commitPort.findCommitted(
          'task-photo-1',
          testOwner,
        );
        expect(cached, isNotNull);
        expect(cached!.committedId, 101);
      },
    );

    test(
      'throws CaptureCommitException when photo stagedPaths is empty',
      () async {
        final draft = CaptureDraft.create(
          taskId: 'task-photo-empty',
          ownerContext: testOwner,
          purpose: CapturePurpose.photo,
          stagedPaths: const [],
        );

        expect(
          () => commitPort.commit(draft),
          throwsA(isA<CaptureCommitException>()),
        );
      },
    );

    test('throws CaptureCommitException when photo save fails', () async {
      photoRepo.shouldFail = true;
      photoRepo.failureMessage = 'Disk full';

      final draft = CaptureDraft.create(
        taskId: 'task-photo-fail',
        ownerContext: testOwner,
        purpose: CapturePurpose.photo,
        stagedPaths: const ['/staging/temp.jpg'],
      );

      expect(
        () => commitPort.commit(draft),
        throwsA(
          isA<CaptureCommitException>().having(
            (e) => e.message,
            'message',
            contains('Disk full'),
          ),
        ),
      );
    });
  });

  group('AppCommitPort - Evidence commit', () {
    test('successfully commits new evidence draft', () async {
      final draft = CaptureDraft.create(
        taskId: 'task-evidence-1',
        ownerContext: testOwner,
        purpose: CapturePurpose.evidence,
        stagedPaths: const ['/sandbox/staging/receipt.png'],
        draftValues: const {
          'projectName': '办公采购',
          'amount': 88.50,
          'merchant': 'Apple Store',
          'category': 'purchase',
          'status': 'submitted',
          'note': '采购键盘',
          'currency': 'CNY',
          'evidenceDate': '2026-06-18T12:00:00.000',
        },
      );

      final result = await commitPort.commit(draft);

      expect(result.taskId, 'task-evidence-1');
      expect(result.purpose, CapturePurpose.evidence);
      expect(result.committedId, 201);
      expect(result.isUpdate, isFalse);
      expect(result.metadata['projectName'], '办公采购');
      expect(result.metadata['amount'], 88.50);
      expect(result.metadata['merchant'], 'Apple Store');

      expect(evidenceRepo.lastMarkDirty, isTrue);
      expect(evidenceRepo.lastSourcePath, '/sandbox/staging/receipt.png');
      expect(evidenceRepo.lastSourceExtension, 'png');
      expect(evidenceRepo.lastSavedEntry?.projectName, '办公采购');
      expect(evidenceRepo.lastSavedEntry?.amount, 88.50);
      expect(evidenceRepo.lastSavedEntry?.merchant, 'Apple Store');
      expect(
        evidenceRepo.lastSavedEntry?.category,
        EvidenceEntryCategory.purchase,
      );
      expect(
        evidenceRepo.lastSavedEntry?.status,
        EvidenceEntryStatus.submitted,
      );

      // 验证 findCommitted 幂等缓存
      final cached = await commitPort.findCommitted(
        'task-evidence-1',
        testOwner,
      );
      expect(cached, isNotNull);
      expect(cached!.committedId, 201);
    });

    test(
      'successfully updates existing evidence when editTargetId != null (U290)',
      () async {
        final draft = CaptureDraft.create(
          taskId: 'task-evidence-update',
          ownerContext: testOwner,
          purpose: CapturePurpose.evidence,
          editTargetId: 999,
          stagedPaths: const ['/sandbox/staging/new_invoice.pdf'],
          draftValues: const {
            'projectName': '差旅费',
            'amount': '350.00',
            'merchant': '希尔顿酒店',
            'category': '住宿',
            'note': '更新发票图片',
          },
        );

        final result = await commitPort.commit(draft);

        expect(result.taskId, 'task-evidence-update');
        expect(result.purpose, CapturePurpose.evidence);
        expect(result.committedId, 999);
        expect(result.isUpdate, isTrue);

        expect(evidenceRepo.lastSavedEntry?.id, 999);
        expect(evidenceRepo.lastSavedEntry?.projectName, '差旅费');
        expect(evidenceRepo.lastSavedEntry?.amount, 350.00);
        expect(evidenceRepo.lastSavedEntry?.merchant, '希尔顿酒店');
        expect(
          evidenceRepo.lastSavedEntry?.category,
          EvidenceEntryCategory.accommodation,
        );
        expect(evidenceRepo.lastSourceExtension, 'pdf');
      },
    );

    test('throws CaptureCommitException when evidence save fails', () async {
      evidenceRepo.shouldFail = true;
      evidenceRepo.failureMessage = 'Database locked';

      final draft = CaptureDraft.create(
        taskId: 'task-evidence-fail',
        ownerContext: testOwner,
        purpose: CapturePurpose.evidence,
        draftValues: const {'projectName': '测试'},
      );

      expect(
        () => commitPort.commit(draft),
        throwsA(
          isA<CaptureCommitException>().having(
            (e) => e.message,
            'message',
            contains('Database locked'),
          ),
        ),
      );
    });

    test('findCommitted returns null for uncommitted draft', () async {
      final uncommitted = await commitPort.findCommitted(
        'unknown-task',
        testOwner,
      );
      expect(uncommitted, isNull);
    });
  });

  group('ImagePickerAcquisitionPort', () {
    late _FakeImagePicker fakePicker;
    late ImagePickerAcquisitionPort acquisitionPort;

    setUp(() {
      fakePicker = _FakeImagePicker();
      acquisitionPort = ImagePickerAcquisitionPort(picker: fakePicker);
    });

    test('acquires media and releases session lock on completion', () async {
      fakePicker.pickImagePathToReturn = '/tmp/picked.jpg';

      expect(acquisitionPort.isSessionActive, isFalse);

      final pathFuture = acquisitionPort.acquireMedia(
        taskId: 't-1',
        source: AcquisitionSource.camera,
      );

      final path = await pathFuture;
      expect(path, '/tmp/picked.jpg');
      expect(acquisitionPort.isSessionActive, isFalse);
    });

    test(
      'throws AcquisitionBusyException when another session is active',
      () async {
        // Simulate active session
        final portWithActive = ImagePickerAcquisitionPort(picker: fakePicker);

        // We can trigger an asynchronous acquisition that doesn't finish immediately,
        // or check manual release
        fakePicker.pickImagePathToReturn = '/tmp/p.jpg';
        final future1 = portWithActive.acquireMedia(
          taskId: 'task-1',
          source: AcquisitionSource.camera,
        );

        // Now portWithActive is active while future1 executes
        expect(portWithActive.isSessionActive, isTrue);
        expect(
          () => portWithActive.acquireMedia(
            taskId: 'task-2',
            source: AcquisitionSource.gallery,
          ),
          throwsA(isA<AcquisitionBusyException>()),
        );

        await future1;
        expect(portWithActive.isSessionActive, isFalse);
      },
    );

    test('releaseSession resets the session lock', () async {
      fakePicker.pickImagePathToReturn = '/tmp/p.jpg';
      final future = acquisitionPort.acquireMedia(
        taskId: 'task-lock',
        source: AcquisitionSource.camera,
      );
      expect(acquisitionPort.isSessionActive, isTrue);

      await acquisitionPort.releaseSession(taskId: 'task-lock');
      expect(acquisitionPort.isSessionActive, isFalse);

      await future;
    });

    test('retrieveLostData returns lost file paths', () async {
      fakePicker.lostFilesToReturn = [
        XFile('/storage/lost_1.jpg'),
        XFile('/storage/lost_2.jpg'),
      ];

      final lost = await acquisitionPort.retrieveLostData();
      expect(lost, ['/storage/lost_1.jpg', '/storage/lost_2.jpg']);
    });
  });

  group('configureCaptureFeatureDependencies DI', () {
    late GetIt testLocator;
    late Directory tempDir;

    setUp(() {
      testLocator = GetIt.asNewInstance();
      tempDir = Directory.systemTemp.createTempSync('capture_di_test_');

      // Register required external feature dependencies in test locator
      testLocator.registerLazySingleton<PhotoRepositoryPort>(() => photoRepo);
      testLocator.registerLazySingleton<SavePhotoFromPath>(
        () => savePhotoFromPath,
      );
      testLocator.registerLazySingleton<EvidenceRepositoryPort>(
        () => evidenceRepo,
      );
      testLocator.registerLazySingleton<SaveEvidenceEntry>(
        () => saveEvidenceEntry,
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('registers all capture ports and coordinator', () async {
      await configureCaptureFeatureDependencies(
        locator: testLocator,
        documentsDirectory: tempDir,
      );

      expect(testLocator.isRegistered<LocalCaptureJournal>(), isTrue);
      expect(testLocator.isRegistered<CaptureJournalPort>(), isTrue);
      expect(testLocator.isRegistered<SandboxStagingManager>(), isTrue);
      expect(testLocator.isRegistered<StagingPort>(), isTrue);
      expect(testLocator.isRegistered<ImagePickerAcquisitionPort>(), isTrue);
      expect(testLocator.isRegistered<AcquisitionPort>(), isTrue);
      expect(testLocator.isRegistered<AppCommitPort>(), isTrue);
      expect(testLocator.isRegistered<CommitPort>(), isTrue);
      expect(testLocator.isRegistered<CaptureCoordinator>(), isTrue);

      final coordinator = testLocator<CaptureCoordinator>();
      expect(coordinator, isNotNull);
    });
  });
}
