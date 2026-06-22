import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/log_edit_view.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_cubit.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';

void main() {
  tearDown(() async {
    await serviceLocator.reset();
  });

  group('WorkLogEditorCubit', () {
    test('initializes a business-trip draft from an existing entry', () {
      final cubit = _editor(
        existingEntry: _entry(
          id: 9,
          type: WorkLogEntryType.businessTrip,
          location: '上海',
          transport: '高铁',
          expenses: 32.5,
          isReimbursed: true,
          note: '已存在记录',
        ),
      );
      addTearDown(cubit.close);

      expect(cubit.state.type, WorkLogEntryType.businessTrip);
      expect(cubit.state.tripLocation, '上海');
      expect(cubit.state.transport, '高铁');
      expect(cubit.state.expenseText, '32.5');
      expect(cubit.state.isReimbursed, isTrue);
      expect(cubit.state.note, '已存在记录');
    });

    test('rejects invalid trip expense before saving', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository);
      addTearDown(cubit.close);

      cubit
        ..changeType(WorkLogEntryType.businessTrip)
        ..changeExpenseText('-1');

      await cubit.submit();

      expect(repository.savedEntries, isEmpty);
      expect(cubit.state.status, WorkLogEditorStatus.failure);
      expect(cubit.state.failure?.code, 'work-log/editor/invalid-expense');
    });

    test('saves a new draft as dirty work-log entry', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository);
      addTearDown(cubit.close);

      cubit
        ..changeType(WorkLogEntryType.businessTrip)
        ..changeTripLocation('北京')
        ..changeTransport('飞机')
        ..changeExpenseText('108.6')
        ..changeReimbursed(true)
        ..changeNote('新出差');

      await cubit.submit();

      final call = repository.savedEntries.single;
      expect(call.markDirty, isTrue);
      expect(call.entry.id, 0);
      expect(call.entry.date, DateTime(2026, 5, 9));
      expect(call.entry.type, WorkLogEntryType.businessTrip);
      expect(call.entry.location, '北京');
      expect(call.entry.transport, '飞机');
      expect(call.entry.expenses, 108.6);
      expect(call.entry.isReimbursed, isTrue);
      expect(call.entry.note, '新出差');
      expect(cubit.state.status, WorkLogEditorStatus.saved);
    });

    test(
      'keeps an unchanged existing draft clean unless it was already dirty',
      () async {
        final repository = _EditorRepository();
        final existing = _entry(id: 12, note: '未改动');
        final cubit = _editor(repository: repository, existingEntry: existing);
        addTearDown(cubit.close);

        await cubit.submit();

        expect(repository.savedEntries.single.markDirty, isFalse);
        expect(repository.savedEntries.single.entry.id, 12);
      },
    );

    test('deletes the existing entry through the delete command', () async {
      final repository = _EditorRepository();
      final cubit = _editor(
        repository: repository,
        existingEntry: _entry(id: 13),
      );
      addTearDown(cubit.close);

      await cubit.delete();

      expect(repository.deletedIds, [13]);
      expect(cubit.state.status, WorkLogEditorStatus.deleted);
    });
  });

  group('AddLogSheet architecture guard', () {
    testWidgets('page presentation exposes a visible back action', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      configureWorkLogFeatureDependencies(repository: _EditorRepository());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                LogEditView(selectedDate: DateTime(2026, 5, 9)),
                          ),
                        );
                      },
                      child: const Text('open editor'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open editor'));
      await tester.pumpAndSettle();

      expect(find.byType(LogEditView), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(LogEditView), findsNothing);
    });

    test(
      'submits through WorkLogEditorCubit instead of controller write methods',
      () {
        final source = File(
          'lib/features/work_log/presentation/add_log_sheet.dart',
        ).readAsStringSync();
        final legacySheet = File('lib/modules/work_log/add_log_sheet.dart');
        final dialogs = File(
          'lib/features/work_log/presentation/work_log_dialogs.dart',
        ).readAsStringSync();

        expect(source, contains('WorkLogEditorCubit'));
        expect(source, contains('BlocListener<WorkLogEditorCubit'));
        expect(source, contains('onSavedOrDeleted'));
        expect(source, contains('confirmWorkLogDelete'));
        expect(source, isNot(contains('AppConfirmDialog')));
        expect(source, isNot(contains("package:get/get.dart")));
        expect(source, isNot(contains('WorkLogController')));
        expect(source, isNot(contains('WorkLogController.to.addLog')));
        expect(source, isNot(contains('WorkLogController.to.deleteLog')));
        expect(source, isNot(contains('Get.back')));
        expect(source, isNot(contains('Get.snackbar')));
        expect(legacySheet.existsSync(), isFalse);
        expect(dialogs, contains('Future<bool> confirmWorkLogDelete'));
      },
    );

    test('LogEditView receives explicit edit dependencies', () {
      final source = File(
        'lib/features/work_log/presentation/log_edit_view.dart',
      ).readAsStringSync();
      final legacyView = File('lib/modules/work_log/views/log_edit_view.dart');

      expect(source, contains('onSavedOrDeleted'));
      expect(source, contains('AddLogSheet'));
      expect(source, isNot(contains("package:get/get.dart")));
      expect(source, isNot(contains('WorkLogController')));
      expect(source, isNot(contains('Get.isRegistered')));
      expect(legacyView.existsSync(), isFalse);
    });
  });
}

WorkLogEditorCubit _editor({
  _EditorRepository? repository,
  WorkLogEntry? existingEntry,
  bool existingAlreadyDirty = false,
}) {
  final activeRepository = repository ?? _EditorRepository();
  return WorkLogEditorCubit(
    saveEntry: SaveWorkLogEntry(activeRepository),
    deleteEntry: DeleteWorkLogEntry(activeRepository),
    selectedDate: DateTime(2026, 5, 9, 18),
    existingEntry: existingEntry,
    existingAlreadyDirty: existingAlreadyDirty,
  );
}

WorkLogEntry _entry({
  required int id,
  WorkLogEntryType type = WorkLogEntryType.work,
  String? location,
  String? transport,
  double? expenses,
  bool isReimbursed = false,
  String? note,
}) {
  return WorkLogEntry(
    id: id,
    date: DateTime(2026, 5, 9),
    type: type,
    overtimeHours: type == WorkLogEntryType.work ? 1 : null,
    location: location,
    transport: transport,
    expenses: expenses,
    isReimbursed: isReimbursed,
    note: note,
  );
}

final class _SavedEditorEntry {
  final WorkLogEntry entry;
  final bool markDirty;

  const _SavedEditorEntry({required this.entry, required this.markDirty});
}

final class _EditorRepository implements WorkLogRepositoryPort {
  final savedEntries = <_SavedEditorEntry>[];
  final deletedIds = <int>[];

  @override
  Future<List<WorkLogEntry>> getAllEntries() async => const [];

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async =>
      const [];

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {
    savedEntries.add(_SavedEditorEntry(entry: entry, markDirty: markDirty));
  }

  @override
  Future<void> deleteEntry(int id) async {
    deletedIds.add(id);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
