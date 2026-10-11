import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'package:life_log/features/project/application/delete_project_note_entry.dart';
import 'package:life_log/features/project/application/save_project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';
import 'package:life_log/features/project/presentation/project_note_editor.dart';
import 'package:life_log/features/project/presentation/project_stage_field.dart';

const _project = ProjectEntry(
  id: 7,
  syncId: 'project-sync-7',
  name: '园区设备升级',
  status: ProjectEntryStatus.active,
  stageNames: ['勘查', '现场交付'],
);

ProjectNoteEntry _existing({String? stage = '历史验收'}) => ProjectNoteEntry(
  id: 12,
  projectId: 7,
  projectSyncId: 'old-project-sync-7',
  projectName: _project.name,
  projectStageName: stage,
  content: '原始现场说明',
  date: DateTime(2026, 10, 11),
  createdAt: DateTime(2026, 9, 1, 9, 30),
  updatedAt: DateTime(2026, 10, 11, 10),
);

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  testWidgets('new note uses stage context and saves trimmed local fields', (
    tester,
  ) async {
    final repository = _Notes();
    final session = await _open(tester, repository, initialStage: ' 现场交付 ');
    expect(_stage(tester).selected, '现场交付');
    final initialDay = DateUtils.dateOnly(DateTime.now());
    expect(find.text(_ymd(initialDay)), findsOneWidget);
    await tester.enterText(_content, '  设备接入完成\n明天复查网络  ');
    final before = DateTime.now();

    await _tapEditor(tester, '保存记录');

    expect(repository.saves, hasLength(1));
    final saved = repository.saves.single;
    expect(saved.id, 0);
    expect(saved.projectId, _project.id);
    expect(saved.projectSyncId, _project.syncId);
    expect(saved.projectName, _project.name);
    expect(saved.projectStageName, '现场交付');
    expect(saved.content, '设备接入完成\n明天复查网络');
    expect(saved.date, initialDay);
    expect(saved.createdAt.isBefore(before), isFalse);
    expect(saved.createdAt.isAfter(DateTime.now()), isFalse);
    expect(saved.updatedAt, saved.createdAt);
    expect(session.results, [true]);
    expect(find.byType(ProjectNoteEditor), findsNothing);
    expect(find.text('文字记录已保存'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'edit keeps historical stage and creation identity after date edit',
    (tester) async {
      final repository = _Notes();
      final old = _existing();
      await _open(tester, repository, existing: old, initialStage: '勘查');
      expect(_stage(tester).selected, '历史验收');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('历史验收'), findsWidgets);
      await tester.tap(find.text('历史验收').last);
      await tester.pumpAndSettle();
      await tester.enterText(_content, '补充验收结果');
      await _tapEditor(tester, '记录日期');
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('12').last);
      final pickerContext = tester.element(find.byType(DatePickerDialog));
      final confirm = MaterialLocalizations.of(pickerContext).okButtonLabel;
      final confirmButton = find.text('确定').evaluate().isNotEmpty
          ? find.text('确定')
          : find.text(confirm);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(find.text('2026-10-12'), findsOneWidget);

      await _tapEditor(tester, '保存记录');

      final saved = repository.saves.single;
      expect(saved.id, old.id);
      expect(saved.projectId, old.projectId);
      expect(saved.projectSyncId, old.projectSyncId);
      expect(saved.projectStageName, '历史验收');
      expect(saved.createdAt, old.createdAt);
      expect(saved.date, DateTime(2026, 10, 12));
      expect(saved.content, '补充验收结果');
      expect(saved.updatedAt.isBefore(old.updatedAt), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blank content stays inline and never calls persistence', (
    tester,
  ) async {
    final repository = _Notes();
    await _open(tester, repository);
    await tester.enterText(_content, '   \n ');

    await _tapEditor(tester, '保存记录');

    expect(repository.saves, isEmpty);
    expect(repository.deletes, isEmpty);
    expect(find.byType(ProjectNoteEditor), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppFormFeedback),
        matching: find.text('请填写记录内容'),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slow save locks one command and failure keeps draft for retry', (
    tester,
  ) async {
    final pending = Completer<void>();
    final repository = _Notes()..savePending = pending;
    final session = await _open(tester, repository, existing: _existing());
    await tester.enterText(_content, '等待验证的现场问题');

    await _tapEditor(tester, '保存记录', settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    _expectLocked(tester);
    await session.navigator.currentState!.maybePop();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('放弃未保存的修改？'), findsNothing);
    expect(repository.saves, hasLength(1));
    expect(repository.deletes, isEmpty);

    pending.completeError(StateError('磁盘暂不可用'));
    await tester.pumpAndSettle();
    expect(find.text('磁盘暂不可用'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_content).controller!.text,
      '等待验证的现场问题',
    );
    expect(_stage(tester).selected, '历史验收');
    expect(find.text('2026-10-11'), findsOneWidget);
    expect(tester.widget<TextFormField>(_content).enabled, isTrue);
    repository.savePending = null;

    await _tapEditor(tester, '保存记录');

    expect(repository.saves, hasLength(2));
    expect(repository.saves.last.content, '等待验证的现场问题');
    expect(session.results, [true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete confirmation and slow deletion cannot overlap a save', (
    tester,
  ) async {
    final pending = Completer<void>();
    final repository = _Notes()..deletePending = pending;
    final session = await _open(tester, repository, existing: _existing());
    await tester.enterText(_content, '删除前的编辑草稿');
    await _tapEditor(tester, '删除', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('删除文字记录？'), findsOneWidget);
    _expectLocked(tester);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('取消')),
    );
    await tester.pumpAndSettle();
    expect(repository.deletes, isEmpty);
    expect(tester.widget<TextFormField>(_content).controller!.text, '删除前的编辑草稿');

    await _tapEditor(tester, '删除', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('删除')),
    );
    await tester.pump();
    _expectLocked(tester);
    await session.navigator.currentState!.maybePop();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.deletes, [12]);
    expect(repository.saves, isEmpty);
    expect(find.byType(ProjectNoteEditor), findsOneWidget);

    pending.completeError(StateError('删除暂失败'));
    await tester.pumpAndSettle();
    expect(find.text('删除暂失败'), findsOneWidget);
    expect(tester.widget<TextFormField>(_content).controller!.text, '删除前的编辑草稿');
    repository.deletePending = null;
    await _tapEditor(tester, '删除', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('删除')),
    );
    await tester.pumpAndSettle();
    expect(repository.deletes, [12, 12]);
    expect(repository.saves, isEmpty);
    expect(session.results, [true]);
    expect(find.text('文字记录已删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account change during save retains the original draft', (
    tester,
  ) async {
    final pending = Completer<void>();
    final repository = _Notes()..savePending = pending;
    final session = await _open(tester, repository, existing: _existing());
    expect(repository.captureCalls, 1);
    await tester.enterText(_content, '原账号下尚未提交的现场记录');

    await _tapEditor(tester, '保存记录', settle: false);
    expect(repository.saveContexts, [0]);
    repository.context = 1;
    pending.complete();
    await tester.pumpAndSettle();

    expect(find.text('账号或数据库已变化，请重新打开项目'), findsOneWidget);
    expect(repository.committedSaves, isEmpty);
    expect(session.results, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester.widget<TextFormField>(_content).controller!.text,
      '原账号下尚未提交的现场记录',
    );
    expect(_stage(tester).selected, '历史验收');
    expect(find.text('2026-10-11'), findsOneWidget);
    expect(tester.widget<TextFormField>(_content).enabled, isTrue);

    repository.savePending = null;
    await _tapEditor(tester, '保存记录');
    expect(repository.saveContexts, [0, 0]);
    expect(repository.committedSaves, isEmpty);
    expect(repository.captureCalls, 1);
    await _tapEditor(tester, '取消');
    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(session.results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account change while confirming deletion preserves the draft', (
    tester,
  ) async {
    final repository = _Notes();
    final session = await _open(tester, repository, existing: _existing());
    expect(repository.captureCalls, 1);
    await tester.enterText(_content, '删除确认期间仍需保留的草稿');
    await _tapEditor(tester, '删除', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('删除文字记录？'), findsOneWidget);
    repository.context = 1;

    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('删除')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletes, [12]);
    expect(repository.deleteContexts, [0]);
    expect(repository.committedDeletes, isEmpty);
    expect(repository.saves, isEmpty);
    expect(repository.captureCalls, 1);
    expect(find.text('账号或数据库已变化，请重新打开项目'), findsOneWidget);
    expect(find.byType(ProjectNoteEditor), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(session.results, isEmpty);
    expect(
      tester.widget<TextFormField>(_content).controller!.text,
      '删除确认期间仍需保留的草稿',
    );
    expect(_stage(tester).selected, '历史验收');
    expect(find.text('2026-10-11'), findsOneWidget);
    expect(tester.widget<TextFormField>(_content).enabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel asks before discarding and continue retains content', (
    tester,
  ) async {
    final repository = _Notes();
    final session = await _open(tester, repository);
    await tester.enterText(_content, '需要保留的沟通内容');

    await _tapEditor(tester, '取消');

    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(_content).controller!.text,
      '需要保留的沟通内容',
    );
    await _tapEditor(tester, '取消');
    await tester.tap(find.text('放弃修改'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectNoteEditor), findsNothing);
    expect(session.results, [null]);
    expect(repository.saves, isEmpty);
    expect(repository.deletes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing only the stage is a protected draft', (tester) async {
    final repository = _Notes();
    await _open(tester, repository, existing: _existing(stage: null));
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('勘查').last);
    await tester.pumpAndSettle();
    expect(_stage(tester).selected, '勘查');

    await _tapEditor(tester, '取消');

    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    expect(repository.saves, isEmpty);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(_stage(tester).selected, '勘查');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an untouched prefilled editor can close without prompting', (
    tester,
  ) async {
    final repository = _Notes();
    final session = await _open(tester, repository, initialStage: '勘查');
    await _tapEditor(tester, '取消');
    expect(find.text('放弃未保存的修改？'), findsNothing);
    expect(find.byType(ProjectNoteEditor), findsNothing);
    expect(session.results, [null]);
    expect(repository.saves, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets('late save completion after dispose is inert fails=$fails', (
      tester,
    ) async {
      final pending = Completer<void>();
      final repository = _Notes()..savePending = pending;
      await _open(tester, repository);
      await tester.enterText(_content, '异步现场记录');
      await _tapEditor(tester, '保存记录', settle: false);
      expect(repository.saves, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      if (fails) {
        pending.completeError(StateError('晚到失败'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dark in [false, true]) {
    testWidgets('narrow large text editor remains actionable dark=$dark', (
      tester,
    ) async {
      final repository = _Notes();
      await _open(
        tester,
        repository,
        existing: _existing(stage: '需要与施工及验收团队协调的历史阶段'),
        dark: dark,
        width: 320,
        scale: 2,
      );
      await tester.enterText(_content, '较长的设备故障说明\n需要跟进电源、信号及后续验收情况。');
      await _tapEditor(tester, '保存记录');
      expect(repository.saves, hasLength(1));
      expect(repository.saves.single.projectStageName, '需要与施工及验收团队协调的历史阶段');
      expect(find.text('文字记录已保存'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Finder get _content => find.descendant(
  of: find.byType(ProjectNoteEditor),
  matching: find.byType(TextFormField),
);

ProjectStageField _stage(WidgetTester tester) =>
    tester.widget<ProjectStageField>(find.byType(ProjectStageField));

String _ymd(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

Future<void> _tapEditor(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  final target = find.descendant(
    of: find.byType(ProjectNoteEditor),
    matching: find.text(label),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void _expectLocked(WidgetTester tester) {
  expect(tester.widget<TextFormField>(_content).enabled, isFalse);
  expect(_stage(tester).enabled, isFalse);
  final save = tester.widget<AppButton>(find.byType(AppButton));
  expect(save.isLoading, isTrue);
  expect(save.onPressed, isNull);
  final editor = find.byType(ProjectNoteEditor);
  for (final label in ['取消', '删除']) {
    final buttons = find.descendant(
      of: editor,
      matching: find.widgetWithText(TextButton, label),
    );
    for (final button in tester.widgetList<TextButton>(buttons)) {
      expect(button.onPressed, isNull);
    }
  }
  expect(
    tester.widget<ListTile>(find.widgetWithText(ListTile, '记录日期')).onTap,
    isNull,
  );
}

class _Session {
  final navigator = GlobalKey<NavigatorState>();
  final results = <bool?>[];
}

Future<_Session> _open(
  WidgetTester tester,
  _Notes repository, {
  ProjectNoteEntry? existing,
  String? initialStage,
  bool dark = false,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final session = _Session();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        navigatorKey: session.navigator,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('zh', 'CN')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  session.results.add(
                    await showAppBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProjectNoteEditor(
                        project: _project,
                        existing: existing,
                        initialStage: initialStage,
                        saveEntry: SaveProjectNoteEntry(repository),
                        deleteEntry: DeleteProjectNoteEntry(repository),
                      ),
                    ),
                  );
                },
                child: const Text('打开编辑器'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('打开编辑器'));
  await tester.pumpAndSettle();
  return session;
}

class _Notes implements ProjectNoteRepositoryPort {
  final saves = <ProjectNoteEntry>[];
  final deletes = <int>[];
  final saveContexts = <Object?>[];
  final deleteContexts = <Object?>[];
  final committedSaves = <ProjectNoteEntry>[];
  final committedDeletes = <int>[];
  int context = 0;
  int captureCalls = 0;
  Completer<void>? savePending;
  Completer<void>? deletePending;

  @override
  Object? captureContext() {
    captureCalls++;
    return context;
  }

  void _checkContext(Object? expectedContext) {
    if (expectedContext != null && expectedContext != context) {
      throw ProjectNoteContextChanged();
    }
  }

  @override
  Future<ProjectNoteEntry> saveEntry(
    ProjectNoteEntry entry, {
    Object? expectedContext,
  }) async {
    saves.add(entry);
    saveContexts.add(expectedContext);
    await savePending?.future;
    _checkContext(expectedContext);
    committedSaves.add(entry);
    return entry;
  }

  @override
  Future<void> deleteEntry(int id, {Object? expectedContext}) async {
    deletes.add(id);
    deleteContexts.add(expectedContext);
    await deletePending?.future;
    _checkContext(expectedContext);
    committedDeletes.add(id);
  }

  @override
  Future<List<ProjectNoteEntry>> getEntries(ProjectRecordScope scope) async =>
      [];

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
