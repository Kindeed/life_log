import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/work_log/application/load_work_log_today.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_today_cubit.dart';

void main() {
  group('LoadWorkLogToday', () {
    test(
      'keeps latest day entries and builds today dashboard snapshot',
      () async {
        final repository = _FakeWorkLogRepository([
          _entry(
            id: 1,
            date: DateTime(2026, 5, 9),
            type: WorkLogEntryType.work,
            overtimeHours: 2,
            updatedAt: DateTime(2026, 5, 9, 8),
          ),
          _entry(
            id: 2,
            date: DateTime(2026, 5, 9),
            type: WorkLogEntryType.businessTrip,
            updatedAt: DateTime(2026, 5, 9, 9),
          ),
          _entry(
            id: 3,
            date: DateTime(2026, 5, 8),
            type: WorkLogEntryType.work,
            overtimeHours: 1,
          ),
          _entry(
            id: 4,
            date: DateTime(2026, 5, 3),
            type: WorkLogEntryType.rest,
          ),
          _entry(
            id: 5,
            date: DateTime(2026, 5, 2),
            type: WorkLogEntryType.work,
            overtimeHours: 5,
          ),
          _entry(
            id: 6,
            date: DateTime(2026, 4, 30),
            type: WorkLogEntryType.work,
            overtimeHours: 3,
          ),
        ]);

        final result = await LoadWorkLogToday(
          repository,
        ).call(DateTime(2026, 5, 9, 13));

        final snapshot = result.valueOrNull!;
        expect(result.isSuccess, isTrue);
        expect(snapshot.today, DateTime(2026, 5, 9));
        expect(snapshot.todayEntry?.id, 2);
        expect(snapshot.recentEntries.map((entry) => entry.id), [2, 3, 4]);
        expect(snapshot.currentMonthSummary.workHours, 6);
        expect(snapshot.currentMonthSummary.workDays, 2);
        expect(snapshot.currentMonthSummary.tripDays, 1);
        expect(snapshot.currentMonthSummary.restDays, 1);
      },
    );

    test('returns failure when the repository throws', () async {
      final result = await LoadWorkLogToday(
        _FakeWorkLogRepository.throws(StateError('today db down')),
      ).call(DateTime(2026, 5, 9));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'work-log/load-today');
      expect(result.failureOrNull?.message, contains('today db down'));
    });
  });

  group('WorkLogTodayCubit', () {
    test(
      'loads today snapshot and reloads when work-log entries change',
      () async {
        final repository = _WatchableWorkLogRepository([
          _entry(
            id: 1,
            date: DateTime(2026, 5, 9),
            type: WorkLogEntryType.work,
          ),
        ]);
        addTearDown(repository.dispose);
        final cubit = WorkLogTodayCubit(
          loadToday: LoadWorkLogToday(repository),
          watchEntries: WatchWorkLogEntries(repository),
          todayProvider: () => DateTime(2026, 5, 9, 18),
        );
        addTearDown(cubit.close);

        cubit.start();
        await _settleCubitAsyncWork();

        expect(repository.getAllEntriesCallCount, 1);
        expect(cubit.state.status, WorkLogTodayStatus.ready);
        expect(cubit.state.snapshot.todayEntry?.type, WorkLogEntryType.work);

        repository.replaceEntries([
          _entry(
            id: 2,
            date: DateTime(2026, 5, 9),
            type: WorkLogEntryType.rest,
          ),
        ]);
        repository.emitChange();
        await _settleCubitAsyncWork();

        expect(repository.getAllEntriesCallCount, 2);
        expect(cubit.state.snapshot.todayEntry?.type, WorkLogEntryType.rest);
      },
    );
  });

  group('TodayView architecture guard', () {
    test('reads work-log dashboard state from the feature Cubit', () {
      final source = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();

      expect(source, contains('WorkLogTodayCubit'));
      expect(source, contains('openWorkLogEditorPage'));
      expect(source, isNot(contains('WorkLogController')));
      expect(source, isNot(contains("work_log_controller.dart")));
      expect(source, isNot(contains('workLog.loadData')));
      expect(source, isNot(contains('workLog.getEventsForDay')));
      expect(source, isNot(contains('workLog.getLogForDay')));
      expect(source, isNot(contains('monthStatsHours')));
    });
  });
}

WorkLogEntry _entry({
  required int id,
  required DateTime date,
  WorkLogEntryType type = WorkLogEntryType.work,
  double? overtimeHours,
  DateTime? updatedAt,
}) {
  return WorkLogEntry(
    id: id,
    date: date,
    type: type,
    overtimeHours: overtimeHours,
    updatedAt: updatedAt,
  );
}

final class _FakeWorkLogRepository implements WorkLogRepositoryPort {
  final List<WorkLogEntry> entries;
  final Object? error;

  _FakeWorkLogRepository(this.entries) : error = null;

  _FakeWorkLogRepository.throws(this.error) : entries = const [];

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    final activeError = error;
    if (activeError != null) throw activeError;
    return entries;
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

final class _WatchableWorkLogRepository implements WorkLogRepositoryPort {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  List<WorkLogEntry> _entries;
  int getAllEntriesCallCount = 0;

  _WatchableWorkLogRepository(this._entries);

  void replaceEntries(List<WorkLogEntry> entries) {
    _entries = entries;
  }

  void emitChange() {
    _changes.add(null);
  }

  Future<void> dispose() {
    return _changes.close();
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    getAllEntriesCallCount += 1;
    return _entries;
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => _changes.stream;
}

Future<void> _settleCubitAsyncWork() async {
  await pumpEventQueue();
  await pumpEventQueue();
}
