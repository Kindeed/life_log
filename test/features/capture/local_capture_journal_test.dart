import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/capture/data/local_capture_journal.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';

void main() {
  late Directory tempDir;
  late LocalCaptureJournal journal;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('capture_journal_test_');
    journal = LocalCaptureJournal(tempDir);
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('LocalCaptureJournal - 基础写入与读取', () {
    test('正常写入首版草稿、读取及更新', () async {
      final draft = CaptureDraft.create(
        taskId: 'task_001',
        ownerContext: const CaptureOwnerContext(
          ownerUserId: 'user_a',
          sessionEpoch: 1,
        ),
        purpose: CapturePurpose.photo,
        projectLocalId: 10,
        draftValues: const {'title': '测试草稿'},
        stagedPaths: const ['/tmp/photo1.jpg'],
      );

      // 1. 写入首版 (revision = 1)
      await journal.writeDraft(draft);

      // 2. 读取验证
      final loaded = await journal.readDraft('task_001');
      expect(loaded, isNotNull);
      expect(loaded!.taskId, 'task_001');
      expect(loaded.ownerContext.ownerUserId, 'user_a');
      expect(loaded.ownerContext.sessionEpoch, 1);
      expect(loaded.purpose, CapturePurpose.photo);
      expect(loaded.projectLocalId, 10);
      expect(loaded.draftValues, {'title': '测试草稿'});
      expect(loaded.stagedPaths, ['/tmp/photo1.jpg']);
      expect(loaded.state, CaptureState.prepared);
      expect(loaded.revision, 1);

      // 3. 更新至 revision = 2
      final updated = draft.transitionTo(
        CaptureState.pickerActive,
        draftValues: const {'title': '更新后的草稿'},
      );
      expect(updated.revision, 2);
      await journal.writeDraft(updated);

      final loadedUpdated = await journal.readDraft('task_001');
      expect(loadedUpdated, isNotNull);
      expect(loadedUpdated!.state, CaptureState.pickerActive);
      expect(loadedUpdated.revision, 2);
      expect(loadedUpdated.draftValues['title'], '更新后的草稿');

      // 4. 删除草稿
      await journal.removeDraft('task_001');
      final afterDelete = await journal.readDraft('task_001');
      expect(afterDelete, isNull);
    });

    test('读取不存在的草稿返回 null', () async {
      final loaded = await journal.readDraft('non_existent_task');
      expect(loaded, isNull);
    });

    test('移除不存在的草稿保持幂等无异常', () async {
      await expectLater(journal.removeDraft('non_existent_task'), completes);
    });
  });

  group('LocalCaptureJournal - CAS 乐观并发冲突校验', () {
    test('新增未存在的草稿但 revision != 1 抛出 CaptureCasConflictException', () async {
      final invalidInitialDraft = CaptureDraft.create(
        taskId: 'task_cas_1',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.evidence,
        revision: 2,
      );

      expect(
        () => journal.writeDraft(invalidInitialDraft),
        throwsA(
          isA<CaptureCasConflictException>()
              .having((e) => e.taskId, 'taskId', 'task_cas_1')
              .having((e) => e.actualRevision, 'actualRevision', isNull)
              .having((e) => e.expectedRevision, 'expectedRevision', 1),
        ),
      );
    });

    test('既有草稿已存在时再次写入 revision = 1 抛出 CaptureCasConflictException', () async {
      final initialDraft = CaptureDraft.create(
        taskId: 'task_cas_2',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
      );
      await journal.writeDraft(initialDraft);

      // 试图再次以 revision = 1 写入相同 taskId
      final duplicateInitialDraft = CaptureDraft.create(
        taskId: 'task_cas_2',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
      );

      expect(
        () => journal.writeDraft(duplicateInitialDraft),
        throwsA(
          isA<CaptureCasConflictException>()
              .having((e) => e.taskId, 'taskId', 'task_cas_2')
              .having((e) => e.actualRevision, 'actualRevision', 1),
        ),
      );
    });

    test('更新时版本跳跃（例如当前为 1，直接提交 3）抛出 CaptureCasConflictException', () async {
      final initialDraft = CaptureDraft.create(
        taskId: 'task_cas_3',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
      );
      await journal.writeDraft(initialDraft);

      final jumpDraft = initialDraft.copyWith(revision: 3);

      expect(
        () => journal.writeDraft(jumpDraft),
        throwsA(
          isA<CaptureCasConflictException>()
              .having((e) => e.taskId, 'taskId', 'task_cas_3')
              .having((e) => e.expectedRevision, 'expectedRevision', 2)
              .having((e) => e.actualRevision, 'actualRevision', 1),
        ),
      );
    });

    test('更新时版本过旧（例如当前为 2，重复提交 2）抛出 CaptureCasConflictException', () async {
      final initialDraft = CaptureDraft.create(
        taskId: 'task_cas_4',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
      );
      await journal.writeDraft(initialDraft);

      final updatedDraft = initialDraft.transitionTo(CaptureState.pickerActive);
      expect(updatedDraft.revision, 2);
      await journal.writeDraft(updatedDraft);

      // 再次提交相同的 revision 2
      expect(
        () => journal.writeDraft(updatedDraft),
        throwsA(
          isA<CaptureCasConflictException>()
              .having((e) => e.taskId, 'taskId', 'task_cas_4')
              .having((e) => e.expectedRevision, 'expectedRevision', 1)
              .having((e) => e.actualRevision, 'actualRevision', 2),
        ),
      );
    });
  });

  group('LocalCaptureJournal - 原子写入与损坏容错恢复', () {
    test('写入完成后不存在残留的 .tmp 文件，主文件为合法 JSON', () async {
      final draft = CaptureDraft.create(
        taskId: 'task_atomic_1',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
      );
      await journal.writeDraft(draft);

      final mainFile = File(journal.mainFilePath);
      final tmpFile = File(journal.tmpFilePath);

      expect(await mainFile.exists(), isTrue);
      expect(await tmpFile.exists(), isFalse);

      final content = await mainFile.readAsString();
      expect(() => jsonDecode(content), returnsNormally);
    });

    test('主文件损坏但存在有效的 .tmp 文件时，成功容错恢复', () async {
      final draft = CaptureDraft.create(
        taskId: 'task_recover_1',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.evidence,
      );

      // 构造主文件为损坏内容
      final mainFile = File(journal.mainFilePath);
      await mainFile.writeAsString('{ "corrupted_incomplete_json": [');

      // 构造有效的 .tmp 文件
      final tmpFile = File(journal.tmpFilePath);
      final validData = {
        'version': 1,
        'drafts': {draft.taskId: draft.toMap()},
      };
      await tmpFile.writeAsString(jsonEncode(validData), flush: true);

      // 读取草稿，验证从 .tmp 自动恢复
      final loaded = await journal.readDraft('task_recover_1');
      expect(loaded, isNotNull);
      expect(loaded!.taskId, 'task_recover_1');

      // 恢复后主文件应已被修复，.tmp 文件被替换或清理
      expect(await mainFile.exists(), isTrue);
      final recoveredJson = await mainFile.readAsString();
      expect(() => jsonDecode(recoveredJson), returnsNormally);
    });

    test('主文件不存在但存在有效的 .tmp 文件时，成功恢复为完整主文件', () async {
      final draft = CaptureDraft.create(
        taskId: 'task_recover_2',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_b'),
        purpose: CapturePurpose.photo,
      );

      final tmpFile = File(journal.tmpFilePath);
      final validData = {
        'version': 1,
        'drafts': {draft.taskId: draft.toMap()},
      };
      await tmpFile.writeAsString(jsonEncode(validData), flush: true);

      final loaded = await journal.readDraft('task_recover_2');
      expect(loaded, isNotNull);
      expect(loaded!.taskId, 'task_recover_2');

      final mainFile = File(journal.mainFilePath);
      expect(await mainFile.exists(), isTrue);
    });

    test('主文件损坏且无有效 .tmp 时，健壮降级返回空而不崩溃', () async {
      final mainFile = File(journal.mainFilePath);
      await mainFile.writeAsString('<<<BAD CORRUPTED BINARY DATA>>>');

      final loaded = await journal.readDraft('any_task');
      expect(loaded, isNull);

      final activeDrafts = await journal.listActiveDrafts();
      expect(activeDrafts, isEmpty);
    });

    test('主文件正常但残留无效 .tmp 文件时，正常读取主文件并清理无效 .tmp', () async {
      final draft = CaptureDraft.create(
        taskId: 'task_cleanup_1',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
      );
      await journal.writeDraft(draft);

      // 人为放入垃圾 .tmp 文件模拟中断遗留
      final tmpFile = File(journal.tmpFilePath);
      await tmpFile.writeAsString('partial write interrupted');

      final loaded = await journal.readDraft('task_cleanup_1');
      expect(loaded, isNotNull);
      expect(loaded!.taskId, 'task_cleanup_1');

      // 验证遗留的 .tmp 文件已被清理
      expect(await tmpFile.exists(), isFalse);
    });
  });

  group('LocalCaptureJournal - 按 owner 过滤 active drafts', () {
    test('正确根据 ownerUserId 及 isActive 状态进行筛选', () async {
      // 1. user_a 活跃草稿 (editing)
      final draftA = CaptureDraft.create(
        taskId: 'draft_user_a',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
        state: CaptureState.editing,
      );
      await journal.writeDraft(draftA);

      // 2. user_b 活跃草稿 (prepared)
      final draftB = CaptureDraft.create(
        taskId: 'draft_user_b',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_b'),
        purpose: CapturePurpose.evidence,
        state: CaptureState.prepared,
      );
      await journal.writeDraft(draftB);

      // 3. 无账号本地活跃草稿 (pickerActive)
      final draftUnowned = CaptureDraft.create(
        taskId: 'draft_unowned',
        ownerContext: const CaptureOwnerContext(ownerUserId: null),
        purpose: CapturePurpose.photo,
        state: CaptureState.pickerActive,
      );
      await journal.writeDraft(draftUnowned);

      // 4. user_a 已完结草稿 (committed)
      final draftACommitted = CaptureDraft.create(
        taskId: 'draft_user_a_committed',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_a'),
        purpose: CapturePurpose.photo,
        state: CaptureState.committed,
      );
      await journal.writeDraft(draftACommitted);

      // 5. user_b 已取消草稿 (cancelled)
      final draftBCancelled = CaptureDraft.create(
        taskId: 'draft_user_b_cancelled',
        ownerContext: const CaptureOwnerContext(ownerUserId: 'user_b'),
        purpose: CapturePurpose.evidence,
        state: CaptureState.cancelled,
      );
      await journal.writeDraft(draftBCancelled);

      // 按 user_a 过滤：仅应包含 draftA（draftACommitted 为终态应被排除）
      final userADrafts = await journal.listActiveDrafts(ownerUserId: 'user_a');
      expect(userADrafts.length, 1);
      expect(userADrafts.first.taskId, 'draft_user_a');

      // 按 user_b 过滤：仅应包含 draftB（draftBCancelled 为终态应被排除）
      final userBDrafts = await journal.listActiveDrafts(ownerUserId: 'user_b');
      expect(userBDrafts.length, 1);
      expect(userBDrafts.first.taskId, 'draft_user_b');

      // 按 unowned 过滤
      final unownedDrafts = await journal.listActiveDrafts(onlyUnowned: true);
      expect(unownedDrafts.length, 1);
      expect(unownedDrafts.first.taskId, 'draft_unowned');

      // 无参数默认查询所有活跃草稿：应包含 draftA, draftB, draftUnowned (共3个)
      final allActive = await journal.listActiveDrafts();
      expect(allActive.length, 3);
      final activeIds = allActive.map((d) => d.taskId).toSet();
      expect(activeIds, {'draft_user_a', 'draft_user_b', 'draft_unowned'});
    });
  });
}
