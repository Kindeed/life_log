import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/log_edit_view.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_cubit.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_launcher.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';

void main() {
  tearDown(() async {
    await serviceLocator.reset();
  });

  group('WorkLogEditorCubit', () {
    test(
      'prefills and saves a new business trip in its project stage',
      () async {
        final repository = _EditorRepository();
        final cubit = _editor(
          repository: repository,
          initialType: WorkLogEntryType.businessTrip,
          initialProject: _project,
          initialProjectStageName: ' 施工 ',
        );
        addTearDown(cubit.close);

        expect(cubit.state.projectId, 7);
        expect(cubit.state.projectSyncId, 'project-sync-7');
        expect(cubit.state.projectName, '项目七');
        expect(cubit.state.projectStageName, '施工');

        await cubit.submit();

        final saved = repository.savedEntries.single.entry;
        expect(saved.type, WorkLogEntryType.businessTrip);
        expect(saved.id, 0);
        expect(saved.projectId, 7);
        expect(saved.projectSyncId, 'project-sync-7');
        expect(saved.projectName, '项目七');
        expect(saved.projectStageName, '施工');
      },
    );

    for (final type in [
      WorkLogEntryType.work,
      WorkLogEntryType.rest,
      WorkLogEntryType.leave,
    ]) {
      test('does not inject project context into a new ${type.name}', () async {
        final repository = _EditorRepository();
        final cubit = _editor(
          repository: repository,
          initialType: type,
          initialProject: _project,
          initialProjectStageName: '施工',
        );
        addTearDown(cubit.close);

        expect(cubit.state.projectId, isNull);
        expect(cubit.state.projectSyncId, isNull);
        expect(cubit.state.projectName, isEmpty);
        expect(cubit.state.projectStageName, isEmpty);
        await cubit.submit();
        final saved = repository.savedEntries.single.entry;
        expect(saved.type, type);
        expect(saved.projectId, isNull);
        expect(saved.projectSyncId, isNull);
        expect(saved.projectName, isNull);
        expect(saved.projectStageName, isNull);
      });
    }

    test('does not inject a stage without an initial project', () {
      final cubit = _editor(
        initialType: WorkLogEntryType.businessTrip,
        initialProjectStageName: '施工',
      );
      addTearDown(cubit.close);
      expect(cubit.state.projectStageName, isEmpty);
    });

    for (final hasRelationship in [true, false]) {
      test(
        'existing trip keeps its ${hasRelationship ? 'own' : 'unassigned'} relationship',
        () async {
          final repository = _EditorRepository();
          final cubit = _editor(
            repository: repository,
            existingEntry: _entry(
              id: 45,
              syncId: 'trip-sync-45',
              type: WorkLogEntryType.businessTrip,
              location: '',
              transport: '高铁',
              note: '',
              projectId: hasRelationship ? 4 : null,
              projectSyncId: hasRelationship ? 'project-sync-4' : null,
              projectName: hasRelationship ? '旧项目' : null,
              projectStageName: hasRelationship ? '旧阶段' : null,
            ),
            initialType: WorkLogEntryType.work,
            initialProject: _project,
            initialProjectStageName: '施工',
          );
          addTearDown(cubit.close);

          await cubit.submit();

          final call = repository.savedEntries.single;
          expect(call.entry.id, 45);
          expect(call.entry.syncId, 'trip-sync-45');
          expect(call.entry.type, WorkLogEntryType.businessTrip);
          expect(call.entry.projectId, hasRelationship ? 4 : null);
          expect(
            call.entry.projectSyncId,
            hasRelationship ? 'project-sync-4' : null,
          );
          expect(call.entry.projectName, hasRelationship ? '旧项目' : null);
          expect(call.entry.projectStageName, hasRelationship ? '旧阶段' : null);
          expect(call.markDirty, isFalse);
        },
      );
    }

    test('existing ordinary work ignores initial trip context', () async {
      final repository = _EditorRepository();
      final cubit = _editor(
        repository: repository,
        existingEntry: _entry(id: 45),
        initialType: WorkLogEntryType.businessTrip,
        initialProject: _project,
        initialProjectStageName: '施工',
      );
      addTearDown(cubit.close);
      expect(cubit.state.type, WorkLogEntryType.work);
      expect(cubit.state.projectName, isEmpty);
      expect(cubit.state.projectStageName, isEmpty);
      await cubit.submit();
      expect(repository.savedEntries.single.entry.projectId, isNull);
    });

    test('changing the prefilled project clears its stage', () async {
      final repository = _EditorRepository();
      final cubit = _editor(
        repository: repository,
        initialType: WorkLogEntryType.businessTrip,
        initialProject: _project,
        initialProjectStageName: '施工',
      );
      addTearDown(cubit.close);
      cubit.changeProject(id: 8, syncId: 'project-sync-8', name: '项目八');
      expect(cubit.state.projectStageName, isEmpty);
      await cubit.submit();
      final saved = repository.savedEntries.single.entry;
      expect(saved.projectId, 8);
      expect(saved.projectSyncId, 'project-sync-8');
      expect(saved.projectName, '项目八');
      expect(saved.projectStageName, isNull);
    });

    test('switching away from trip context does not restore it later', () {
      final cubit = _editor(
        initialType: WorkLogEntryType.businessTrip,
        initialProject: _project,
        initialProjectStageName: '施工',
      );
      addTearDown(cubit.close);
      cubit.changeType(WorkLogEntryType.work);
      cubit.changeType(WorkLogEntryType.businessTrip);
      expect(cubit.state.projectId, isNull);
      expect(cubit.state.projectSyncId, isNull);
      expect(cubit.state.projectName, isEmpty);
      expect(cubit.state.projectStageName, isEmpty);
    });

    test(
      'switching to a local project removes the previous cloud identity',
      () async {
        final repository = _EditorRepository();
        final cubit = _editor(
          repository: repository,
          initialType: WorkLogEntryType.businessTrip,
          initialProject: _project,
          initialProjectStageName: '施工',
        );
        addTearDown(cubit.close);
        cubit.changeProject(id: 8, name: '本地项目');
        await cubit.submit();
        final saved = repository.savedEntries.single.entry;
        expect(saved.projectId, 8);
        expect(saved.projectSyncId, isNull);
        expect(saved.projectName, '本地项目');
        expect(saved.projectStageName, isNull);
      },
    );

    test(
      'removing the selected project clears all relationship fields',
      () async {
        final repository = _EditorRepository();
        final cubit = _editor(
          repository: repository,
          initialType: WorkLogEntryType.businessTrip,
          initialProject: _project,
          initialProjectStageName: '施工',
        );
        addTearDown(cubit.close);
        cubit.changeProject();
        await cubit.submit();
        final saved = repository.savedEntries.single.entry;
        expect(saved.projectId, isNull);
        expect(saved.projectSyncId, isNull);
        expect(saved.projectName, isNull);
        expect(saved.projectStageName, isNull);
      },
    );

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
      expect(cubit.state.projectId, isNull);
      expect(cubit.state.projectSyncId, isNull);
      expect(cubit.state.projectName, '');
      expect(cubit.state.note, '已存在记录');
    });

    test('initializes business-trip project link from an existing entry', () {
      final cubit = _editor(
        existingEntry: _entry(
          id: 10,
          type: WorkLogEntryType.businessTrip,
          projectId: 5,
          projectSyncId: 'project-sync-5',
          projectName: 'Y9 项目',
        ),
      );
      addTearDown(cubit.close);

      expect(cubit.state.projectId, 5);
      expect(cubit.state.projectSyncId, 'project-sync-5');
      expect(cubit.state.projectName, 'Y9 项目');
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

    test('saves a project link only for business-trip entries', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository);
      addTearDown(cubit.close);

      cubit
        ..changeType(WorkLogEntryType.businessTrip)
        ..changeProject(id: 3, syncId: 'project-sync-3', name: '项目 A')
        ..changeTripLocation('北京');

      await cubit.submit();

      final saved = repository.savedEntries.single.entry;
      expect(saved.type, WorkLogEntryType.businessTrip);
      expect(saved.projectId, 3);
      expect(saved.projectSyncId, 'project-sync-3');
      expect(saved.projectName, '项目 A');
    });

    test('clears project link when entry is not a business trip', () async {
      final repository = _EditorRepository();
      final cubit = _editor(
        repository: repository,
        existingEntry: _entry(
          id: 11,
          type: WorkLogEntryType.businessTrip,
          projectId: 3,
          projectSyncId: 'project-sync-3',
          projectName: '项目 A',
        ),
      );
      addTearDown(cubit.close);

      cubit.changeType(WorkLogEntryType.work);

      await cubit.submit();

      final saved = repository.savedEntries.single.entry;
      expect(saved.type, WorkLogEntryType.work);
      expect(saved.projectId, isNull);
      expect(saved.projectSyncId, isNull);
      expect(saved.projectName, isNull);
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
    for (final asSheet in [false, true]) {
      testWidgets(
        'launcher prefills and saves a trip ${asSheet ? 'sheet' : 'page'}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(375, 812);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = _EditorRepository();
          configureWorkLogFeatureDependencies(repository: repository);

          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (context, _) => MaterialApp(
                home: Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final launcher = asSheet
                              ? openWorkLogEditorSheet
                              : openWorkLogEditorPage;
                          launcher(
                            context,
                            selectedDate: DateTime(2026, 5, 9),
                            initialType: WorkLogEntryType.businessTrip,
                            initialProject: _project,
                            initialProjectStageName: '施工',
                          );
                        },
                        child: const Text('new trip'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('new trip'));
          await tester.pumpAndSettle();
          expect(find.text('城市/地点'), findsOneWidget);
          expect(find.text('项目七'), findsOneWidget);
          expect(find.text('施工'), findsOneWidget);
          await tester.tap(find.text('保存'));
          await tester.pumpAndSettle();
          final saved = repository.savedEntries.single.entry;
          expect(saved.type, WorkLogEntryType.businessTrip);
          expect(saved.projectId, 7);
          expect(saved.projectSyncId, 'project-sync-7');
          expect(saved.projectName, '项目七');
          expect(saved.projectStageName, '施工');
        },
      );
    }

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

    testWidgets('project selectors are scoped to the business-trip form', (
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
            home: LogEditView(selectedDate: DateTime(2026, 5, 9)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('加班时长'), findsOneWidget);
      expect(find.text('无关联项目'), findsNothing);

      await tester.tap(find.text('出差'));
      await tester.pumpAndSettle();

      expect(find.text('城市/地点'), findsOneWidget);
      expect(find.text('无关联项目'), findsOneWidget);
    });

    testWidgets('editor semantics remain stable while switching entry types', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      configureWorkLogFeatureDependencies(repository: _EditorRepository());
      final semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            home: LogEditView(selectedDate: DateTime(2026, 5, 9)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editorFinder = find.byKey(
        const ValueKey('work-log-editor-semantics'),
      );
      expect(tester.getSemantics(editorFinder).label, '工时记录编辑器');

      for (final type in ['出差', '请假', '休息', '工作']) {
        await tester.tap(find.text(type));
        await tester.pumpAndSettle();
        expect(tester.getSemantics(editorFinder).label, '工时记录编辑器');
      }
      semanticsHandle.dispose();
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
  WorkLogEntryType? initialType,
  ProjectEntry? initialProject,
  String? initialProjectStageName,
}) {
  final activeRepository = repository ?? _EditorRepository();
  return WorkLogEditorCubit(
    saveEntry: SaveWorkLogEntry(activeRepository),
    deleteEntry: DeleteWorkLogEntry(activeRepository),
    selectedDate: DateTime(2026, 5, 9, 18),
    existingEntry: existingEntry,
    existingAlreadyDirty: existingAlreadyDirty,
    initialType: initialType,
    initialProject: initialProject,
    initialProjectStageName: initialProjectStageName,
  );
}

WorkLogEntry _entry({
  required int id,
  String? syncId,
  WorkLogEntryType type = WorkLogEntryType.work,
  String? location,
  String? transport,
  double? expenses,
  int? projectId,
  String? projectSyncId,
  String? projectName,
  String? projectStageName,
  bool isReimbursed = false,
  String? note,
}) {
  return WorkLogEntry(
    id: id,
    syncId: syncId,
    date: DateTime(2026, 5, 9),
    type: type,
    overtimeHours: type == WorkLogEntryType.work ? 1 : null,
    location: location,
    transport: transport,
    expenses: expenses,
    projectId: projectId,
    projectSyncId: projectSyncId,
    projectName: projectName,
    projectStageName: projectStageName,
    isReimbursed: isReimbursed,
    note: note,
  );
}

const _project = ProjectEntry(
  id: 7,
  syncId: 'project-sync-7',
  name: '项目七',
  status: ProjectEntryStatus.active,
  stageNames: ['施工', '验收'],
);

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
