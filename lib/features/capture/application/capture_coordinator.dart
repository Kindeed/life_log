import 'dart:async';

import 'package:life_log/common/utils/sync_id_generator.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';

/// 异步串行互斥锁，确保临界区操作按调用顺序排队执行。
class _AsyncLock {
  Future<void>? _lastOperation;

  Future<T> synchronized<T>(Future<T> Function() action) {
    final previous = _lastOperation;
    final completer = Completer<void>();
    _lastOperation = completer.future;

    return Future.sync(() async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      return await action();
    }).whenComplete(() {
      completer.complete();
    });
  }
}

/// 采集协议应用层协调器。
///
/// 串联驱动草稿日志（[CaptureJournalPort]）、沙箱暂存（[StagingPort]）、
/// 设备采集（[AcquisitionPort]）与落库提交（[CommitPort]），
/// 维护采集生命周期状态机推进、系统杀死恢复、账户隔离与幂等提交。
class CaptureCoordinator {
  final CaptureJournalPort _journalPort;
  final StagingPort _stagingPort;
  final AcquisitionPort _acquisitionPort;
  final CommitPort _commitPort;
  final String Function() _idGenerator;

  final _AsyncLock _recoveryLock = _AsyncLock();

  CaptureCoordinator({
    required CaptureJournalPort journalPort,
    required StagingPort stagingPort,
    required AcquisitionPort acquisitionPort,
    required CommitPort commitPort,
    String Function()? idGenerator,
  }) : _journalPort = journalPort,
       _stagingPort = stagingPort,
       _acquisitionPort = acquisitionPort,
       _commitPort = commitPort,
       _idGenerator = idGenerator ?? SyncIdGenerator.newSyncId;

  /// 初始化采集任务草稿。
  ///
  /// 生成全局唯一 [taskId] (UUID)，将状态初始化为 [CaptureState.prepared]，
  /// 并持久化写入草稿日志。
  Future<CaptureDraft> prepare({
    required CapturePurpose purpose,
    required CaptureOwnerContext ownerContext,
    int? projectLocalId,
    int? editTargetId,
    Map<String, dynamic> initialDraftValues = const {},
  }) async {
    final taskId = _idGenerator();
    final draft = CaptureDraft.create(
      taskId: taskId,
      ownerContext: ownerContext,
      purpose: purpose,
      projectLocalId: projectLocalId,
      editTargetId: editTargetId,
      draftValues: initialDraftValues,
      state: CaptureState.prepared,
      revision: 1,
    );

    await _journalPort.writeDraft(draft);
    return draft;
  }

  /// 调起设备采集（相机拍照或相册选择）。
  ///
  /// 1. 读取草稿并迁移状态为 [CaptureState.pickerActive]，写入 Journal；
  /// 2. 调用 [AcquisitionPort.acquireMedia] 调起系统采集；
  /// 3. 若用户取消（返回 null），迁移状态为 [CaptureState.cancelled] 并清理沙箱暂存；
  /// 4. 若采集成功，调用 [StagingPort.stageFile] 存入沙箱私有目录，
  ///    迁移状态为 [CaptureState.staged] 并写入 Journal。
  Future<CaptureDraft> startAcquisition(
    String taskId, {
    required bool isCamera,
  }) async {
    final draft = await _journalPort.readDraft(taskId);
    if (draft == null) {
      throw StateError('Capture draft not found for taskId: $taskId');
    }

    final activeDraft = draft.transitionTo(CaptureState.pickerActive);
    await _journalPort.writeDraft(activeDraft);

    final source = isCamera
        ? AcquisitionSource.camera
        : AcquisitionSource.gallery;

    try {
      final rawPath = await _acquisitionPort.acquireMedia(
        taskId: taskId,
        source: source,
      );

      if (rawPath == null) {
        final cancelledDraft = activeDraft.transitionTo(CaptureState.cancelled);
        await _journalPort.writeDraft(cancelledDraft);
        await _stagingPort.clearTaskStaging(taskId);
        return cancelledDraft;
      }

      final stagedPath = await _stagingPort.stageFile(
        taskId: taskId,
        sourcePath: rawPath,
        purpose: activeDraft.purpose,
      );

      final stagedDraft = activeDraft.transitionTo(
        CaptureState.staged,
        stagedPaths: [...activeDraft.stagedPaths, stagedPath],
      );
      await _journalPort.writeDraft(stagedDraft);
      return stagedDraft;
    } catch (e) {
      if (activeDraft.canTransitionTo(CaptureState.recoverableFailure)) {
        try {
          final failureDraft = activeDraft.transitionTo(
            CaptureState.recoverableFailure,
            failureReason: e.toString(),
          );
          await _journalPort.writeDraft(failureDraft);
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// 检索因系统杀死遗失的相机采集结果并恢复草稿。
  ///
  /// 1. 全局互斥串行调用 [AcquisitionPort.retrieveLostData]；
  /// 2. 若无遗失数据则直接返回空列表；
  /// 3. 若存在遗失数据，查询所有处于 [CaptureState.pickerActive] 或 [CaptureState.prepared]
  ///    的活跃草稿；
  /// 4. 若草稿 [ownerContext] 与 [currentOwner] 匹配，暂存至沙箱并迁移至 [CaptureState.staged]；
  /// 5. 若发生账号不匹配，绝不交叉合并，将其隔离置为 [CaptureState.recoverableFailure]
  ///    待原所有者重新登录后处理。
  Future<List<CaptureDraft>> recoverLostData(CaptureOwnerContext currentOwner) {
    return _recoveryLock.synchronized(() async {
      final lostFiles = await _acquisitionPort.retrieveLostData();
      if (lostFiles.isEmpty) {
        return const [];
      }

      final activeDrafts = await _journalPort.listActiveDrafts();
      final candidates = activeDrafts.where((d) {
        return d.state == CaptureState.pickerActive ||
            d.state == CaptureState.prepared;
      }).toList();

      if (candidates.isEmpty) {
        return const [];
      }

      final recovered = <CaptureDraft>[];

      for (final draft in candidates) {
        if (!draft.ownerContext.matches(currentOwner)) {
          // 账号切换不匹配，不进行交叉合并，置为 recoverableFailure
          final failedDraft = draft.transitionTo(
            CaptureState.recoverableFailure,
            failureReason:
                'Owner context mismatch during recovery: draft owner '
                '(${draft.ownerContext.ownerUserId}) does not match current owner '
                '(${currentOwner.ownerUserId}).',
          );
          await _journalPort.writeDraft(failedDraft);
          continue;
        }

        // 所有者匹配，暂存至任务沙箱并推进至 staged
        final stagedPaths = <String>[];
        for (final file in lostFiles) {
          final staged = await _stagingPort.stageFile(
            taskId: draft.taskId,
            sourcePath: file,
            purpose: draft.purpose,
          );
          stagedPaths.add(staged);
        }

        final stagedDraft = draft.transitionTo(
          CaptureState.staged,
          stagedPaths: [...draft.stagedPaths, ...stagedPaths],
        );
        await _journalPort.writeDraft(stagedDraft);
        recovered.add(stagedDraft);
      }

      return recovered;
    });
  }

  /// 更新草稿表单数据，迁移状态为 [CaptureState.editing]。
  Future<CaptureDraft> updateDraftValues(
    String taskId,
    CaptureOwnerContext owner,
    Map<String, dynamic> newValues,
  ) async {
    final draft = await _journalPort.readDraft(taskId);
    if (draft == null) {
      throw StateError('Capture draft not found for taskId: $taskId');
    }
    if (!draft.ownerContext.matches(owner)) {
      throw StateError(
        'Owner context mismatch for taskId: $taskId. '
        'Expected ${draft.ownerContext}, got $owner',
      );
    }

    final updatedValues = Map<String, dynamic>.from(draft.draftValues)
      ..addAll(newValues);

    int? projectLocalId = draft.projectLocalId;
    if (newValues.containsKey('projectLocalId')) {
      projectLocalId = (newValues['projectLocalId'] as num?)?.toInt();
    }

    int? editTargetId = draft.editTargetId;
    if (newValues.containsKey('editTargetId')) {
      editTargetId = (newValues['editTargetId'] as num?)?.toInt();
    }

    final updatedDraft = draft.transitionTo(
      CaptureState.editing,
      draftValues: updatedValues,
      projectLocalId: projectLocalId,
      editTargetId: editTargetId,
    );

    await _journalPort.writeDraft(updatedDraft);
    return updatedDraft;
  }

  /// 提交草稿入库持久化。
  ///
  /// 1. 幂等性保障：先调用 [CommitPort.findCommitted]，若已存在提交记录，
  ///    直接标记 [CaptureState.committed]、清理沙箱暂存并返回已有结果；
  /// 2. 若未提交，迁移状态为 [CaptureState.committing]，调用 [CommitPort.commit]；
  /// 3. 提交成功后迁移为 [CaptureState.committed]，调用 [StagingPort.clearTaskStaging]；
  /// 4. 若落库失败，草稿降级迁移至 [CaptureState.recoverableFailure] 并记录原因，
  ///    沙箱文件安全保留不清理。
  Future<CommitResult> commit(String taskId, CaptureOwnerContext owner) async {
    final draft = await _journalPort.readDraft(taskId);
    if (draft == null) {
      throw StateError('Capture draft not found for taskId: $taskId');
    }
    if (!draft.ownerContext.matches(owner)) {
      throw StateError(
        'Owner context mismatch for taskId: $taskId. '
        'Expected ${draft.ownerContext}, got $owner',
      );
    }

    // 1. 幂等性保障
    final existing = await _commitPort.findCommitted(taskId, owner);
    if (existing != null) {
      if (draft.state != CaptureState.committed) {
        final committedDraft = draft.copyWith(
          state: CaptureState.committed,
          revision: draft.revision + 1,
          updatedAt: DateTime.now(),
        );
        await _journalPort.writeDraft(committedDraft);
      }
      await _stagingPort.clearTaskStaging(taskId);
      return existing;
    }

    // 2. 推进至 committing
    final committingDraft = draft.transitionTo(CaptureState.committing);
    await _journalPort.writeDraft(committingDraft);

    // 3. 执行落库
    try {
      final result = await _commitPort.commit(committingDraft);
      final committedDraft = committingDraft.transitionTo(
        CaptureState.committed,
      );
      await _journalPort.writeDraft(committedDraft);
      await _stagingPort.clearTaskStaging(taskId);
      return result;
    } catch (e) {
      // 4. 落库失败降级，保留沙箱文件以备重试或恢复
      final failureDraft = committingDraft.transitionTo(
        CaptureState.recoverableFailure,
        failureReason: e.toString(),
      );
      await _journalPort.writeDraft(failureDraft);
      rethrow;
    }
  }

  /// 主动放弃或取消采集任务。
  ///
  /// 将草稿迁移至 [CaptureState.cancelled] 并清理沙箱暂存文件。
  Future<void> abandon(String taskId, CaptureOwnerContext owner) async {
    final draft = await _journalPort.readDraft(taskId);
    if (draft == null) {
      throw StateError('Capture draft not found for taskId: $taskId');
    }
    if (!draft.ownerContext.matches(owner)) {
      throw StateError(
        'Owner context mismatch for taskId: $taskId. '
        'Expected ${draft.ownerContext}, got $owner',
      );
    }

    if (draft.state != CaptureState.cancelled) {
      final cancelledDraft = draft.transitionTo(CaptureState.cancelled);
      await _journalPort.writeDraft(cancelledDraft);
    }

    await _stagingPort.clearTaskStaging(taskId);
  }

  /// 读取单个采集草稿。
  Future<CaptureDraft?> getDraft(String taskId) =>
      _journalPort.readDraft(taskId);

  /// 列出当前所有活跃草稿。
  Future<List<CaptureDraft>> listActiveDrafts({String? ownerUserId}) =>
      _journalPort.listActiveDrafts(ownerUserId: ownerUserId);
}
