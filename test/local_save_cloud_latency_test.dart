import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/data/project_repository.dart';
import 'package:life_log/features/project/data/project_local_data_source.dart';
import 'package:life_log/features/project/data/project_sync_gateway.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';
import 'package:life_log/features/expense/data/expense_record_local_data_source.dart';
import 'package:life_log/features/expense/data/expense_record_sync_gateway.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_repository.dart';
import 'package:life_log/features/evidence/data/evidence_local_data_source.dart';
import 'package:life_log/features/evidence/data/evidence_sync_gateway.dart';
import 'package:life_log/features/evidence/data/evidence_project_linker.dart';
import 'package:life_log/features/evidence/data/evidence_file_store.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/subscription/data/subscription_repository.dart';
import 'package:life_log/features/subscription/data/subscription_local_data_source.dart';
import 'package:life_log/features/subscription/data/subscription_sync_gateway.dart';

void main() {
  setUp(() => serviceLocator.registerSingleton(LogService()));
  tearDown(() async => serviceLocator.reset());

  for (final feature in ['project', 'expense', 'evidence']) {
    for (final cloudThrows in [false, true]) {
      test(
        '$feature commits before delayed cloud ${cloudThrows ? 'error' : 'incomplete result'}',
        () async {
          final local = _LocalWrites()..gate = Completer<void>();
          final cloud = _CloudRequests();
          addTearDown(cloud.finish);
          final save = _save(feature, local, cloud);
          var completed = false;
          final completion = save.then((_) => completed = true);
          await _settle();
          expect(completed, isFalse);
          expect(cloud.reasons, isEmpty);
          local.gate!.complete();
          await _settle();
          expect(completed, isTrue);
          expect(cloud.gate.isCompleted, isFalse);
          expect(local.rows, hasLength(1));
          expect(cloud.reasons, hasLength(1));
          if (cloudThrows) {
            cloud.gate.completeError(StateError('cloud unavailable'));
          } else {
            cloud.gate.complete(false);
          }
          await completion;
          await _settle();
          final dynamic row = local.rows.single;
          expect(row.isDirty, isTrue);
          expect(row.remoteVersion, 4);
          expect(
            serviceLocator<LogService>().logs.last.message,
            contains(cloudThrows ? '云端同步失败' : '保留待同步'),
          );
        },
      );
    }
    test('$feature local failure never starts cloud work', () async {
      final local = _LocalWrites()..failWrite = true;
      final cloud = _CloudRequests();
      addTearDown(cloud.finish);
      await expectLater(_save(feature, local, cloud), throwsStateError);
      expect(cloud.reasons, isEmpty);
      expect(local.rows, isEmpty);
    });
  }

  test(
    'expense and evidence linking use durable project identity without awaiting its cloud request',
    () async {
      final local = _LocalWrites();
      final cloud = _CloudRequests();
      addTearDown(cloud.finish);
      serviceLocator.registerSingleton(
        ProjectRepository(localDataSource: local, syncGateway: cloud),
      );
      final expense = ExpenseRecord()
        ..expenseDate = DateTime(2026, 10, 7)
        ..amount = 24
        ..projectName = '项目A';
      final evidence = ExpenseEvidence()
        ..evidenceDate = DateTime(2026, 10, 7)
        ..amount = 35
        ..projectName = '项目A';
      var completed = false;
      final saves = Future.wait([
        ExpenseRecordRepository(
          localDataSource: local,
          syncGateway: cloud,
        ).saveExpenseRecord(expense),
        EvidenceRepository(
          localDataSource: local,
          syncGateway: cloud,
        ).saveEvidence(evidence),
      ]).then((_) => completed = true);
      await _settle();
      expect(completed, isTrue);
      expect(cloud.gate.isCompleted, isFalse);
      expect(expense.projectId, 42);
      expect(evidence.projectId, 42);
      expect(expense.projectSyncId, 'project-id');
      expect(evidence.projectSyncId, 'project-id');
      expect(
        cloud.reasons,
        containsAll(['project-save', 'expense-record-save', 'evidence-save']),
      );
      expect(local.rows, hasLength(2));
      cloud.finish();
      await saves;
    },
  );

  test(
    'evidence still waits for its local attachment copy before persistence and acknowledgement',
    () async {
      final local = _LocalWrites();
      final cloud = _CloudRequests();
      addTearDown(cloud.finish);
      final files = _LocalFiles();
      final evidence = ExpenseEvidence()
        ..evidenceDate = DateTime(2026, 10, 7)
        ..amount = 12
        ..projectName = '项目A';
      var completed = false;
      final save =
          EvidenceRepository(
                localDataSource: local,
                syncGateway: cloud,
                projectLinker: _EvidenceLinker(),
                fileStore: files,
              )
              .saveEvidence(evidence, sourcePath: '/source/receipt.jpg')
              .then((_) => completed = true);
      await _settle();
      expect(completed, isFalse);
      expect(local.rows, isEmpty);
      expect(cloud.reasons, isEmpty);
      files.copyGate.complete();
      await _settle();
      expect(completed, isTrue);
      expect(evidence.localFilePath, '/local/receipt.jpg');
      expect(cloud.gate.isCompleted, isFalse);
      cloud.finish();
      await save;
    },
  );

  test(
    '100-row reorder commits once and schedules one pending cloud request',
    () async {
      final local = _LocalWrites()..gate = Completer<void>();
      final cloud = _CloudRequests();
      addTearDown(cloud.finish);
      final subscriptions = List.generate(
        100,
        (id) => Subscription()
          ..id = id + 1
          ..name = '订阅$id'
          ..nextPaymentDate = DateTime(2026, 10, 7),
      );
      var completed = false;
      final reorder = SubscriptionRepository(
        localDataSource: local,
        syncGateway: cloud,
      ).reorderSubscriptions(subscriptions).then((_) => completed = true);
      await _settle();
      expect(completed, isFalse);
      expect(cloud.reasons, isEmpty);
      local.gate!.complete();
      await _settle();
      expect(completed, isTrue);
      expect(cloud.gate.isCompleted, isFalse);
      expect(local.rows, hasLength(100));
      expect(subscriptions.every((row) => row.isDirty), isTrue);
      expect(
        subscriptions.map((row) => row.sortIndex),
        orderedEquals(List.generate(100, (i) => i)),
      );
      expect(cloud.reasons, ['subscription-reorder']);
      cloud.gate.completeError(StateError('offline'));
      await reorder;
      await _settle();
      expect(subscriptions.every((row) => row.isDirty), isTrue);
      expect(
        serviceLocator<LogService>().logs.last.message,
        contains('云端同步失败'),
      );
    },
  );

  test('unchanged reorder schedules no cloud request', () async {
    final cloud = _CloudRequests();
    addTearDown(cloud.finish);
    await SubscriptionRepository(
      localDataSource: _LocalWrites(),
      syncGateway: cloud,
    ).reorderSubscriptions([]);
    expect(cloud.reasons, isEmpty);
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<Object> _save(String feature, _LocalWrites local, _CloudRequests cloud) {
  if (feature == 'project') {
    final row = Project()
      ..name = '项目A'
      ..remoteVersion = 4;
    return ProjectRepository(
      localDataSource: local,
      syncGateway: cloud,
    ).saveProject(row);
  }
  if (feature == 'expense') {
    final row = ExpenseRecord()
      ..expenseDate = DateTime(2026, 10, 7)
      ..amount = 10
      ..remoteVersion = 4;
    return ExpenseRecordRepository(
      localDataSource: local,
      syncGateway: cloud,
    ).saveExpenseRecord(row);
  }
  final row = ExpenseEvidence()
    ..evidenceDate = DateTime(2026, 10, 7)
    ..amount = 10
    ..projectName = '项目A'
    ..remoteVersion = 4;
  return EvidenceRepository(
    localDataSource: local,
    syncGateway: cloud,
    projectLinker: _EvidenceLinker(),
  ).saveEvidence(row);
}

class _CloudRequests
    implements
        ProjectSyncGateway,
        ExpenseRecordSyncGateway,
        EvidenceSyncGateway,
        SubscriptionSyncGateway {
  final gate = Completer<bool>();
  final reasons = <String>[];
  @override
  bool get isAvailable => true;
  @override
  Future<bool> requestSync(Object row, {required String reason}) {
    reasons.add(reason);
    return gate.future;
  }

  void finish() {
    if (!gate.isCompleted) gate.complete(true);
  }
}

class _LocalWrites
    implements
        ProjectLocalDataSource,
        ExpenseRecordLocalDataSource,
        EvidenceLocalDataSource,
        SubscriptionLocalDataSource {
  final rows = <Object>[];
  Completer<void>? gate;
  bool failWrite = false;
  Future<void> _write(dynamic row) async {
    if (gate != null) await gate!.future;
    if (failWrite) throw StateError('local write failed');
    row.isDirty = true;
    rows.add(row as Object);
  }

  @override
  Future<void> addProject(Project project) => _write(project);
  @override
  Future<int> addExpenseRecord(ExpenseRecord record) async {
    await _write(record);
    return record.id;
  }

  @override
  Future<int> addEvidence(ExpenseEvidence evidence) async {
    await _write(evidence);
    return evidence.id;
  }

  @override
  Future<Project> ensureProject(String name, {bool syncable = false}) async =>
      Project()
        ..id = 42
        ..name = name
        ..syncId = 'project-id'
        ..isDirty = true;
  @override
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subs,
  ) async {
    if (gate != null) await gate!.future;
    if (failWrite) throw StateError('local reorder failed');
    for (var i = 0; i < subs.length; i++) {
      subs[i].sortIndex = i;
      subs[i].isDirty = true;
    }
    rows.addAll(subs);
    return subs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _EvidenceLinker implements EvidenceProjectLinker {
  @override
  Future<EvidenceLinkedProject> ensureSyncableProject(String name) async =>
      EvidenceLinkedProject(id: 42, name: name, syncId: 'project-id');
}

class _LocalFiles implements EvidenceFileStore {
  final copyGate = Completer<void>();
  @override
  Future<void> copyEvidenceFile(
    ExpenseEvidence evidence, {
    required String sourcePath,
    String? sourceExtension,
  }) async {
    await copyGate.future;
    evidence.localFilePath = '/local/receipt.jpg';
  }

  @override
  Future<void> deleteEvidenceFile(ExpenseEvidence? evidence) async {}
}
