import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/presentation/project_accounting_summary.dart';
import 'package:life_log/features/project/presentation/project_trips_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

void main() {
  const scope = ProjectRecordScope(name: '新名称', id: 7, syncId: 'project-7');
  group('project record identity', () {
    test('matching sync link survives renamed project and device-local id', () {
      expect(scope.contains(name: '旧名称', id: 99, syncId: 'project-7'), isTrue);
    });
    test('different sync link rejects matching local id and name', () {
      expect(scope.contains(name: '新名称', id: 7, syncId: 'other'), isFalse);
    });
    test('matching local id survives stale child name', () {
      expect(scope.contains(name: '旧名称', id: 7), isTrue);
    });
    test('same-name child linked to another id is excluded', () {
      expect(scope.contains(name: '新名称', id: 8), isFalse);
    });
    test('only unlinked legacy children use trimmed names', () {
      expect(scope.contains(name: ' 新名称 '), isTrue);
      expect(scope.contains(name: '其他项目'), isFalse);
      expect(scope.contains(), isFalse);
    });
    test('unresolvable strong link is never guessed from the name', () {
      const byName = ProjectRecordScope(name: '新名称');
      expect(byName.contains(name: '新名称', id: 7), isFalse);
      expect(byName.contains(name: '新名称', syncId: 'project-7'), isFalse);
    });
  });
  group('project expense summaries', () {
    ExpenseRecordEntry expense(int id, double amount, String currency) =>
        ExpenseRecordEntry(
          id: id,
          expenseDate: DateTime(2026),
          amount: amount,
          currency: currency,
        );
    test(
      'groups currencies without silently converting or mixing receipts',
      () {
        expect(
          projectExpenseTotals([
            expense(1, 200, 'CNY'),
            expense(2, 25, 'cny'),
            expense(3, 30, 'USD'),
            expense(4, 10, 'EUR'),
          ]),
          {'CNY': 225, 'USD': 30, 'EUR': 10},
        );
      },
    );
    test('empty expenses do not produce a receipt-derived expense amount', () {
      expect(projectExpenseTotals([]), isEmpty);
    });
    test('money labels retain foreign currency', () {
      expect(projectAmount(25, 'CNY'), '¥25.00');
      expect(projectAmount(25, 'usd'), 'USD 25.00');
    });
  });
  group('project trip reads', () {
    test(
      'loader selects durable links and excludes same-name unrelated trips',
      () async {
        final repository = _TripsRepository();
        repository.entries = [
          _trip(1, name: '旧名称', projectId: 7),
          _trip(2, name: '新名称', projectId: 8),
          _trip(3, name: '新名称'),
          _trip(4, name: null),
          _trip(5, name: '新名称', projectId: 7, projectSyncId: 'other'),
          _trip(6, name: '旧名称', projectId: 99, projectSyncId: 'project-7'),
        ];
        final result = await LoadProjectWorkLogTrips(repository)(
          scope.name,
          projectId: scope.id,
          projectSyncId: scope.syncId,
        );
        expect(result.valueOrNull!.map((e) => e.id), [6, 3, 1]);
      },
    );
    test('older completion cannot replace newer trip data', () async {
      final repository = _TripsRepository();
      final old = Completer<List<WorkLogEntry>>();
      repository.next = old;
      final cubit = ProjectTripsCubit(
        scope: scope,
        loadTrips: LoadProjectWorkLogTrips(repository),
      );
      addTearDown(cubit.close);
      final first = cubit.loadEntries();
      repository.next = null;
      repository.entries = [_trip(2)];
      await cubit.loadEntries();
      old.complete([_trip(1)]);
      await first;
      expect(cubit.state.entries.single.id, 2);
    });
    test('older failure cannot erase a successful newer read', () async {
      final repository = _TripsRepository();
      final old = Completer<List<WorkLogEntry>>();
      repository.next = old;
      final cubit = ProjectTripsCubit(
        scope: scope,
        loadTrips: LoadProjectWorkLogTrips(repository),
      );
      addTearDown(cubit.close);
      final first = cubit.loadEntries();
      repository.next = null;
      repository.entries = [_trip(2)];
      await cubit.loadEntries();
      old.completeError(StateError('old read failed'));
      await first;
      expect(cubit.state.entries.single.id, 2);
      expect(cubit.state.failure, isNull);
    });
    test('failure preserves cached trips and retry clears it', () async {
      final repository = _TripsRepository()..entries = [_trip(1)];
      final cubit = ProjectTripsCubit(
        scope: scope,
        loadTrips: LoadProjectWorkLogTrips(repository),
      );
      addTearDown(cubit.close);
      await cubit.loadEntries();
      repository.fail = true;
      await cubit.loadEntries();
      expect(cubit.state.entries.single.id, 1);
      expect(cubit.state.failure, isNotNull);
      repository.fail = false;
      await cubit.loadEntries();
      expect(cubit.state.failure, isNull);
    });
    test(
      'scope change clears cached trips and rejects the old result',
      () async {
        final repository = _TripsRepository()..entries = [_trip(1)];
        final cubit = ProjectTripsCubit(
          scope: scope,
          loadTrips: LoadProjectWorkLogTrips(repository),
        );
        addTearDown(cubit.close);
        await cubit.loadEntries();
        final old = Completer<List<WorkLogEntry>>();
        repository.next = old;
        final pending = cubit.loadEntries();
        final newer = Completer<List<WorkLogEntry>>();
        repository.next = newer;
        cubit.setProject(const ProjectRecordScope(name: '其他', id: 8));
        expect(cubit.state.entries, isEmpty);
        old.complete([_trip(1)]);
        await pending;
        expect(cubit.state.entries, isEmpty);
        newer.complete([_trip(3, name: '其他', projectId: 8)]);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.entries.single.id, 3);
      },
    );
    test('watcher burst coalesces and updates the snapshot', () async {
      final repository = _TripsRepository()..entries = [_trip(1)];
      final cubit = ProjectTripsCubit(
        scope: scope,
        loadTrips: LoadProjectWorkLogTrips(repository),
        watchEntries: WatchWorkLogEntries(repository),
      );
      addTearDown(cubit.close);
      cubit.start();
      await Future<void>.delayed(Duration.zero);
      repository.reads = 0;
      repository.entries = [_trip(2)];
      for (var i = 0; i < 100; i++) {
        repository.changes.add(null);
      }
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(repository.reads, 2);
      expect(cubit.state.entries.single.id, 2);
    });
    test(
      'late completion and watcher events after disposal do not emit',
      () async {
        final repository = _TripsRepository();
        final pending = Completer<List<WorkLogEntry>>();
        repository.next = pending;
        final cubit = ProjectTripsCubit(
          scope: scope,
          loadTrips: LoadProjectWorkLogTrips(repository),
          watchEntries: WatchWorkLogEntries(repository),
        );
        cubit.start();
        await cubit.close();
        pending.complete([_trip(1)]);
        repository.changes.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.entries, isEmpty);
        expect(repository.reads, 1);
      },
    );
  });
}

WorkLogEntry _trip(
  int id, {
  String? name = '新名称',
  int? projectId,
  String? projectSyncId,
}) => WorkLogEntry(
  id: id,
  date: DateTime(2026),
  type: WorkLogEntryType.businessTrip,
  projectName: name,
  projectId: projectId,
  projectSyncId: projectSyncId,
);

class _TripsRepository implements WorkLogRepositoryPort {
  List<WorkLogEntry> entries = [];
  Completer<List<WorkLogEntry>>? next;
  final changes = StreamController<void>.broadcast(sync: true);
  bool fail = false;
  int reads = 0;
  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    reads++;
    if (fail) throw StateError('read failed');
    return next == null ? List.of(entries) : await next!.future;
  }

  @override
  Stream<void> watchEntries() => changes.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
