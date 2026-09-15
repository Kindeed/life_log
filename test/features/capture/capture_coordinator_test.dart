import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/capture/application/capture_coordinator.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';

/// 内存版草稿日志 Fake 实现，具备与生产级一致的 CAS 乐观锁版本校验。
class FakeCaptureJournalPort implements CaptureJournalPort {
  final Map<String, CaptureDraft> drafts = {};
  int writeCount = 0;

  @override
  Future<void> writeDraft(CaptureDraft draft) async {
    writeCount++;
    final existing = drafts[draft.taskId];
    if (existing == null) {
      if (draft.revision != 1) {
        throw CaptureCasConflictException(
          taskId: draft.taskId,
          expectedRevision: draft.revision - 1,
          actualRevision: null,
          message:
              'Cannot create draft with revision ${draft.revision}, expected 1.',
        );
      }
    } else {
      if (draft.revision != existing.revision + 1) {
        throw CaptureCasConflictException(
          taskId: draft.taskId,
          expectedRevision: draft.revision - 1,
          actualRevision: existing.revision,
          message:
              'CAS mismatch: expected ${draft.revision - 1}, actual ${existing.revision}.',
        );
      }
    }
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

/// 内存版沙箱暂存 Fake 实现。
class FakeStagingPort implements StagingPort {
  final Map<String, List<String>> stagedByTask = {};
  int stageCount = 0;
  int clearCount = 0;

  @override
  Future<String> stageFile({
    required String taskId,
    required String sourcePath,
    CapturePurpose? purpose,
  }) async {
    stageCount++;
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
      final staged = await stageFile(
        taskId: taskId,
        sourcePath: path,
        purpose: purpose,
      );
      result.add(staged);
    }
    return result;
  }

  @override
  Future<List<String>> getStagedFiles(String taskId) async {
    return List.unmodifiable(stagedByTask[taskId] ?? const []);
  }

  @override
  Future<void> clearTaskStaging(String taskId) async {
    clearCount++;
    stagedByTask.remove(taskId);
  }

  @override
  Future<void> removeStagedFile(String stagedPath) async {
    for (final list in stagedByTask.values) {
      list.remove(stagedPath);
    }
  }
}

/// 内存版设备采集 Fake 实现。
class FakeAcquisitionPort implements AcquisitionPort {
  bool isSessionActiveValue = false;
  String? acquireResult;
  List<String> lostData = [];
  int acquireCallCount = 0;
  int retrieveCallCount = 0;
  int releaseCallCount = 0;

  @override
  bool get isSessionActive => isSessionActiveValue;

  @override
  Future<String?> acquireMedia({
    required String taskId,
    required AcquisitionSource source,
  }) async {
    acquireCallCount++;
    isSessionActiveValue = true;
    try {
      return acquireResult;
    } finally {
      isSessionActiveValue = false;
    }
  }

  @override
  Future<List<String>> retrieveLostData() async {
    retrieveCallCount++;
    final result = List<String>.from(lostData);
    lostData.clear();
    return result;
  }

  @override
  Future<void> releaseSession({required String taskId}) async {
    releaseCallCount++;
    isSessionActiveValue = false;
  }
}

/// 内存版提交落库 Fake 实现。
class FakeCommitPort implements CommitPort {
  final Map<String, CommitResult> committedMap = {};
  int commitCallCount = 0;
  int findCommittedCallCount = 0;
  bool shouldThrowOnCommit = false;
  Object? errorToThrow;
  int nextCommittedId = 100;

  @override
  Future<CommitResult> commit(CaptureDraft draft) async {
    commitCallCount++;
    if (shouldThrowOnCommit) {
      throw errorToThrow ??
          CaptureCommitException(
            taskId: draft.taskId,
            message: 'Database insertion failed during commit.',
          );
    }
    final result = CommitResult(
      taskId: draft.taskId,
      purpose: draft.purpose,
      committedId: nextCommittedId++,
      committedAt: DateTime.now(),
      metadata: Map<String, dynamic>.from(draft.draftValues),
    );
    committedMap['${draft.taskId}:${draft.ownerContext.ownerUserId}'] = result;
    return result;
  }

  @override
  Future<CommitResult?> findCommitted(
    String taskId,
    CaptureOwnerContext owner,
  ) async {
    findCommittedCallCount++;
    return committedMap['$taskId:${owner.ownerUserId}'];
  }
}

void main() {
  late FakeCaptureJournalPort journalPort;
  late FakeStagingPort stagingPort;
  late FakeAcquisitionPort acquisitionPort;
  late FakeCommitPort commitPort;
  late CaptureCoordinator coordinator;

  const ownerA = CaptureOwnerContext(ownerUserId: 'user_a', sessionEpoch: 1);
  const ownerB = CaptureOwnerContext(ownerUserId: 'user_b', sessionEpoch: 1);

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
  });

  group('CaptureCoordinator - 完整生命周期正向流程', () {
    test(
      'prepare -> startAcquisition -> updateDraftValues -> commit',
      () async {
        // 1. prepare
        final draft = await coordinator.prepare(
          purpose: CapturePurpose.photo,
          ownerContext: ownerA,
          projectLocalId: 42,
          initialDraftValues: {'remark': '初始现场拍照'},
        );

        expect(draft.taskId, isNotEmpty);
        expect(draft.state, CaptureState.prepared);
        expect(draft.revision, 1);
        expect(draft.purpose, CapturePurpose.photo);
        expect(draft.projectLocalId, 42);
        expect(draft.draftValues['remark'], '初始现场拍照');

        final journalDraft1 = await journalPort.readDraft(draft.taskId);
        expect(journalDraft1, isNotNull);
        expect(journalDraft1!.state, CaptureState.prepared);

        // 2. startAcquisition (使用相机)
        acquisitionPort.acquireResult = '/camera/raw_capture.jpg';
        final stagedDraft = await coordinator.startAcquisition(
          draft.taskId,
          isCamera: true,
        );

        expect(stagedDraft.state, CaptureState.staged);
        expect(stagedDraft.stagedPaths, hasLength(1));
        expect(
          stagedDraft.stagedPaths.first,
          '/sandbox/${draft.taskId}/raw_capture.jpg',
        );
        // prepared (rev 1) -> pickerActive (rev 2) -> staged (rev 3)
        expect(stagedDraft.revision, 3);

        final stagedFiles = await stagingPort.getStagedFiles(draft.taskId);
        expect(stagedFiles, hasLength(1));

        // 3. updateDraftValues
        final editedDraft = await coordinator.updateDraftValues(
          draft.taskId,
          ownerA,
          {'title': '基坑安全检查', 'severity': 'high'},
        );

        expect(editedDraft.state, CaptureState.editing);
        expect(editedDraft.draftValues['remark'], '初始现场拍照');
        expect(editedDraft.draftValues['title'], '基坑安全检查');
        expect(editedDraft.draftValues['severity'], 'high');
        expect(editedDraft.revision, 4);

        // 4. commit
        final commitResult = await coordinator.commit(draft.taskId, ownerA);

        expect(commitResult.taskId, draft.taskId);
        expect(commitResult.committedId, 100);
        expect(commitPort.commitCallCount, 1);
        expect(commitPort.findCommittedCallCount, 1);

        // 验证最终状态为 committed 且暂存区已清空
        final finalDraft = await journalPort.readDraft(draft.taskId);
        expect(finalDraft!.state, CaptureState.committed);
        // editing (rev 4) -> committing (rev 5) -> committed (rev 6)
        expect(finalDraft.revision, 6);

        final remainingStaged = await stagingPort.getStagedFiles(draft.taskId);
        expect(remainingStaged, isEmpty);
        expect(stagingPort.clearCount, 1);
      },
    );
  });

  group('CaptureCoordinator - 相机取消流程', () {
    test('用户在系统相机中取消 (返回 null) -> 自动迁移为 cancelled 且清理沙箱', () async {
      final draft = await coordinator.prepare(
        purpose: CapturePurpose.evidence,
        ownerContext: ownerA,
      );

      // 模拟相机返回 null (用户点击返回/取消)
      acquisitionPort.acquireResult = null;

      final cancelledDraft = await coordinator.startAcquisition(
        draft.taskId,
        isCamera: true,
      );

      expect(cancelledDraft.state, CaptureState.cancelled);
      // prepared (rev 1) -> pickerActive (rev 2) -> cancelled (rev 3)
      expect(cancelledDraft.revision, 3);

      final journalDraft = await journalPort.readDraft(draft.taskId);
      expect(journalDraft!.state, CaptureState.cancelled);

      // 沙箱暂存区必须被清理
      final stagedFiles = await stagingPort.getStagedFiles(draft.taskId);
      expect(stagedFiles, isEmpty);
      expect(stagingPort.clearCount, 1);
    });
  });

  group('CaptureCoordinator - 系统杀死恢复 (recoverLostData)', () {
    test(
      '存在 pickerActive 任务，进程重启后调用 recoverLostData 成功补全暂存并恢复至 staged',
      () async {
        // 模拟进程杀死前遗留的草稿：任务处于 pickerActive
        final activeDraft = CaptureDraft.create(
          taskId: 'killed_task_001',
          ownerContext: ownerA,
          purpose: CapturePurpose.photo,
          projectLocalId: 5,
          state: CaptureState.pickerActive,
          revision: 1,
        );
        await journalPort.writeDraft(activeDraft);

        // 模拟 Android Activity 恢复时 AcquisitionPort 检索到丢失的文件
        acquisitionPort.lostData = ['/lost_dir/lost_photo_123.jpg'];

        final recovered = await coordinator.recoverLostData(ownerA);

        expect(recovered, hasLength(1));
        expect(recovered.first.taskId, 'killed_task_001');
        expect(recovered.first.state, CaptureState.staged);
        expect(recovered.first.stagedPaths, [
          '/sandbox/killed_task_001/lost_photo_123.jpg',
        ]);
        expect(recovered.first.revision, 2);

        // 验证 Journal 中也已同步为 staged
        final journalDraft = await journalPort.readDraft('killed_task_001');
        expect(journalDraft!.state, CaptureState.staged);

        // 验证沙箱中有对应文件
        final stagedFiles = await stagingPort.getStagedFiles('killed_task_001');
        expect(stagedFiles, hasLength(1));
      },
    );

    test('账号不匹配时隔离挂起为 recoverableFailure，防止交叉写入', () async {
      // 模拟 user_a 遗留的 pickerActive 任务
      final userADraft = CaptureDraft.create(
        taskId: 'user_a_task',
        ownerContext: ownerA,
        purpose: CapturePurpose.evidence,
        state: CaptureState.pickerActive,
        revision: 1,
      );
      await journalPort.writeDraft(userADraft);

      // 系统中检索到遗失文件
      acquisitionPort.lostData = ['/lost_dir/camera_snap.jpg'];

      // 当前登录用户已切换为 user_b
      final recovered = await coordinator.recoverLostData(ownerB);

      // 不对 user_b 返回任何 user_a 的草稿
      expect(recovered, isEmpty);

      // user_a 的草稿必须被安全置为 recoverableFailure，待原所有者登录后处理
      final updatedUserADraft = await journalPort.readDraft('user_a_task');
      expect(updatedUserADraft, isNotNull);
      expect(updatedUserADraft!.state, CaptureState.recoverableFailure);
      expect(
        updatedUserADraft.failureReason,
        contains('Owner context mismatch'),
      );
      expect(updatedUserADraft.stagedPaths, isEmpty);

      // 沙箱中绝不交叉写入 user_a 的 task 目录
      final staged = await stagingPort.getStagedFiles('user_a_task');
      expect(staged, isEmpty);
    });

    test('无遗失数据时返回空列表且不修改活跃草稿', () async {
      final activeDraft = CaptureDraft.create(
        taskId: 'active_task',
        ownerContext: ownerA,
        purpose: CapturePurpose.photo,
        state: CaptureState.pickerActive,
        revision: 1,
      );
      await journalPort.writeDraft(activeDraft);

      acquisitionPort.lostData = [];

      final recovered = await coordinator.recoverLostData(ownerA);
      expect(recovered, isEmpty);

      final reloaded = await journalPort.readDraft('active_task');
      expect(reloaded!.state, CaptureState.pickerActive);
    });
  });

  group('CaptureCoordinator - 幂等性提交', () {
    test('若 CommitPort.findCommitted 返回已成功记录，则直接返回，不重复调用 commit', () async {
      final draft = await coordinator.prepare(
        purpose: CapturePurpose.evidence,
        ownerContext: ownerA,
      );

      // 预先模拟已成功入库的结果（例如之前提交落库成功但客户端网络/状态更新中断）
      final existingResult = CommitResult(
        taskId: draft.taskId,
        purpose: CapturePurpose.evidence,
        committedId: 888,
        committedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        metadata: const {'preCommitted': true},
      );
      commitPort.committedMap['${draft.taskId}:${ownerA.ownerUserId}'] =
          existingResult;

      // 执行提交
      final result = await coordinator.commit(draft.taskId, ownerA);

      expect(result.committedId, 888);
      expect(result.metadata['preCommitted'], true);
      // 核心断言：绝不重复调用 commit()
      expect(commitPort.commitCallCount, 0);
      expect(commitPort.findCommittedCallCount, 1);

      // 草稿被标记为 committed
      final updatedDraft = await journalPort.readDraft(draft.taskId);
      expect(updatedDraft!.state, CaptureState.committed);

      // 沙箱暂存必须被清理
      expect(stagingPort.clearCount, 1);
    });
  });

  group('CaptureCoordinator - 落库异常降级', () {
    test(
      'CommitPort.commit 抛出异常，草稿被安全置为 recoverableFailure，文件保留在暂存区不丢失',
      () async {
        final draft = await coordinator.prepare(
          purpose: CapturePurpose.photo,
          ownerContext: ownerA,
        );

        acquisitionPort.acquireResult = '/camera/photo_urgent.jpg';
        await coordinator.startAcquisition(draft.taskId, isCamera: true);

        // 配置 CommitPort 抛出数据库写入异常
        commitPort.shouldThrowOnCommit = true;
        commitPort.errorToThrow = const CaptureCommitException(
          taskId: 'any',
          message: 'Disk I/O error or SQLite locked.',
        );

        // 执行 commit，预期抛出异常
        await expectLater(
          () => coordinator.commit(draft.taskId, ownerA),
          throwsA(isA<CaptureCommitException>()),
        );

        // 验证草稿安全降级为 recoverableFailure
        final failedDraft = await journalPort.readDraft(draft.taskId);
        expect(failedDraft, isNotNull);
        expect(failedDraft!.state, CaptureState.recoverableFailure);
        expect(failedDraft.failureReason, contains('SQLite locked'));

        // 关键约束：暂存区文件绝对不能被清理，保障数据不丢失
        final stagedFiles = await stagingPort.getStagedFiles(draft.taskId);
        expect(stagedFiles, hasLength(1));
        expect(stagingPort.clearCount, 0);
      },
    );
  });

  group('CaptureCoordinator - 主动放弃 (abandon)', () {
    test('abandon 迁移状态为 cancelled 并清理沙箱暂存', () async {
      final draft = await coordinator.prepare(
        purpose: CapturePurpose.photo,
        ownerContext: ownerA,
      );

      acquisitionPort.acquireResult = '/camera/abandon_me.jpg';
      await coordinator.startAcquisition(draft.taskId, isCamera: true);

      final stagedBefore = await stagingPort.getStagedFiles(draft.taskId);
      expect(stagedBefore, hasLength(1));

      // 执行 abandon
      await coordinator.abandon(draft.taskId, ownerA);

      final cancelledDraft = await journalPort.readDraft(draft.taskId);
      expect(cancelledDraft!.state, CaptureState.cancelled);

      final stagedAfter = await stagingPort.getStagedFiles(draft.taskId);
      expect(stagedAfter, isEmpty);
      expect(stagingPort.clearCount, 1);
    });
  });

  group('CaptureCoordinator - 所有者安全校验', () {
    test('非草稿所有者调用 updateDraftValues 抛出 StateError', () async {
      final draft = await coordinator.prepare(
        purpose: CapturePurpose.photo,
        ownerContext: ownerA,
      );

      await expectLater(
        () =>
            coordinator.updateDraftValues(draft.taskId, ownerB, {'foo': 'bar'}),
        throwsStateError,
      );
    });

    test('非草稿所有者调用 commit 抛出 StateError', () async {
      final draft = await coordinator.prepare(
        purpose: CapturePurpose.photo,
        ownerContext: ownerA,
      );

      await expectLater(
        () => coordinator.commit(draft.taskId, ownerB),
        throwsStateError,
      );
    });

    test('非草稿所有者调用 abandon 抛出 StateError', () async {
      final draft = await coordinator.prepare(
        purpose: CapturePurpose.photo,
        ownerContext: ownerA,
      );

      await expectLater(
        () => coordinator.abandon(draft.taskId, ownerB),
        throwsStateError,
      );
    });
  });
}
