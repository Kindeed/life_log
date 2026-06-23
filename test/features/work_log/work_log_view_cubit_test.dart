import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_cubit.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';
import 'package:life_log/features/work_log/presentation/work_log_view.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets('WorkLogView uses WorkLogCubit loading state for read path', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _PendingWorkLogRepository();
    configureWorkLogFeatureDependencies(
      repository: repository,
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pump();

    expect(repository.getEntriesByMonthCallCount, 1);
    expect(find.text('正在加载工时'), findsOneWidget);
    expect(find.byType(WorkLogView), findsOneWidget);
    expect(serviceLocator.isRegistered<WorkLogCubit>(), isTrue);

    repository.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('这天还没有记录'), findsOneWidget);
  });

  testWidgets('WorkLogView renders without a legacy WorkLogController', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    configureWorkLogFeatureDependencies(
      repository: const _ReadyWorkLogRepository(),
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pumpAndSettle();

    expect(find.byType(WorkLogView), findsOneWidget);
    expect(find.text('这天还没有记录'), findsOneWidget);
  });

  testWidgets('calendar header format toggle updates only WorkLogCubit span', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    configureWorkLogFeatureDependencies(
      repository: const _ReadyWorkLogRepository(),
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pumpAndSettle();

    final weekToggle = find.text('周');
    final monthToggle = find.text('月');
    final toggleContext = tester.element(weekToggle);
    final cubit = toggleContext.read<WorkLogCubit>();

    expect(cubit.state.calendarSpan, WorkLogCalendarSpan.month);

    await tester.tap(weekToggle);
    await tester.pumpAndSettle();

    expect(cubit.state.calendarSpan, WorkLogCalendarSpan.week);

    await tester.tap(monthToggle);
    await tester.pumpAndSettle();

    expect(cubit.state.calendarSpan, WorkLogCalendarSpan.month);
  });

  testWidgets('detail list reads selected day from WorkLogCubit state', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    configureWorkLogFeatureDependencies(
      repository: _ReadyWorkLogRepository([
        WorkLogEntry(
          id: 1,
          date: DateTime(2026, 5, 1),
          type: WorkLogEntryType.work,
          overtimeHours: 2,
          note: 'Cubit 日期记录',
        ),
      ]),
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pumpAndSettle();

    expect(find.text('5月1日'), findsOneWidget);
    expect(find.text('Cubit 日期记录'), findsOneWidget);
  });

  testWidgets('detail list does not fall back to legacy controller entries', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    configureWorkLogFeatureDependencies(
      repository: const _ReadyWorkLogRepository(),
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pumpAndSettle();

    expect(find.text('旧 controller 残留记录'), findsNothing);
    expect(find.text('这天还没有记录'), findsOneWidget);
  });

  testWidgets('save flow refreshes WorkLogCubit without legacy controller', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _SavingWorkLogRepository();
    configureWorkLogFeatureDependencies(
      repository: repository,
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pumpAndSettle();

    expect(repository.getEntriesByMonthCallCount, 1);

    await tester.tap(find.text('记工时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repository.savedEntries.length, 1);
    expect(repository.getEntriesByMonthCallCount, 2);
    expect(find.text('工作'), findsOneWidget);
    expect(find.text('正常出勤'), findsOneWidget);
  });

  testWidgets(
    'fab creates a new work-log entry when the selected day has logs',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _SavingWorkLogRepository([
        WorkLogEntry(
          id: 9,
          date: DateTime(2026, 5, 1),
          type: WorkLogEntryType.leave,
          location: '事假',
        ),
      ]);
      configureWorkLogFeatureDependencies(
        repository: repository,
        initialNow: () => DateTime(2026, 5, 1),
      );

      await tester.pumpWidget(_workLogHarness(const WorkLogView()));
      await tester.pumpAndSettle();

      expect(find.text('请假'), findsOneWidget);

      await tester.tap(find.text('记工时'));
      await tester.pumpAndSettle();

      expect(find.text('记录一下'), findsOneWidget);

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(repository.savedEntries.last.id, 0);
      expect(repository.savedEntries.last.type, WorkLogEntryType.work);
      expect(find.text('正常出勤'), findsOneWidget);
    },
  );

  testWidgets('detail delete action uses feature command before refresh', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DeletingWorkLogRepository([
      WorkLogEntry(
        id: 7,
        date: DateTime(2026, 5, 1),
        type: WorkLogEntryType.rest,
        note: '待删除记录',
      ),
    ]);
    configureWorkLogFeatureDependencies(
      repository: repository,
      initialNow: () => DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(_workLogHarness(const WorkLogView()));
    await tester.pumpAndSettle();

    expect(find.text('待删除记录'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [7]);
    expect(repository.getEntriesByMonthCallCount, greaterThanOrEqualTo(2));
  });

  test('WorkLog add edit routes do not use GetX route helpers', () {
    final workLogView = File(
      'lib/features/work_log/presentation/work_log_view.dart',
    ).readAsStringSync();
    final legacyWorkLogView = File('lib/modules/work_log/work_log_view.dart');
    final legacyLogDetailCard = File(
      'lib/modules/work_log/widgets/log_detail_card.dart',
    );
    final dayLogList = File(
      'lib/features/work_log/presentation/widgets/day_log_list.dart',
    ).readAsStringSync();
    final workLogDialogs = File(
      'lib/features/work_log/presentation/work_log_dialogs.dart',
    ).readAsStringSync();
    final workLogEditorLauncher = File(
      'lib/features/work_log/presentation/work_log_editor_launcher.dart',
    ).readAsStringSync();
    final addLogSheet = File(
      'lib/features/work_log/presentation/add_log_sheet.dart',
    ).readAsStringSync();
    final logEditView = File(
      'lib/features/work_log/presentation/log_edit_view.dart',
    ).readAsStringSync();
    final todayView = File(
      'lib/features/today/presentation/today_view.dart',
    ).readAsStringSync();
    final repositoryPort = File(
      'lib/features/work_log/domain/repositories/work_log_repository_port.dart',
    ).readAsStringSync();
    final repositoryAdapter = File(
      'lib/features/work_log/data/legacy_work_log_repository_adapter.dart',
    ).readAsStringSync();

    expect(workLogView, isNot(contains('Get.to')));
    expect(workLogView, isNot(contains("work_log_model.dart")));
    expect(workLogView, isNot(contains('_entryToEditableWorkLog')));
    expect(workLogView, isNot(contains('toLegacyLogType')));
    expect(workLogView, isNot(contains('WorkLogController')));
    expect(workLogView, isNot(contains('legacyController')));
    expect(workLogView, isNot(contains('resolveLegacyWorkLogController')));
    expect(workLogView, isNot(contains('logic.getEventsForDay')));
    expect(workLogView, isNot(contains('logic.onDaySelected')));
    expect(workLogView, isNot(contains('logic.onPageChanged')));
    expect(workLogView, isNot(contains('logic.onFormatChanged')));
    expect(workLogView, contains('TableCalendar<WorkLogEntry>'));
    expect(workLogView, isNot(contains('TableCalendar<WorkLog>')));
    expect(workLogView, contains('_entriesForDay(cubitState, day)'));
    expect(workLogView, isNot(contains('_workLogsForDay')));
    expect(dayLogList, isNot(contains('WorkLogController')));
    expect(dayLogList, isNot(contains("work_log_controller.dart")));
    expect(dayLogList, isNot(contains("work_log_model.dart")));
    expect(dayLogList, isNot(contains('List<WorkLog>')));
    expect(dayLogList, contains('List<WorkLogEntry>'));
    expect(dayLogList, isNot(contains('logic.')));
    expect(dayLogList, isNot(contains('AppConfirmDialog')));
    expect(dayLogList, contains('confirmWorkLogDelete'));
    expect(workLogDialogs, contains('showDialog<bool>'));
    expect(workLogDialogs, isNot(contains('Get.dialog')));
    expect(workLogDialogs, isNot(contains('Get.back')));
    expect(workLogView, isNot(contains('logic.deleteLog')));
    expect(dayLogList, isNot(contains('Get.bottomSheet')));
    expect(dayLogList, isNot(contains('showModalBottomSheet')));
    expect(legacyLogDetailCard.existsSync(), isFalse);
    expect(_libDartSources(), isNot(contains('log_detail_card.dart')));
    expect(_libDartSources(), isNot(contains('LogDetailCard')));
    expect(_libDartSources(), isNot(contains('modules/work_log/widgets')));
    expect(workLogView, isNot(contains('Navigator.of(context).push')));
    expect(workLogView, isNot(contains('showModalBottomSheet')));
    expect(workLogView, contains('openWorkLogEditorPage'));
    expect(workLogView, contains('openWorkLogEditorSheet'));
    expect(workLogEditorLauncher, contains('Navigator.of(context).push'));
    expect(workLogEditorLauncher, contains('showModalBottomSheet'));
    expect(workLogEditorLauncher, contains('LogEditView'));
    expect(workLogEditorLauncher, contains('AddLogSheet'));
    expect(workLogEditorLauncher, isNot(contains('WorkLogController')));
    expect(workLogEditorLauncher, isNot(contains("work_log_model.dart")));
    expect(workLogEditorLauncher, contains('LoadWorkLogEditDraft'));
    expect(addLogSheet, isNot(contains("work_log_model.dart")));
    expect(addLogSheet, contains('existingEntry'));
    expect(addLogSheet, contains('existingAlreadyDirty'));
    expect(addLogSheet, isNot(contains('existingLog')));
    expect(logEditView, isNot(contains("work_log_model.dart")));
    expect(logEditView, contains('WorkLogEntry? existingEntry'));
    expect(logEditView, isNot(contains('WorkLog? existingLog')));
    expect(todayView, isNot(contains("work_log_model.dart")));
    expect(todayView, isNot(contains('_legacyWorkLogFromEntry')));
    expect(repositoryPort, contains('WorkLogEditDraft'));
    expect(repositoryPort, contains('getEditDraft'));
    expect(repositoryAdapter, contains('alreadyDirty: log.isDirty'));
    expect(legacyWorkLogView.existsSync(), isFalse);
    expect(
      _libDartSources(),
      isNot(contains('modules/work_log/work_log_view')),
    );
  });
}

String _libDartSources() {
  final buffer = StringBuffer();
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    buffer
      ..writeln(entity.path)
      ..writeln(entity.readAsStringSync());
  }
  return buffer.toString();
}

Widget _workLogHarness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(home: child),
  );
}

final class _PendingWorkLogRepository implements WorkLogRepositoryPort {
  final Completer<List<WorkLogEntry>> _entriesCompleter = Completer();
  var getAllEntriesCallCount = 0;
  var getEntriesByMonthCallCount = 0;

  void complete(List<WorkLogEntry> entries) {
    if (!_entriesCompleter.isCompleted) {
      _entriesCompleter.complete(entries);
    }
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() {
    getAllEntriesCallCount++;
    return _entriesCompleter.future;
  }

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) {
    getEntriesByMonthCallCount++;
    return _entriesCompleter.future;
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

final class _ReadyWorkLogRepository implements WorkLogRepositoryPort {
  final List<WorkLogEntry> entries;

  const _ReadyWorkLogRepository([this.entries = const []]);

  @override
  Future<List<WorkLogEntry>> getAllEntries() async => entries;

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async {
    return entries
        .where(
          (entry) =>
              entry.date.year == month.year && entry.date.month == month.month,
        )
        .toList(growable: false);
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

final class _SavingWorkLogRepository implements WorkLogRepositoryPort {
  final savedEntries = <WorkLogEntry>[];
  var getAllEntriesCallCount = 0;
  var getEntriesByMonthCallCount = 0;

  _SavingWorkLogRepository([List<WorkLogEntry> entries = const []]) {
    savedEntries.addAll(entries);
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    getAllEntriesCallCount++;
    return savedEntries;
  }

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async {
    getEntriesByMonthCallCount++;
    return savedEntries
        .where(
          (entry) =>
              entry.date.year == month.year && entry.date.month == month.month,
        )
        .toList(growable: false);
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {
    savedEntries.add(entry);
  }

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => const Stream.empty();
}

final class _DeletingWorkLogRepository implements WorkLogRepositoryPort {
  final deletedIds = <int>[];
  var getAllEntriesCallCount = 0;
  var getEntriesByMonthCallCount = 0;
  List<WorkLogEntry> _entries;

  _DeletingWorkLogRepository(this._entries);

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    getAllEntriesCallCount++;
    return _entries;
  }

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async {
    getEntriesByMonthCallCount++;
    return _entries
        .where(
          (entry) =>
              entry.date.year == month.year && entry.date.month == month.month,
        )
        .toList(growable: false);
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {}

  @override
  Future<void> deleteEntry(int id) async {
    deletedIds.add(id);
    _entries = [
      for (final entry in _entries)
        if (entry.id != id) entry,
    ];
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
