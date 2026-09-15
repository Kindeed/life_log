import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/capture/application/capture_coordinator.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';
import 'package:life_log/features/capture/presentation/capture_recovery_handler.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_sheet.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';

// Fake implementations for Capture ports
class FakeCaptureJournalPort implements CaptureJournalPort {
  final Map<String, CaptureDraft> drafts = {};

  @override
  Future<void> writeDraft(CaptureDraft draft) async {
    drafts[draft.taskId] = draft;
  }

  @override
  Future<CaptureDraft?> readDraft(String taskId) async {
    return drafts[taskId];
  }

  @override
  Future<List<CaptureDraft>> listActiveDrafts({String? ownerUserId}) async {
    return drafts.values.where((d) {
      if (!d.isActive) return false;
      if (ownerUserId != null && d.ownerContext.ownerUserId != ownerUserId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> removeDraft(String taskId) async {
    drafts.remove(taskId);
  }
}

class FakeStagingPort implements StagingPort {
  final Map<String, List<String>> stagedByTask = {};

  @override
  Future<String> stageFile({
    required String taskId,
    required String sourcePath,
    CapturePurpose? purpose,
  }) async {
    final fileName = sourcePath.split('/').last;
    final staged = '/sandbox/$taskId/$fileName';
    stagedByTask.putIfAbsent(taskId, () => []).add(staged);
    return staged;
  }

  @override
  Future<List<String>> stageFiles({
    required String taskId,
    required List<String> sourcePaths,
    CapturePurpose? purpose,
  }) async {
    final result = <String>[];
    for (final path in sourcePaths) {
      result.add(
        await stageFile(taskId: taskId, sourcePath: path, purpose: purpose),
      );
    }
    return result;
  }

  @override
  Future<List<String>> getStagedFiles(String taskId) async {
    return stagedByTask[taskId] ?? const [];
  }

  @override
  Future<void> clearTaskStaging(String taskId) async {
    stagedByTask.remove(taskId);
  }

  @override
  Future<void> removeStagedFile(String stagedPath) async {
    for (final list in stagedByTask.values) {
      list.remove(stagedPath);
    }
  }
}

class FakeAcquisitionPort implements AcquisitionPort {
  List<String> lostData = [];

  @override
  bool get isSessionActive => false;

  @override
  Future<String?> acquireMedia({
    required String taskId,
    required AcquisitionSource source,
  }) async => null;

  @override
  Future<List<String>> retrieveLostData() async {
    final result = List<String>.from(lostData);
    lostData.clear();
    return result;
  }

  @override
  Future<void> releaseSession({required String taskId}) async {}
}

class FakeCommitPort implements CommitPort {
  final Map<String, CommitResult> committedMap = {};

  @override
  Future<CommitResult> commit(CaptureDraft draft) async {
    final res = CommitResult(
      taskId: draft.taskId,
      purpose: draft.purpose,
      committedId: 101,
      isUpdate: draft.editTargetId != null,
      committedAt: DateTime.now(),
    );
    committedMap[draft.taskId] = res;
    return res;
  }

  @override
  Future<CommitResult?> findCommitted(
    String taskId,
    CaptureOwnerContext owner,
  ) async {
    return committedMap[taskId];
  }
}

class FakePhotoRepository implements PhotoRepositoryPort {
  final List<PhotoEntry> photos = [];

  @override
  Future<int> unlinkEntriesFromProject({
    required int projectId,
    required String projectName,
  }) async => 0;

  @override
  Future<List<PhotoEntry>> getAllEntries() async => photos;

  @override
  Stream<void> watchEntries() => const Stream.empty();

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
    final entry = PhotoEntry(
      id: photos.length + 1,
      ownerUserId: null,
      fileName: 'photo_${photos.length + 1}.jpg',
      filePath: tempPath,
      createdAt: capturedAt ?? DateTime.now(),
      deviceName: deviceName,
      projectName: projectName,
      description: description,
      projectId: null,
      dateIndexed: DateTime.now(),
    );
    photos.add(entry);
    return entry;
  }

  @override
  Future<void> deleteEntries(List<PhotoEntry> entries) async {
    final ids = entries.map((e) => e.id).toSet();
    photos.removeWhere((p) => ids.contains(p.id));
  }

  @override
  Future<String?> updateEntryDescription(
    PhotoEntry entry,
    String description,
  ) async => null;

  @override
  Future<int> exportEntries(
    List<PhotoEntry> entries,
    String targetDirectory,
  ) async => entries.length;
}

class FakeEvidenceRepository implements EvidenceRepositoryPort {
  final Map<int, EvidenceEntry> entries = {};

  @override
  Future<List<EvidenceEntry>> getAllEntries() async => entries.values.toList();

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async {
    final entry = entries[id];
    if (entry == null) return null;
    return EvidenceEditDraft(entry: entry, alreadyDirty: false);
  }

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    entries[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(int id) async {
    entries.remove(id);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaptureCoordinator 全局接线静态验证', () {
    test('lifelog_mobile_entry.dart 接入 capture DI 及 postFrame 统一恢复', () {
      final entryFile = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();

      expect(
        entryFile,
        contains('configureCaptureFeatureDependencies();'),
        reason:
            '_configureFeatureDependencies 应注册 configureCaptureFeatureDependencies',
      );
      expect(
        entryFile,
        contains('recoverLostCaptureData(_rootNavigatorKey)'),
        reason: 'addPostFrameCallback 应调用统一的 recoverLostCaptureData',
      );
      expect(
        entryFile,
        contains(
          "import 'package:life_log/features/capture/capture_feature_di.dart';",
        ),
      );
      expect(
        entryFile,
        contains(
          "import 'package:life_log/features/capture/presentation/capture_recovery_handler.dart';",
        ),
      );
    });

    test('capture_recovery_handler.dart 导出统一 recoverLostCaptureData 入口', () {
      final handlerFile = File(
        'lib/features/capture/presentation/capture_recovery_handler.dart',
      ).readAsStringSync();
      expect(handlerFile, contains('recoverLostCaptureData('));
      expect(handlerFile, contains('CaptureOwnerContext'));
      expect(handlerFile, contains('CapturePurpose.photo'));
      expect(handlerFile, contains('CapturePurpose.evidence'));
      expect(handlerFile, contains('editTargetId'));
    });
  });

  group('CaptureCoordinator DI 与恢复路由协调集成测试', () {
    late FakeCaptureJournalPort journalPort;
    late FakeStagingPort stagingPort;
    late FakeAcquisitionPort acquisitionPort;
    late FakeCommitPort commitPort;
    late CaptureCoordinator coordinator;
    late FakePhotoRepository photoRepo;
    late FakeEvidenceRepository evidenceRepo;

    const owner = CaptureOwnerContext(
      ownerUserId: 'test_user',
      sessionEpoch: 1,
    );

    setUp(() {
      journalPort = FakeCaptureJournalPort();
      stagingPort = FakeStagingPort();
      acquisitionPort = FakeAcquisitionPort();
      commitPort = FakeCommitPort();

      coordinator = CaptureCoordinator(
        journalPort: journalPort,
        stagingPort: stagingPort,
        acquisitionPort: acquisitionPort,
        commitPort: commitPort,
      );

      photoRepo = FakePhotoRepository();
      evidenceRepo = FakeEvidenceRepository();

      if (serviceLocator.isRegistered<PhotoCubit>()) {
        serviceLocator.unregister<PhotoCubit>();
      }
      if (serviceLocator.isRegistered<SavePhotoFromPath>()) {
        serviceLocator.unregister<SavePhotoFromPath>();
      }
      if (serviceLocator.isRegistered<EvidenceRepositoryPort>()) {
        serviceLocator.unregister<EvidenceRepositoryPort>();
      }
      if (serviceLocator.isRegistered<SaveEvidenceEntry>()) {
        serviceLocator.unregister<SaveEvidenceEntry>();
      }
      if (serviceLocator.isRegistered<DeleteEvidenceEntry>()) {
        serviceLocator.unregister<DeleteEvidenceEntry>();
      }
      if (serviceLocator.isRegistered<CaptureCoordinator>()) {
        serviceLocator.unregister<CaptureCoordinator>();
      }

      serviceLocator.registerFactory<PhotoCubit>(
        () => PhotoCubit(
          loadEntries: LoadPhotoEntries(photoRepo),
          watchEntries: WatchPhotoEntries(photoRepo),
        ),
      );
      serviceLocator.registerLazySingleton<SavePhotoFromPath>(
        () => SavePhotoFromPath(photoRepo),
      );
      serviceLocator.registerLazySingleton<EvidenceRepositoryPort>(
        () => evidenceRepo,
      );
      serviceLocator.registerLazySingleton<SaveEvidenceEntry>(
        () => SaveEvidenceEntry(evidenceRepo),
      );
      serviceLocator.registerLazySingleton<DeleteEvidenceEntry>(
        () => DeleteEvidenceEntry(evidenceRepo),
      );
      serviceLocator.registerLazySingleton<CaptureCoordinator>(
        () => coordinator,
      );
    });

    tearDown(() {
      if (serviceLocator.isRegistered<PhotoCubit>()) {
        serviceLocator.unregister<PhotoCubit>();
      }
      if (serviceLocator.isRegistered<SavePhotoFromPath>()) {
        serviceLocator.unregister<SavePhotoFromPath>();
      }
      if (serviceLocator.isRegistered<EvidenceRepositoryPort>()) {
        serviceLocator.unregister<EvidenceRepositoryPort>();
      }
      if (serviceLocator.isRegistered<SaveEvidenceEntry>()) {
        serviceLocator.unregister<SaveEvidenceEntry>();
      }
      if (serviceLocator.isRegistered<DeleteEvidenceEntry>()) {
        serviceLocator.unregister<DeleteEvidenceEntry>();
      }
      if (serviceLocator.isRegistered<CaptureCoordinator>()) {
        serviceLocator.unregister<CaptureCoordinator>();
      }
    });

    testWidgets('照片采集崩溃恢复协调：打开归档对话框并成功保存', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      // 准备处于 pickerActive 状态的照片草稿
      final draft = CaptureDraft.create(
        taskId: 'photo_task_1',
        ownerContext: owner,
        purpose: CapturePurpose.photo,
        draftValues: const {'projectName': '港珠澳大桥'},
        state: CaptureState.pickerActive,
      );
      await journalPort.writeDraft(draft);
      acquisitionPort.lostData = ['/camera/lost_bridge.jpg'];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('主界面')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 执行恢复
      await recoverLostCaptureData(
        navigatorKey,
        coordinator: coordinator,
        currentOwner: owner,
      );
      await tester.pumpAndSettle();

      // 验证照片归档对话框已弹出
      expect(find.text('归档照片'), findsOneWidget);
      expect(find.text('港珠澳大桥'), findsOneWidget);

      // 点击确认保存
      await tester.tap(find.text('确认录入'));
      await tester.pumpAndSettle();

      // 验证草稿已被提交并完成
      final savedDraft = await journalPort.readDraft('photo_task_1');
      expect(savedDraft?.state, CaptureState.committed);
    });

    testWidgets('新增凭证崩溃恢复协调：打开新增凭证编辑器 (existing == null)', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      final draft = CaptureDraft.create(
        taskId: 'evidence_task_new',
        ownerContext: owner,
        purpose: CapturePurpose.evidence,
        draftValues: const {'projectName': '办公用品采购'},
        state: CaptureState.pickerActive,
      );
      await journalPort.writeDraft(draft);
      acquisitionPort.lostData = ['/camera/receipt_new.jpg'];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('主界面')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await recoverLostCaptureData(
        navigatorKey,
        coordinator: coordinator,
        currentOwner: owner,
      );
      await tester.pumpAndSettle();

      // 验证以新增模式打开凭证编辑器（标题为添加凭证）
      expect(find.byType(EvidenceEditorSheet), findsOneWidget);
      expect(find.text('添加凭证'), findsOneWidget);
      expect(find.text('办公用品采购'), findsOneWidget);
    });

    testWidgets('已有凭证编辑崩溃恢复协调：以已有记录模式打开 (彻底闭环 U290)', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      // 预先向 evidenceRepo 注册待编辑的原记录 ID: 290
      final originalEvidence = EvidenceEntry(
        id: 290,
        projectName: 'U290修复验证项目',
        evidenceDate: DateTime(2026, 6, 20),
        amount: 888.5,
        merchant: '苹果专卖店',
        note: '原凭证备注信息',
      );
      await evidenceRepo.saveEntry(originalEvidence, markDirty: false);

      // 准备带有 editTargetId: 290 的凭证草稿
      final draft = CaptureDraft.create(
        taskId: 'evidence_task_edit',
        ownerContext: owner,
        purpose: CapturePurpose.evidence,
        editTargetId: 290,
        draftValues: const {'projectName': 'U290修复验证项目'},
        state: CaptureState.pickerActive,
      );
      await journalPort.writeDraft(draft);
      acquisitionPort.lostData = ['/camera/receipt_replacement.jpg'];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('主界面')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await recoverLostCaptureData(
        navigatorKey,
        coordinator: coordinator,
        currentOwner: owner,
      );
      await tester.pumpAndSettle();

      // 验证已通过原有凭证 290 编辑模式打开（标题为编辑凭证，保留了原记录信息）
      expect(find.byType(EvidenceEditorSheet), findsOneWidget);
      expect(find.text('编辑凭证'), findsOneWidget);
      expect(find.text('苹果专卖店'), findsOneWidget);
      expect(find.text('888.5'), findsOneWidget);
      expect(find.text('原凭证备注信息'), findsOneWidget);
    });

    testWidgets('多账号隔离保护：不同用户或纪元时不跨账号恢复', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      // 准备归属于 user_other 的草稿
      const otherOwner = CaptureOwnerContext(
        ownerUserId: 'user_other',
        sessionEpoch: 1,
      );
      final draft = CaptureDraft.create(
        taskId: 'photo_task_other_user',
        ownerContext: otherOwner,
        purpose: CapturePurpose.photo,
        state: CaptureState.pickerActive,
      );
      await journalPort.writeDraft(draft);
      acquisitionPort.lostData = ['/camera/secret_photo.jpg'];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('主界面')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 当前环境使用 owner (test_user)，期望不恢复也不弹窗
      await recoverLostCaptureData(
        navigatorKey,
        coordinator: coordinator,
        currentOwner: owner,
      );
      await tester.pumpAndSettle();

      expect(find.text('归档照片'), findsNothing);
      expect(find.byType(EvidenceEditorSheet), findsNothing);

      // 验证草稿已被置为 recoverableFailure 隔离
      final isolatedDraft = await journalPort.readDraft(
        'photo_task_other_user',
      );
      expect(isolatedDraft?.state, CaptureState.recoverableFailure);
    });
  });
}
