import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/initialize_work_log_feature.dart';
import 'package:life_log/features/work_log/application/load_work_log_month.dart';
import 'package:life_log/features/work_log/application/load_work_log_today.dart';
import 'package:life_log/features/work_log/application/normalize_work_log_entries.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_cubit.dart';
import 'package:life_log/features/work_log/presentation/work_log_today_cubit.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';

void main() {
  group('LoadWorkLogMonth', () {
    test(
      'keeps latest entry per day and calculates legacy month stats',
      () async {
        final repository = _FakeWorkLogRepository([
          _entry(
            id: 1,
            date: DateTime(2026, 5, 9),
            type: WorkLogEntryType.work,
            overtimeHours: 2,
            updatedAt: DateTime(2026, 5, 9, 9),
          ),
          _entry(
            id: 2,
            date: DateTime(2026, 5, 9),
            type: WorkLogEntryType.rest,
            updatedAt: DateTime(2026, 5, 9, 10),
          ),
          _entry(
            id: 3,
            date: DateTime(2026, 5, 10),
            type: WorkLogEntryType.businessTrip,
          ),
          _entry(
            id: 4,
            date: DateTime(2026, 6, 1),
            type: WorkLogEntryType.work,
            overtimeHours: 5,
          ),
        ]);

        final result = await LoadWorkLogMonth(
          repository,
        ).call(DateTime(2026, 5, 1));

        final snapshot = result.valueOrNull!;
        expect(result.isSuccess, isTrue);
        expect(snapshot.entriesByDay.keys, [
          DateTime(2026, 5, 9),
          DateTime(2026, 5, 10),
        ]);
        expect(snapshot.entriesByDay[DateTime(2026, 5, 9)]!.id, 2);
        expect(snapshot.summary.workDays, 0);
        expect(snapshot.summary.tripDays, 1);
        expect(snapshot.summary.restDays, 1);
        expect(snapshot.summary.workHours, 0);
      },
    );

    test('returns failure when the repository throws', () async {
      final result = await LoadWorkLogMonth(
        _FakeWorkLogRepository.throws(StateError('db down')),
      ).call(DateTime(2026, 5, 1));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'work-log/load-month');
      expect(result.failureOrNull?.message, contains('db down'));
    });
  });

  group('WorkLogCubit', () {
    test('loads month snapshot and updates selected day', () async {
      final repository = _FakeWorkLogRepository([
        _entry(id: 1, date: DateTime(2026, 5, 9)),
      ]);
      final cubit = WorkLogCubit(
        loadMonth: LoadWorkLogMonth(repository),
        watchEntries: WatchWorkLogEntries(repository),
        initialNow: () => DateTime(2026, 5, 1),
      );
      addTearDown(cubit.close);
      final states = <WorkLogState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.loadFocusedMonth();
      cubit.selectDay(DateTime(2026, 5, 9), DateTime(2026, 5, 12));
      await pumpEventQueue();

      expect(states.map((state) => state.status), [
        WorkLogStatus.loading,
        WorkLogStatus.ready,
        WorkLogStatus.ready,
      ]);
      expect(cubit.state.selectedDay, DateTime(2026, 5, 9));
      expect(cubit.state.focusedDay, DateTime(2026, 5, 12));
      expect(cubit.state.eventsForDay(DateTime(2026, 5, 9)).single.id, 1);
    });

    test('reloads focused month when repository emits entry changes', () async {
      final repository = _WatchableWorkLogRepository([
        _entry(id: 1, date: DateTime(2026, 5, 9), type: WorkLogEntryType.work),
      ]);
      addTearDown(repository.dispose);
      final cubit = WorkLogCubit(
        loadMonth: LoadWorkLogMonth(repository),
        watchEntries: WatchWorkLogEntries(repository),
        initialNow: () => DateTime(2026, 5, 1),
      );
      addTearDown(cubit.close);

      cubit.start();
      await _settleCubitAsyncWork();

      expect(repository.getAllEntriesCallCount, 1);
      expect(
        cubit.state.entriesByDay[DateTime(2026, 5, 9)]!.type,
        WorkLogEntryType.work,
      );

      repository.replaceEntries([
        _entry(id: 2, date: DateTime(2026, 5, 9), type: WorkLogEntryType.rest),
      ]);
      repository.emitChange();
      await _settleCubitAsyncWork();

      expect(repository.getAllEntriesCallCount, 2);
      expect(
        cubit.state.entriesByDay[DateTime(2026, 5, 9)]!.type,
        WorkLogEntryType.rest,
      );
    });
  });

  group('configureWorkLogFeatureDependencies', () {
    test('registers repository port, use case, and cubit factory', () async {
      final locator = GetIt.asNewInstance();

      configureWorkLogFeatureDependencies(
        locator: locator,
        repository: _FakeWorkLogRepository([]),
        initialNow: () => DateTime(2026, 5, 1),
      );

      expect(locator.isRegistered<WorkLogRepositoryPort>(), isTrue);
      expect(locator.isRegistered<NormalizeWorkLogEntries>(), isTrue);
      expect(locator.isRegistered<InitializeWorkLogFeature>(), isTrue);
      expect(locator.isRegistered<LoadWorkLogMonth>(), isTrue);
      expect(locator.isRegistered<LoadWorkLogToday>(), isTrue);
      expect(locator.isRegistered<SaveWorkLogEntry>(), isTrue);
      expect(locator.isRegistered<DeleteWorkLogEntry>(), isTrue);
      expect(locator.isRegistered<WatchWorkLogEntries>(), isTrue);
      final cubit = locator<WorkLogCubit>();
      addTearDown(cubit.close);

      expect(cubit.state.focusedDay, DateTime(2026, 5, 1));
      expect(cubit.state.calendarSpan, WorkLogCalendarSpan.month);

      final todayCubit = locator<WorkLogTodayCubit>();
      addTearDown(todayCubit.close);

      expect(todayCubit.state.snapshot.today, DateTime(2026, 5, 1));
    });

    test('mobile bootstrap owns feature DI configuration', () {
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final tabsBinding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(appEntry, contains('configureCoreDependencies'));
      expect(appEntry, contains('configureWorkLogFeatureDependencies'));
      expect(appEntry, contains('configureSubscriptionFeatureDependencies'));
      expect(appEntry, contains('configureExpenseFeatureDependencies'));
      expect(appEntry, contains('configurePhotoFeatureDependencies'));
      expect(appEntry, contains('configureEvidenceFeatureDependencies'));
      expect(appEntry, contains('configureProjectFeatureDependencies'));
      expect(appEntry, contains('configureProfileFeatureDependencies'));

      expect(
        tabsBinding,
        isNot(contains('configureWorkLogFeatureDependencies')),
      );
      expect(
        tabsBinding,
        isNot(contains('configureSubscriptionFeatureDependencies')),
      );
      expect(
        tabsBinding,
        isNot(contains('configureExpenseFeatureDependencies')),
      );
      expect(tabsBinding, isNot(contains('configurePhotoFeatureDependencies')));
      expect(
        tabsBinding,
        isNot(contains('configureEvidenceFeatureDependencies')),
      );
      expect(
        tabsBinding,
        isNot(contains('configureProjectFeatureDependencies')),
      );
      expect(
        tabsBinding,
        isNot(contains('configureProfileFeatureDependencies')),
      );
      expect(tabsBinding, contains('InitializeWorkLogFeature'));
    });

    test(
      'InitializeWorkLogFeature normalizes duplicate days only once',
      () async {
        final repository = _FakeWorkLogRepository([]);
        final initialize = InitializeWorkLogFeature(
          normalizeEntries: NormalizeWorkLogEntries(repository),
        );

        await initialize();
        await initialize();

        expect(repository.normalizeDuplicateDaysCallCount, 1);
      },
    );

    test('legacy WorkLogController is not a runtime binding dependency', () {
      final tabsBinding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      final backupService = File(
        'lib/common/db/backup_service.dart',
      ).readAsStringSync();

      expect(tabsBinding, isNot(contains('WorkLogController')));
      expect(tabsBinding, isNot(contains('work_log_controller.dart')));
      expect(tabsBinding, contains('InitializeWorkLogFeature'));
      expect(backupService, isNot(contains('WorkLogController')));
      expect(backupService, isNot(contains('work_log_controller.dart')));
    });

    test('legacy WorkLogController is retired from production sources', () {
      final legacyController = File(
        'lib/modules/work_log/work_log_controller.dart',
      );

      expect(legacyController.existsSync(), isFalse);
      expect(_libDartSources(), isNot(contains('class WorkLogController')));
      expect(_libDartSources(), isNot(contains('work_log_controller.dart')));
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
  var normalizeDuplicateDaysCallCount = 0;

  _FakeWorkLogRepository(this.entries) : error = null;

  _FakeWorkLogRepository.throws(this.error) : entries = const [];

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    final activeError = error;
    if (activeError != null) {
      throw activeError;
    }
    return entries;
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {
    normalizeDuplicateDaysCallCount += 1;
  }

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

String _libDartSources() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}
