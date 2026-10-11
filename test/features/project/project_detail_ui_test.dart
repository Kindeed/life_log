import 'package:life_log/features/photo/application/assign_photo_stage.dart';
import 'package:life_log/features/photo/domain/repositories/photo_stage_repository_port.dart';
import 'package:life_log/common/widgets/app_amount_field.dart';
import 'package:life_log/features/project/presentation/project_stages_sheet.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_edit_view.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_sheet.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_parse_service.dart';
import 'package:life_log/common/utils/money_input.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/project/presentation/project_channel_record.dart';
import 'package:life_log/features/project/presentation/project_channel_group_header.dart';
import 'package:life_log/features/project/presentation/project_channel_outline_row.dart';
import 'package:life_log/features/project/presentation/project_channel_stage_bar.dart';
import 'package:life_log/features/project/presentation/project_detail_view.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';
import 'package:life_log/features/project/application/load_project_note_entries.dart';
import 'package:life_log/features/project/application/watch_project_note_entries.dart';
import 'package:life_log/features/project/application/save_project_note_entry.dart';
import 'package:life_log/features/project/application/delete_project_note_entry.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/photo/presentation/photo_view.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/application/load_work_log_edit_draft.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/add_log_sheet.dart';

const _output = String.fromEnvironment('UI_REVIEW_DIR');
const _font = String.fromEnvironment('UI_REVIEW_FONT');
const _icons = String.fromEnvironment('UI_REVIEW_ICONS');
const _photo = String.fromEnvironment('UI_REVIEW_PHOTO');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    for (final spec in [('Roboto', _font), ('MaterialIcons', _icons)]) {
      if (spec.$2.isEmpty) continue;
      final loader = FontLoader(spec.$1);
      loader.addFont(
        Future.value(ByteData.sublistView(await File(spec.$2).readAsBytes())),
      );
      await loader.load();
    }
  });
  tearDown(() async => serviceLocator.reset());

  testWidgets(
    'project channel reads, filters and edits stage text alongside media',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.notes.entries = [
        _note(41, '设备压力偏高，已联系现场检查。', stage: '立项'),
        _note(42, '旧节点的沟通内容', stage: '旧节点'),
        _note(43, '另一项目的内容', projectId: 2),
      ];
      serviceLocator.registerSingleton<SaveProjectNoteEntry>(
        SaveProjectNoteEntry(f.notes),
      );
      serviceLocator.registerSingleton<DeleteProjectNoteEntry>(
        DeleteProjectNoteEntry(f.notes),
      );
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      expect(find.text('设备压力偏高，已联系现场检查。'), findsOneWidget);
      expect(find.text('另一项目的内容'), findsNothing);
      await tester.tap(find.byTooltip('筛选记录'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '文字'));
      await tester.pumpAndSettle();
      expect(find.text('现场耗材'), findsNothing);
      expect(
        find.byKey(const ValueKey('channel-day-2026-10-07')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      expect(find.text('3. 旧节点'), findsOneWidget);
      expect(find.textContaining('1 条文字'), findsNWidgets(2));
      await tester.tap(find.text('1. 立项'));
      await tester.pumpAndSettle();
      expect(find.text('设备压力偏高，已联系现场检查。'), findsOneWidget);
      expect(find.text('旧节点的沟通内容'), findsNothing);
      await tester.tap(find.byTooltip('写文字记录'));
      await tester.pumpAndSettle();
      expect(find.text('立项'), findsNWidgets(2));
      await tester.enterText(
        find.widgetWithText(TextFormField, '记录内容'),
        '生产安排：明早复查设备',
      );
      await tester.tap(find.text('保存记录'));
      await tester.pumpAndSettle();
      expect(f.notes.entries.last.projectStageName, '立项');
      expect(f.notes.entries.last.projectId, 1);
      await _expandRecordDay(tester, f.notes.entries.last.date);
      expect(find.text('生产安排：明早复查设备'), findsOneWidget);
      await tester.tap(find.text('生产安排：明早复查设备'));
      await tester.pumpAndSettle();
      expect(find.text('编辑文字记录'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '记录内容'),
        '生产安排：下午复查设备',
      );
      await tester.tap(find.text('保存记录'));
      await tester.pumpAndSettle();
      expect(find.text('生产安排：下午复查设备'), findsOneWidget);
      expect(find.text('生产安排：明早复查设备'), findsNothing);
    },
  );

  testWidgets('project trip action opens a new trip in the selected stage', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    serviceLocator.registerSingleton<SaveWorkLogEntry>(
      SaveWorkLogEntry(f.trips),
    );
    serviceLocator.registerSingleton<DeleteWorkLogEntry>(
      DeleteWorkLogEntry(f.trips),
    );
    serviceLocator.registerSingleton<LoadProjectEntries>(
      LoadProjectEntries(f.projects),
    );
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. 现场交付'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('添加记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录出差'));
    await tester.pumpAndSettle();
    final editor = tester.widget<AddLogSheet>(find.byType(AddLogSheet));
    expect(editor.existingEntry, isNull);
    expect(editor.initialType, WorkLogEntryType.businessTrip);
    expect(editor.initialProject?.id, 1);
    expect(editor.initialProjectStageName, '现场交付');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stage selection filters activities, photos and ledger and retains history',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.photos.entries = [
        _stagePhoto(11, '立项'),
        _stagePhoto(14, '现场交付'),
        _stagePhoto(15, null),
      ];
      f.expenses.entries = [
        _expense(12, merchant: '前期支出', amount: 100, stage: '立项'),
        _expense(16, merchant: '交付支出', amount: 50, stage: '现场交付'),
      ];
      f.evidence.entries = [
        _receipt(13, amount: 99, stage: '立项'),
        _receipt(17, amount: 30, stage: '现场交付'),
      ];
      await Future.wait([
        f.photoCubit.loadEntries(),
        f.expenseCubit.loadEntries(),
        f.evidenceCubit.loadEntries(),
      ]);
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      expect(find.textContaining('¥100.00'), findsWidgets);
      expect(find.textContaining('¥50.00'), findsWidgets);
      await tester.tap(find.text('1. 立项'));
      await tester.pumpAndSettle();
      expect(find.text('前期支出'), findsOneWidget);
      expect(find.text('交付支出'), findsNothing);
      await tester.tap(find.byTooltip('查看照片'));
      await tester.pumpAndSettle();
      expect(find.text('照片11'), findsOneWidget);
      expect(find.text('照片14'), findsNothing);
      await tester.tap(find.byTooltip('查看账目'));
      await tester.pumpAndSettle();
      expect(find.text('¥100.00'), findsWidgets);
      expect(find.text('¥99.00'), findsOneWidget);
      expect(find.text('¥50.00'), findsNothing);
      await tester.tap(find.byTooltip('返回项目记录'));
      await tester.pumpAndSettle();
      expect(find.text('立项'), findsOneWidget);
      expect(find.text('前期支出'), findsOneWidget);
      expect(find.text('交付支出'), findsNothing);
      expect(find.byTooltip('写文字记录'), findsOneWidget);
      await tester.tap(find.byTooltip('查看账目'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2. 现场交付'));
      await tester.pumpAndSettle();
      expect(find.text('交付支出'), findsOneWidget);
      expect(find.text('前期支出'), findsNothing);
      await tester.tap(find.byTooltip('返回项目记录'));
      await tester.pumpAndSettle();
      expect(find.text('现场交付'), findsOneWidget);
      expect(find.text('交付支出'), findsOneWidget);
      expect(find.text('前期支出'), findsNothing);
      await tester.tap(find.byTooltip('查看账目'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '全部阶段'));
      await tester.pumpAndSettle();
      expect(find.text('¥150.00'), findsOneWidget);
      expect(f.expenses.entries, hasLength(2));
      expect(f.photos.entries, hasLength(3));
    },
  );
  testWidgets(
    'legacy photo can be assigned to a stage with single-flight retry feedback',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      final assignments = _StageAssignments(f.photos)
        ..pending = Completer<void>();
      await tester.pumpWidget(
        _harness(f.view(assign: AssignPhotoStage(assignments))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('查看照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('批量选择'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全选'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('设置阶段'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未分阶段'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('立项').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('正在处理照片…'), findsOneWidget);
      expect(assignments.calls, 1);
      assignments.pending!.completeError(StateError('test failure'));
      await tester.pumpAndSettle();
      expect(find.text('设置照片阶段失败，请重试'), findsOneWidget);
      expect(find.text('选择了 1 张照片'), findsOneWidget);
      assignments.pending = null;
      await tester.tap(find.text('设置阶段'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未分阶段'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('立项').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(assignments.calls, 2);
      expect(f.photos.entries.single.projectStageName, '立项');
      expect(find.text('已设置 1 张照片的阶段'), findsOneWidget);
      expect(find.text('已进入选择模式'), findsNothing);
    },
  );
  testWidgets(
    'historical removed stage and unassigned photos remain reachable',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.photos.entries = [_stagePhoto(11, null), _stagePhoto(14, '旧阶段')];
      await f.photoCubit.loadEntries();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      expect(find.text('3. 旧阶段'), findsOneWidget);
      await tester.tap(find.text('未分阶段'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('查看照片'));
      await tester.pumpAndSettle();
      expect(find.text('照片11'), findsOneWidget);
      expect(find.text('照片14'), findsNothing);
    },
  );
  testWidgets(
    'ordered stage sheet appends and reorders without replacing previous names',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showProjectStagesSheet(
                  context,
                  project: f.projects.entries.single,
                  cubit: f.projectCubit,
                ),
                child: const Text('管理'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('管理'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '验收');
      await tester.tap(find.text('追加阶段'));
      await tester.pumpAndSettle();
      expect(find.text('立项'), findsOneWidget);
      expect(find.text('现场交付'), findsOneWidget);
      expect(find.text('验收'), findsOneWidget);
      await tester.tap(find.byTooltip('前移 验收'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存阶段'));
      await tester.pumpAndSettle();
      expect(f.projects.entries.single.stageNames, ['立项', '验收', '现场交付']);
      expect(find.text('项目阶段已保存，历史记录保留'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'stage save failure keeps draft for retry and locks one pending save',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.projects.savePending = Completer<void>();
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showProjectStagesSheet(
                  context,
                  project: f.projects.entries.single,
                  cubit: f.projectCubit,
                ),
                child: const Text('管理'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('管理'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '验收');
      await tester.tap(find.text('保存阶段'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '保存阶段'))
            .onPressed,
        isNull,
      );
      expect(f.projects.saveCalls, 1);
      f.projects.savePending!.completeError(StateError('保存失败'));
      await tester.pumpAndSettle();
      expect(find.text('验收'), findsOneWidget);
      expect(f.projects.entries.single.stageNames, ['立项', '现场交付']);
      f.projects.savePending = null;
      await tester.tap(find.text('保存阶段'));
      await tester.pumpAndSettle();
      expect(f.projects.entries.single.stageNames, ['立项', '现场交付', '验收']);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'amount and stage form reflows with 2x text in ${dark ? 'dark' : 'light'}',
      (tester) async {
        _phone(tester, width: 320);
        final f = await _Fixture.ready();
        _registerExpenseEditor(f);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          _harness(
            const ExpenseRecordEditView(
              initialProjectName: '项目A',
              initialProjectStageName: '现场交付',
            ),
            dark: dark,
            scale: 2,
            boundary: boundary,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('支出金额'), findsOneWidget);
        final cards = tester.widgetList<AppCard>(find.byType(AppCard)).length;
        expect(cards, 3);
        final widths = find
            .byType(AppCard)
            .evaluate()
            .map((element) => (element.renderObject! as RenderBox).size.width)
            .toSet();
        expect(widths, hasLength(1));
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          boundary,
          'stages-${dark ? 'dark' : 'light'}-amount-320-2x',
        );
        await tester.scrollUntilVisible(
          find.text('项目阶段'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          _harness(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showProjectStagesSheet(
                    context,
                    project: f.projects.entries.single,
                    cubit: f.projectCubit,
                  ),
                  child: const Text('管理'),
                ),
              ),
            ),
            dark: dark,
            scale: 2,
            boundary: boundary,
          ),
        );
        await tester.tap(find.text('管理'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          boundary,
          'stages-${dark ? 'dark' : 'light'}-manager-320-2x',
        );
      },
    );
  }
  for (final dark in [false, true]) {
    testWidgets('normal amount editor geometry ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      _phone(tester);
      final f = await _Fixture.ready();
      _registerExpenseEditor(f);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        _harness(
          const ExpenseRecordEditView(
            initialProjectName: '项目A',
            initialProjectStageName: '现场交付',
          ),
          dark: dark,
          boundary: boundary,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNWidgets(6));
      expect(tester.takeException(), isNull);
      expect(
        find
            .byType(AppCard)
            .evaluate()
            .map((element) => (element.renderObject! as RenderBox).size.width)
            .toSet(),
        hasLength(1),
      );
      await _capture(
        tester,
        boundary,
        'stages-${dark ? 'dark' : 'light'}-amount-390',
      );
    });
  }
  testWidgets(
    'amount editor preserves preselected stage and reports save before delayed refresh',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      _registerExpenseEditor(f);
      final refresh = Completer<void>();
      await tester.pumpWidget(
        _harness(
          ExpenseRecordEditView(
            initialProjectName: '项目A',
            initialProjectStageName: '立项',
            onSavedOrDeleted: () => refresh.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppAmountField),
          matching: find.byType(TextField),
        ),
        'NaN',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(f.expenses.saved, isEmpty);
      expect(find.textContaining('最多两位小数'), findsWidgets);
      await tester.enterText(
        find.descendant(
          of: find.byType(AppAmountField),
          matching: find.byType(TextField),
        ),
        '12.34',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(f.expenses.saved.single.projectStageName, '立项');
      expect(find.text('支出已保存'), findsOneWidget);
      refresh.complete();
    },
  );
  testWidgets(
    'new receipt page exposes stage and explicit optional amount currency',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      serviceLocator.registerSingleton<SaveEvidenceEntry>(
        SaveEvidenceEntry(f.evidence),
      );
      serviceLocator.registerSingleton<DeleteEvidenceEntry>(
        DeleteEvidenceEntry(f.evidence),
      );
      serviceLocator.registerSingleton<LoadProjectEntries>(
        LoadProjectEntries(f.projects),
      );
      await tester.pumpWidget(
        _harness(
          const EvidenceEditorSheet(
            asPage: true,
            initialProject: '项目A',
            initialProjectStageName: '立项',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('项目阶段'), findsOneWidget);
      expect(find.text('立项'), findsOneWidget);
      expect(find.text('凭证金额（可选）'), findsOneWidget);
      expect(find.text('CNY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final spec in [('JPY', 123.0, '123'), ('CNY', 0.001, '0.001')]) {
    testWidgets('receipt OCR retains editable amount ${spec.$1}', (
      tester,
    ) async {
      _phone(tester);
      final f = await _Fixture.ready();
      serviceLocator.registerSingleton<SaveEvidenceEntry>(
        SaveEvidenceEntry(f.evidence),
      );
      serviceLocator.registerSingleton<DeleteEvidenceEntry>(
        DeleteEvidenceEntry(f.evidence),
      );
      serviceLocator.registerSingleton<EvidenceParseService>(
        _ParsedAmount(spec.$2),
      );
      final existing = ExpenseEvidence()
        ..projectName = '项目A'
        ..evidenceDate = DateTime(2026, 10, 11)
        ..currency = spec.$1
        ..localFilePath = 'receipt-ocr-review.png';
      await tester.pumpWidget(
        _harness(EvidenceEditorSheet(asPage: true, existing: existing)),
      );
      await tester.pumpAndSettle();
      final parse = find.text('解析附件');
      await tester.scrollUntilVisible(
        parse,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(parse);
      await tester.pumpAndSettle();
      final amount = tester.widget<AppAmountField>(find.byType(AppAmountField));
      expect(amount.currency, spec.$1);
      expect(amount.controller.text, spec.$3);
      if (spec.$1 == 'JPY') {
        expect(moneyInputError(amount.controller.text, 'JPY'), isNull);
      } else {
        final save = find.text('保存修改');
        await tester.scrollUntilVisible(
          save,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(EvidenceEditorSheet), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(
          find
              .descendant(
                of: find.byType(AppFormFeedback),
                matching: find.text('请输入有效金额，最多两位小数'),
              )
              .hitTestable(),
          findsOneWidget,
        );
        expect(amount.controller.text, '0.001');
        await tester.scrollUntilVisible(
          parse,
          -250,
          scrollable: find.byType(Scrollable).first,
        );
      }
      amount.controller.text = '55';
      await tester.tap(parse);
      await tester.pumpAndSettle();
      expect(amount.controller.text, '55');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'expense and receipt amounts remain separate, with original currencies',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.expenses.entries = [
        _expense(1, amount: 200),
        _expense(2, amount: 30, currency: 'USD'),
      ];
      f.evidence.entries = [
        _receipt(3, amount: 999, status: EvidenceEntryStatus.reimbursed),
        _receipt(4),
      ];
      await f.expenseCubit.loadEntries();
      await f.evidenceCubit.loadEntries();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('查看账目'));
      await tester.pumpAndSettle();
      expect(find.text('¥200.00'), findsNWidgets(2));
      expect(find.text('USD 30.00'), findsNWidgets(2));
      expect(find.textContaining('2 笔支出 · 2 份凭证 · 1 份未报销'), findsOneWidget);
      await tester.drag(
        find.byKey(const PageStorageKey('project-ledger')),
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();
      expect(find.text('¥999.00'), findsOneWidget);
      expect(find.text('已报销'), findsOneWidget);
      expect(find.text('金额未填写'), findsOneWidget);
    },
  );

  testWidgets(
    'an expense watcher updates project activity and ledger without reopening',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.expenseCubit.start();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      f.expenses.entries = [_expense(8, merchant: '新增耗材', amount: 88)];
      f.expenses.changes.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('新增耗材'), findsOneWidget);
      await tester.tap(find.byTooltip('查看账目'));
      await tester.pumpAndSettle();
      expect(find.text('¥88.00'), findsNWidgets(2));
      f.expenses.entries = [_expense(9, merchant: '账目打开后新增支出', amount: 99)];
      f.expenses.changes.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('账目打开后新增支出'), findsOneWidget);
      expect(find.text('¥99.00'), findsNWidgets(2));
      expect(find.text('新增耗材'), findsNothing);
      await tester.tap(find.byTooltip('返回项目记录'));
      await tester.pumpAndSettle();
      expect(find.text('账目打开后新增支出'), findsOneWidget);
      expect(find.text('新增耗材'), findsNothing);
    },
  );

  testWidgets('photo watcher refreshes the open tool and channel on return', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    f.photoCubit.start();
    f.photos.entries = [_stagePhoto(11, '立项')];
    await f.photoCubit.loadEntries();
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. 立项'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('查看照片'));
    await tester.pumpAndSettle();
    expect(find.text('照片11'), findsOneWidget);

    f.photos.entries = [_stagePhoto(14, '立项'), _stagePhoto(15, '现场交付')];
    f.photos.changes.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('照片14'), findsOneWidget);
    expect(find.text('照片11'), findsNothing);
    expect(find.text('照片15'), findsNothing);
    await tester.tap(find.byTooltip('返回项目记录'));
    await tester.pumpAndSettle();
    expect(find.text('立项'), findsOneWidget);
    expect(find.text('照片14'), findsOneWidget);
    expect(find.text('照片11'), findsNothing);
    expect(find.text('照片15'), findsNothing);
    expect(find.byTooltip('写文字记录'), findsOneWidget);
  });

  for (final tool in ['查看照片', '查看账目']) {
    testWidgets('account change clears the open $tool tool before returning', (
      tester,
    ) async {
      _phone(tester);
      final f = await _Fixture.ready();
      final accounts = StreamController<void>.broadcast(sync: true);
      addTearDown(accounts.close);
      f.photos.entries = [_stagePhoto(11, '立项')];
      f.expenses.entries = [_expense(12, merchant: '旧账号采购', stage: '立项')];
      f.evidence.entries = [];
      await Future.wait([
        f.photoCubit.loadEntries(),
        f.expenseCubit.loadEntries(),
        f.evidenceCubit.loadEntries(),
      ]);
      await tester.pumpWidget(
        _harness(f.view(watchAccountScope: () => accounts.stream)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1. 立项'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(tool));
      await tester.pumpAndSettle();
      expect(find.text(tool == '查看照片' ? '照片11' : '旧账号采购'), findsOneWidget);
      final pending = Completer<List<ExpenseRecordEntry>>();
      f.expenses.pending = pending;
      f.photos.entries = [_stagePhoto(21, '现场交付')];
      accounts.add(null);
      await tester.pump();

      expect(find.text('照片11'), findsNothing);
      expect(find.text('旧账号采购'), findsNothing);
      expect(find.byTooltip('返回项目记录'), findsNothing);
      expect(find.byTooltip('添加记录'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete([_expense(22, merchant: '新账号采购', stage: '现场交付')]);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const PageStorageKey('project-activity')),
        findsOneWidget,
      );
      expect(find.byTooltip('返回项目记录'), findsNothing);
      expect(find.text('全部阶段'), findsOneWidget);
      expect(find.text('旧账号采购'), findsNothing);
      expect(find.text('照片11'), findsNothing);
      await tester.tap(find.byTooltip(tool));
      await tester.pumpAndSettle();
      expect(find.text(tool == '查看照片' ? '照片21' : '新账号采购'), findsOneWidget);
      expect(find.text('旧账号采购'), findsNothing);
      expect(find.text('照片11'), findsNothing);
      await tester.tap(find.byTooltip('返回项目记录'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('写文字记录'), findsOneWidget);
      expect(find.text('旧账号采购'), findsNothing);
      expect(find.text('照片11'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'trip watcher updates activity and trip tap opens its real editor',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      serviceLocator.registerSingleton<LoadWorkLogEditDraft>(
        LoadWorkLogEditDraft(f.trips),
      );
      serviceLocator.registerSingleton<SaveWorkLogEntry>(
        SaveWorkLogEntry(f.trips),
      );
      serviceLocator.registerSingleton<DeleteWorkLogEntry>(
        DeleteWorkLogEntry(f.trips),
      );
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      f.trips.entries = [_trip(9, '苏州现场交付')];
      f.trips.changes.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.scrollUntilVisible(
        find.text('苏州现场交付'),
        160,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('project-activity')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('苏州现场交付'), findsOneWidget);
      await tester.tap(find.text('苏州现场交付'));
      await tester.pumpAndSettle();
      expect(find.byType(AddLogSheet), findsOneWidget);
      expect(find.widgetWithText(TextField, '苏州现场交付'), findsOneWidget);
    },
  );

  testWidgets(
    'explicit project id wins over same name and renamed children keep their links',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.projects.entries = [
        const ProjectEntry(
          id: 2,
          name: '项目A',
          status: ProjectEntryStatus.archived,
        ),
        const ProjectEntry(
          id: 1,
          syncId: 'p1',
          name: '改名后的项目',
          status: ProjectEntryStatus.active,
        ),
      ];
      f.expenses.entries = [
        _expense(1, merchant: '保留关联', projectId: 1),
        _expense(2, merchant: '同名异项目', projectId: 2),
      ];
      f.evidence.entries = [_receipt(3, projectId: 2, merchant: '无关凭证')];
      await f.projectCubit.loadEntries();
      await f.expenseCubit.loadEntries();
      await f.evidenceCubit.loadEntries();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      expect(find.text('改名后的项目'), findsOneWidget);
      expect(find.text('保留关联'), findsOneWidget);
      expect(find.text('同名异项目'), findsNothing);
      expect(find.text('无关凭证'), findsNothing);
      await tester.tap(find.byTooltip('添加记录'));
      await tester.pumpAndSettle();
      expect(find.text('添加到「改名后的项目」'), findsOneWidget);
    },
  );

  testWidgets(
    'account change hides cached rows immediately through failed read and retry',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      final accounts = StreamController<void>.broadcast(sync: true);
      addTearDown(accounts.close);
      f.photos.entries = [];
      f.evidence.entries = [];
      f.notes.entries = [_note(41, '旧账号现场说明', stage: '立项')];
      await Future.wait([
        f.photoCubit.loadEntries(),
        f.evidenceCubit.loadEntries(),
      ]);
      await tester.pumpWidget(
        _harness(f.view(watchAccountScope: () => accounts.stream)),
      );
      await tester.pumpAndSettle();
      expect(find.text('旧账号现场说明'), findsOneWidget);
      expect(find.text('现场耗材'), findsOneWidget);
      final pending = Completer<List<ExpenseRecordEntry>>();
      f.expenses.pending = pending;

      accounts.add(null);
      await tester.pump();

      expect(find.text('旧账号现场说明'), findsNothing);
      expect(find.text('现场耗材'), findsNothing);
      expect(find.text('项目A'), findsNothing);
      expect(find.byTooltip('写文字记录'), findsNothing);
      expect(find.byTooltip('添加记录'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(StateError('new account read failed'));
      await tester.pumpAndSettle();

      expect(f.expenseCubit.state.entries.single.merchant, '现场耗材');
      expect(find.text('账号切换后读取项目失败，请重试。'), findsOneWidget);
      expect(find.text('旧账号现场说明'), findsNothing);
      expect(find.text('现场耗材'), findsNothing);
      expect(find.byType(Tab), findsNothing);
      f.expenses.pending = null;
      f.expenses.entries = [_expense(52, merchant: '新账号现场支出')];
      f.notes.entries = [_note(53, '新账号交付说明', stage: '现场交付')];

      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      expect(find.text('新账号现场支出'), findsOneWidget);
      expect(find.text('新账号交付说明'), findsOneWidget);
      expect(find.text('旧账号现场说明'), findsNothing);
      expect(find.text('现场耗材'), findsNothing);
      expect(find.text('账号切换后读取项目失败，请重试。'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('local archive only exposes local record additions', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    await _makeLocalArchive(f);
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('添加记录'));
    await tester.pumpAndSettle();

    expect(find.text('写文字记录'), findsOneWidget);
    expect(find.text('添加照片'), findsOneWidget);
    expect(find.text('记录出差'), findsNothing);
    expect(find.text('记录支出'), findsNothing);
    expect(find.text('添加凭证'), findsNothing);
    Navigator.of(tester.element(find.text('写文字记录'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('项目选项'));
    await tester.pumpAndSettle();

    expect(find.text('阶段管理'), findsOneWidget);
    expect(find.text('取消归档'), findsNothing);
    expect(find.text('归档项目'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuItem<String> && widget.value == 'archive',
      ),
      findsNothing,
    );
    expect(f.projects.saveCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local archive ledger opens expenses and receipts read-only', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    await _makeLocalArchive(f);
    f.expenses.entries = [_expense(12, note: '原项目采购说明')];
    f.evidence.entries = [_receipt(13, amount: 45, note: '原项目发票说明')];
    await Future.wait([
      f.expenseCubit.loadEntries(),
      f.evidenceCubit.loadEntries(),
    ]);
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('查看账目'));
    await tester.pumpAndSettle();

    for (final spec in [
      ('expense-12', '原项目采购说明', '¥260.00'),
      ('evidence-13', '原项目发票说明', '¥45.00'),
    ]) {
      final row = find.byKey(ValueKey(spec.$1));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      const explanation = '云端项目已删除，这条记录保留在本机供回看。新的出差和账目请关联到其他项目。';
      expect(find.text(explanation), findsOneWidget);
      expect(find.widgetWithText(SelectableText, spec.$2), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              widget.data?.contains(spec.$3) == true,
        ),
        findsOneWidget,
      );
      expect(find.byType(ExpenseRecordEditView), findsNothing);
      expect(find.byType(EvidenceEditorSheet), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      Navigator.of(tester.element(find.text(explanation))).pop();
      await tester.pumpAndSettle();
    }
    expect(f.expenses.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local archive activity opens historical trip read-only', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    await _makeLocalArchive(f);
    f.photos.entries = [];
    f.expenses.entries = [];
    f.evidence.entries = [];
    f.trips.entries = [_trip(31, '历史苏州交付')];
    await Future.wait([
      f.photoCubit.loadEntries(),
      f.expenseCubit.loadEntries(),
      f.evidenceCubit.loadEntries(),
    ]);
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('历史苏州交付'));
    await tester.pumpAndSettle();

    expect(find.text('云端项目已删除，这条记录保留在本机供回看。新的出差和账目请关联到其他项目。'), findsOneWidget);
    expect(find.byType(AddLogSheet), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'project deletion stops before confirmation when notes read fails',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.notes.entries = [_note(41, '删除前必须统计的文字记录')];
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      final initialReads = f.notes.reads;
      f.notes.failure = StateError('notes read failed');

      await tester.tap(find.byTooltip('项目选项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除项目'));
      await tester.pumpAndSettle();

      expect(f.notes.reads, initialReads + 1);
      expect(find.text('读取项目文字记录失败，请重试后再删除。'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(f.projects.entries, hasLength(1));
      expect(f.notes.entries, hasLength(1));
      f.notes.failure = null;
      await tester.tap(find.byTooltip('项目选项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除项目'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('删除 1 条文字记录'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('取消'),
        ),
      );
      await tester.pumpAndSettle();
      expect(f.projects.entries, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed local read retains records, reports failure and supports retry',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      f.expenses.failure = StateError('read failed');
      await f.expenseCubit.loadEntries(background: true);
      await tester.pumpAndSettle();
      expect(find.text('现场耗材'), findsOneWidget);
      expect(find.text('部分项目记录加载失败，已保留当前内容。'), findsOneWidget);
      expect(find.text('开始记录这个项目'), findsNothing);
      f.expenses.failure = null;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('部分项目记录加载失败，已保留当前内容。'), findsNothing);
      expect(find.text('现场耗材'), findsOneWidget);
    },
  );

  testWidgets(
    'refresh leaves cached content visible while local read is pending',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      final next = Completer<List<ExpenseRecordEntry>>();
      f.expenses.pending = next;
      await tester.drag(
        find.byKey(const PageStorageKey('project-activity')),
        const Offset(0, 400),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('现场耗材'), findsOneWidget);
      next.complete([_expense(1, merchant: '更新后的耗材')]);
      await tester.pumpAndSettle();
      expect(find.text('更新后的耗材'), findsOneWidget);
    },
  );

  testWidgets(
    'same-day records share one date header and filtering separates receipts',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('channel-day-2026-10-07')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('筛选记录'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '凭证'));
      await tester.pumpAndSettle();
      expect(find.text('交付发票'), findsOneWidget);
      expect(find.text('现场耗材'), findsNothing);
      await tester.tap(find.byTooltip('查看照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('返回项目记录'));
      await tester.pumpAndSettle();
      expect(find.text('交付发票'), findsOneWidget);
      expect(find.text('现场耗材'), findsNothing);
    },
  );

  testWidgets('record count follows channel filter and the current tool', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    f.notes.entries = [_note(41, '设备状态说明')];
    f.photos.entries = [_stagePhoto(11, null), _stagePhoto(14, null)];
    await f.photoCubit.loadEntries();
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    expect(_scopeCount('5 条记录'), findsOneWidget);
    await tester.tap(find.byTooltip('筛选记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '文字'));
    await tester.pumpAndSettle();
    expect(_scopeCount('1 条记录'), findsOneWidget);
    expect(find.text('设备状态说明'), findsOneWidget);
    expect(find.text('现场耗材'), findsNothing);

    await tester.tap(find.byTooltip('查看照片'));
    await tester.pumpAndSettle();
    expect(_scopeCount('2 条记录'), findsOneWidget);
    expect(find.text('照片11'), findsOneWidget);
    expect(find.text('照片14'), findsOneWidget);
    await tester.tap(find.byTooltip('查看账目'));
    await tester.pumpAndSettle();
    expect(_scopeCount('2 条记录'), findsOneWidget);
    expect(find.text('现场耗材'), findsOneWidget);
    expect(find.text('交付发票'), findsOneWidget);

    await tester.tap(find.byTooltip('返回项目记录'));
    await tester.pumpAndSettle();
    expect(_scopeCount('1 条记录'), findsOneWidget);
    expect(find.text('设备状态说明'), findsOneWidget);
    expect(find.text('现场耗材'), findsNothing);
    expect(find.text('照片11'), findsNothing);
    await tester.tap(find.byTooltip('筛选记录'));
    await tester.pumpAndSettle();
    final selected = tester.widget<CheckedPopupMenuItem<String>>(
      find.widgetWithText(CheckedPopupMenuItem<String>, '文字'),
    );
    expect(selected.checked, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large histories build visible activity and ledger cards on demand',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.expenses.entries = [
        for (var i = 0; i < 1000; i++)
          _expense(
            i,
            merchant: '支出 $i',
            date: _day.subtract(Duration(days: i)),
          ),
      ];
      await f.expenseCubit.loadEntries();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await _directoryAction(tester, '全部展开');
      expect(
        find.byType(ProjectChannelRecord).evaluate().length,
        inInclusiveRange(1, 19),
      );
      await tester.tap(find.byTooltip('查看账目'));
      await tester.pumpAndSettle();
      final visibleRows = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.startsWith('expense-');
      });
      expect(visibleRows.evaluate().length, inInclusiveRange(1, 19));
      expect(find.byKey(const ValueKey('expense-999')), findsNothing);
    },
  );

  testWidgets(
    'channel and tools retain their own history positions on return',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.expenseCubit.start();
      f.photos.entries = [for (var i = 0; i < 80; i++) _stagePhoto(i, null)];
      f.expenses.entries = [
        for (var i = 0; i < 80; i++)
          _expense(i, merchant: '历史支出$i', stage: '立项'),
      ];
      await Future.wait([
        f.photoCubit.loadEntries(),
        f.expenseCubit.loadEntries(),
      ]);
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      final channel = find.byKey(const PageStorageKey('project-activity'));
      await tester.drag(channel, const Offset(0, -500));
      await tester.pumpAndSettle();
      final channelOffset = _historyOffset(tester, 'project-activity');
      expect(channelOffset, greaterThan(0));

      for (final tool in [
        ('查看照片', 'project-photos'),
        ('查看账目', 'project-ledger'),
      ]) {
        await tester.tap(find.byTooltip(tool.$1));
        await tester.pumpAndSettle();
        final history = find.byKey(PageStorageKey(tool.$2));
        await tester.drag(history, const Offset(0, -500));
        await tester.pumpAndSettle();
        final toolOffset = _historyOffset(tester, tool.$2);
        expect(toolOffset, greaterThan(0));
        await tester.tap(find.byTooltip('返回项目记录'));
        await tester.pumpAndSettle();
        expect(
          _historyOffset(tester, 'project-activity'),
          closeTo(channelOffset, 1),
        );
        await tester.tap(find.byTooltip(tool.$1));
        await tester.pumpAndSettle();
        expect(_historyOffset(tester, tool.$2), closeTo(toolOffset, 1));
        await tester.tap(find.byTooltip('返回项目记录'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('筛选记录'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '费用'));
      await tester.pumpAndSettle();
      expect(_historyOffset(tester, 'project-activity'), 0);
      await tester.drag(channel, const Offset(0, -300));
      await tester.pumpAndSettle();
      final expenseOffset = _historyOffset(tester, 'project-activity');
      expect(expenseOffset, greaterThan(0));
      await tester.tap(find.byTooltip('筛选记录'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<String>, '全部记录'),
      );
      await tester.pumpAndSettle();
      expect(
        _historyOffset(tester, 'project-activity'),
        closeTo(channelOffset, 1),
      );
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1. 立项'));
      await tester.pumpAndSettle();
      expect(_historyOffset(tester, 'project-activity'), 0);
      await tester.drag(channel, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_historyOffset(tester, 'project-activity'), greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '全部阶段'));
      await tester.pumpAndSettle();
      expect(
        _historyOffset(tester, 'project-activity'),
        closeTo(channelOffset, 1),
      );
      await tester.tap(find.byTooltip('筛选记录'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '费用'));
      await tester.pumpAndSettle();
      expect(
        _historyOffset(tester, 'project-activity'),
        closeTo(expenseOffset, 1),
      );
      f.expenses.entries = [
        ...f.expenses.entries,
        _expense(81, merchant: 'watcher新增支出', stage: '立项'),
      ];
      f.expenses.changes.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        _historyOffset(tester, 'project-activity'),
        closeTo(expenseOffset, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month and day folders expand independently without reading data',
    (tester) async {
      _phone(tester);
      final f = await _folderFixture();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      final reads = _readCounts(f);
      expect(
        find.byKey(const ValueKey('channel-month-2026-10')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('channel-day-2026-10-07')),
        findsOneWidget,
      );
      expect(find.text('十月7日设备说明'), findsOneWidget);
      expect(find.text('十月6日生产安排'), findsNothing);
      expect(
        find.byKey(const ValueKey('channel-day-2026-09-30')),
        findsNothing,
      );
      expect(find.text('九月30日沟通'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectChannelRecord), findsNothing);
      await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-06')));
      await tester.pumpAndSettle();
      expect(find.text('十月6日生产安排'), findsOneWidget);
      expect(find.text('十月7日设备说明'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('channel-month-2026-10')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('channel-day-2026-10-06')),
        findsNothing,
      );
      expect(find.byType(ProjectChannelRecord), findsNothing);
      await tester.tap(find.byKey(const ValueKey('channel-month-2026-10')));
      await tester.pumpAndSettle();
      expect(find.text('十月6日生产安排'), findsOneWidget);
      expect(find.text('十月7日设备说明'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('channel-month-2026-09')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('channel-day-2026-09-30')),
        findsOneWidget,
      );
      expect(find.text('九月30日沟通'), findsNothing);
      await _tapChannelHeader(tester, 'channel-day-2026-09-30');
      expect(find.text('九月30日沟通'), findsOneWidget);
      expect(find.text('九月29日验收'), findsNothing);
      expect(_readCounts(f), reads);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('outline guides end at the visible month and day boundaries', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    f.notes.entries.add(_note(45, '十月7日第二条记录', stage: '立项'));
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    final reads = _readCounts(f);

    expect(_outlineRow(tester, 'channel-month-2026-10').isLastInMonth, isFalse);
    final latest = _outlineRow(tester, 'channel-day-2026-10-07');
    expect(latest.hasFollowingDay, isTrue);
    expect(latest.continuesDay, isTrue);
    expect(_outlineRow(tester, 'activity-文字-45').continuesDay, isTrue);
    expect(_outlineRow(tester, 'activity-文字-41').continuesDay, isFalse);
    expect(_outlineRow(tester, 'activity-文字-41').hasFollowingDay, isTrue);
    final foldedLastDay = _outlineRow(tester, 'channel-day-2026-10-06');
    expect(foldedLastDay.isLastInMonth, isTrue);
    expect(foldedLastDay.hasFollowingDay, isFalse);
    expect(foldedLastDay.continuesDay, isFalse);
    expect(_outlineRow(tester, 'channel-month-2026-09').isLastInMonth, isTrue);

    await _tapChannelHeader(tester, 'channel-day-2026-10-06');
    final openLastDay = _outlineRow(tester, 'channel-day-2026-10-06');
    expect(openLastDay.isLastInMonth, isFalse);
    expect(openLastDay.continuesDay, isTrue);
    final lastRecord = _outlineRow(tester, 'activity-文字-42');
    expect(lastRecord.isLastInMonth, isTrue);
    expect(lastRecord.hasFollowingDay, isFalse);
    expect(lastRecord.continuesDay, isFalse);

    await _tapChannelHeader(tester, 'channel-day-2026-10-07');
    expect(_outlineRow(tester, 'channel-day-2026-10-07').continuesDay, isFalse);
    expect(
      _outlineRow(tester, 'channel-day-2026-10-07').hasFollowingDay,
      isTrue,
    );
    expect(find.byKey(const ValueKey('activity-文字-41')), findsNothing);
    await _tapChannelHeader(tester, 'channel-month-2026-10');
    expect(_outlineRow(tester, 'channel-month-2026-10').isLastInMonth, isTrue);
    expect(find.byKey(const ValueKey('channel-day-2026-10-06')), findsNothing);
    expect(_readCounts(f), reads);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'directory controls expand all records and fold them without reads',
    (tester) async {
      _phone(tester);
      final f = await _folderFixture();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      final reads = _readCounts(f);
      await _directoryAction(tester, '全部收起');
      expect(find.byType(ProjectChannelRecord), findsNothing);
      expect(
        find.byKey(const ValueKey('channel-day-2026-10-07')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('channel-month-2026-10')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('channel-month-2026-09')),
        findsOneWidget,
      );
      await _directoryAction(tester, '全部展开');
      for (final content in ['十月7日设备说明', '十月6日生产安排', '九月30日沟通', '九月29日验收']) {
        await tester.scrollUntilVisible(
          find.text(content),
          120,
          scrollable: _channelScrollable(),
        );
        expect(find.text(content), findsOneWidget);
      }
      await _directoryAction(tester, '全部收起');
      expect(find.byType(ProjectChannelRecord), findsNothing);
      expect(_readCounts(f), reads);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stage and type filters preserve an explicitly folded day', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    f.expenses.entries = [_expense(12, merchant: '立项采购', stage: '立项')];
    await f.expenseCubit.loadEntries();
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-06')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. 立项'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('筛选记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '文字'));
    await tester.pumpAndSettle();
    expect(find.text('十月6日生产安排'), findsOneWidget);
    expect(find.text('十月7日设备说明'), findsNothing);
    expect(find.text('立项采购'), findsNothing);
    await tester.tap(find.byTooltip('筛选记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '出差'));
    await tester.pumpAndSettle();
    expect(find.text('暂无这类记录'), findsOneWidget);
    await tester.tap(find.byTooltip('筛选记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '文字'));
    await tester.pumpAndSettle();
    expect(find.text('十月6日生产安排'), findsOneWidget);
    expect(find.text('十月7日设备说明'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pumpAndSettle();
    expect(find.text('十月7日设备说明'), findsOneWidget);
    expect(find.text('十月6日生产安排'), findsOneWidget);
    expect(find.text('立项采购'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('project-stage-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '全部阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('筛选记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '全部记录'));
    await tester.pumpAndSettle();
    expect(find.text('立项采购'), findsOneWidget);
    expect(find.text('十月7日设备说明'), findsOneWidget);
    expect(find.text('九月30日沟通'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('watcher counts new records without reopening folded dates', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pumpAndSettle();
    f.notes.entries = [
      ...f.notes.entries,
      _note(45, '收起日期新增检查', date: _day),
      _note(46, '新日期生产问题', date: DateTime(2026, 10, 8)),
      _note(47, '新月份交付安排', date: DateTime(2026, 11, 1)),
    ];
    f.notes.changes.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final updatedDay = _dateHeader(tester, 'channel-day-2026-10-07');
    expect(updatedDay.recordCount, 2);
    expect(updatedDay.expanded, isFalse);
    final updatedMonth = _dateHeader(tester, 'channel-month-2026-10');
    expect(updatedMonth.recordCount, 4);
    expect(updatedMonth.dayCount, 3);
    expect(find.text('收起日期新增检查'), findsNothing);
    expect(find.text('新日期生产问题'), findsNothing);
    expect(find.text('新月份交付安排'), findsNothing);
    expect(find.byKey(const ValueKey('channel-month-2026-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('channel-day-2026-11-01')), findsNothing);
    expect(find.byType(ProjectChannelRecord), findsNothing);
    await _tapChannelHeader(tester, 'channel-day-2026-10-07');
    expect(find.text('收起日期新增检查'), findsOneWidget);
    expect(find.text('十月7日设备说明'), findsOneWidget);
    expect(find.text('新日期生产问题'), findsNothing);
    await _tapChannelHeader(tester, 'channel-day-2026-10-08');
    expect(find.text('新日期生产问题'), findsOneWidget);
    expect(find.text('新月份交付安排'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo and ledger returns keep folded directory selections', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-06')));
    await tester.pumpAndSettle();
    for (final tool in ['查看照片', '查看账目']) {
      await tester.tap(find.byTooltip(tool));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('返回项目记录'));
      await tester.pumpAndSettle();
      expect(find.text('十月6日生产安排'), findsOneWidget);
      expect(find.text('十月7日设备说明'), findsNothing);
      expect(
        find.byKey(const ValueKey('channel-day-2026-09-30')),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('account change resets directory expansion for the new records', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    final accounts = StreamController<void>.broadcast(sync: true);
    addTearDown(accounts.close);
    await tester.pumpWidget(
      _harness(f.view(watchAccountScope: () => accounts.stream)),
    );
    await tester.pumpAndSettle();
    await _directoryAction(tester, '全部展开');
    await _directoryAction(tester, '全部收起');
    expect(find.byType(ProjectChannelRecord), findsNothing);
    f.notes.entries = [
      _note(51, '新账号最新日期', date: DateTime(2026, 12, 2)),
      _note(52, '新账号较早日期', date: DateTime(2026, 12, 1)),
      _note(53, '新账号较早月份', date: DateTime(2026, 11, 30)),
    ];
    accounts.add(null);
    await tester.pumpAndSettle();
    expect(find.text('新账号最新日期'), findsOneWidget);
    expect(find.text('新账号较早日期'), findsNothing);
    expect(find.text('新账号较早月份'), findsNothing);
    expect(find.byKey(const ValueKey('channel-month-2026-10')), findsNothing);
    expect(
      find.byKey(const ValueKey('channel-day-2026-12-02')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('channel-day-2026-11-30')), findsNothing);
    f.notes.entries = [
      for (var i = 0; i < 80; i++)
        _note(100 + i, '切换前滚动$i', date: DateTime(2026, 12, 2)),
    ];
    f.notes.changes.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.drag(
      find.byKey(const PageStorageKey('project-activity')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(_historyOffset(tester, 'project-activity'), greaterThan(0));
    f.notes.entries = [
      for (var i = 0; i < 80; i++)
        _note(200 + i, '下一账号滚动$i', date: DateTime(2026, 12, 2)),
    ];
    accounts.add(null);
    await tester.pumpAndSettle();
    expect(_historyOffset(tester, 'project-activity'), 0);
    expect(find.text('下一账号滚动79'), findsOneWidget);
    expect(find.textContaining('切换前滚动'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UTC records group under their local calendar month and day', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    // In Asia/Shanghai this UTC instant is still September, but its displayed
    // calendar date is October 1. Other host offsets retain the same contract.
    final utc = DateTime(2026, 10, 1, 0, 30).toUtc();
    f.notes.entries = [
      _note(61, '本地十月1日UTC记录', date: utc),
      _note(62, '本地九月30日记录', date: DateTime(2026, 9, 30, 23)),
    ];
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('channel-month-2026-10')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('channel-day-2026-10-01')),
      findsOneWidget,
    );
    expect(find.text('本地十月1日UTC记录'), findsOneWidget);
    expect(find.byKey(const ValueKey('channel-month-2026-09')), findsOneWidget);
    expect(find.byKey(const ValueKey('channel-day-2026-09-30')), findsNothing);
    expect(find.text('本地九月30日记录'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initially empty channel opens its first loaded day only once', (
    tester,
  ) async {
    _phone(tester);
    final f = await _folderFixture();
    f.notes.entries = [];
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    expect(find.text('开始记录这个项目'), findsOneWidget);
    f.notes.entries = [
      _note(71, '首次加载最新日期', date: _day),
      _note(72, '首次加载较早日期', date: DateTime(2026, 10, 6)),
    ];
    f.notes.changes.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('首次加载最新日期'), findsOneWidget);
    expect(find.text('首次加载较早日期'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pumpAndSettle();
    f.notes.entries = [
      ...f.notes.entries,
      _note(73, '后续新日期默认收起', date: DateTime(2026, 10, 8)),
    ];
    f.notes.changes.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(ProjectChannelRecord), findsNothing);
    expect(_dateHeader(tester, 'channel-day-2026-10-07').expanded, isFalse);
    expect(_dateHeader(tester, 'channel-day-2026-10-08').expanded, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed initial source waits for retry before choosing latest day',
    (tester) async {
      _phone(tester);
      final f = await _folderFixture();
      f.expenses.entries = [
        _expense(81, merchant: '部分加载旧日期支出', date: DateTime(2026, 10, 5)),
      ];
      await f.expenseCubit.loadEntries();
      f.notes.failure = StateError('initial note read failed');
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      expect(find.text('部分项目记录加载失败，已保留当前内容。'), findsOneWidget);
      expect(find.text('部分加载旧日期支出'), findsNothing);
      expect(_dateHeader(tester, 'channel-month-2026-10').expanded, isFalse);
      f.notes.failure = null;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('十月7日设备说明'), findsOneWidget);
      expect(find.text('十月6日生产安排'), findsNothing);
      expect(find.text('部分加载旧日期支出'), findsNothing);
      expect(_dateHeader(tester, 'channel-day-2026-10-07').expanded, isTrue);
      expect(_dateHeader(tester, 'channel-day-2026-10-05').expanded, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unavailable batch deletion reports failure and retains selected photos',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('查看照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('批量选择'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全选'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      expect(find.text('删除照片功能暂不可用'), findsOneWidget);
      expect(find.text('选择了 1 张照片'), findsOneWidget);
    },
  );

  testWidgets(
    'photo selection drops removed ids after a local watcher refresh',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('查看照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('批量选择'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全选'));
      await tester.pumpAndSettle();
      expect(find.text('选择了 1 张照片'), findsOneWidget);
      f.photos.entries = [];
      await f.photoCubit.loadEntries(background: true);
      await tester.pumpAndSettle();
      expect(find.text('选择了 1 张照片'), findsNothing);
      expect(find.text('已进入选择模式'), findsOneWidget);
    },
  );

  for (final back in ['system', 'toolbar']) {
    testWidgets(
      '$back back cancels photo selection then returns to the channel',
      (tester) async {
        _phone(tester);
        final f = await _Fixture.ready();
        await tester.pumpWidget(_harness(f.view()));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('查看照片'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('批量选择'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('全选'));
        await tester.pumpAndSettle();
        expect(find.text('选择了 1 张照片'), findsOneWidget);

        Future<void> goBack() async {
          if (back == 'system') {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byTooltip('返回项目记录'));
          }
          await tester.pumpAndSettle();
        }

        await goBack();
        expect(find.text('选择了 1 张照片'), findsNothing);
        expect(find.text('项目照片'), findsOneWidget);
        expect(find.byType(ProjectDetailView), findsOneWidget);

        await goBack();
        expect(find.byTooltip('返回项目记录'), findsNothing);
        expect(find.byType(ProjectDetailView), findsOneWidget);
        expect(find.byTooltip('写文字记录'), findsOneWidget);
        expect(
          find.byKey(const PageStorageKey('project-activity')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('batch deletion is single flight and recovers after failure', (
    tester,
  ) async {
    _phone(tester);
    final f = await _Fixture.ready();
    final pending = Completer<void>();
    f.photos.deletePending = pending;
    serviceLocator.registerSingleton<DeletePhotoEntries>(
      DeletePhotoEntries(f.photos),
    );
    await tester.pumpWidget(_harness(f.view()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('查看照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('批量选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.text('正在处理照片…'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pump();
    expect(f.photos.deleteCalls, 1);
    pending.completeError(StateError('file-delete-failed'));
    await tester.pumpAndSettle();
    expect(find.text('选择了 1 张照片'), findsOneWidget);
    expect(find.textContaining('file-delete-failed'), findsOneWidget);
    f.photos.deletePending = null;
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(f.photos.deleteCalls, 2);
    expect(find.text('已删除 1 张照片'), findsOneWidget);
    await tester.tap(find.byTooltip('返回项目记录'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('添加记录'), findsOneWidget);
  });

  testWidgets(
    'project navigation reuses loaded cubits and keeps them alive on return',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready(ownsCubits: false);
      serviceLocator.registerSingleton<ProjectCubit>(f.projectCubit);
      serviceLocator.registerSingleton<PhotoCubit>(f.photoCubit);
      serviceLocator.registerSingleton<EvidenceCubit>(f.evidenceCubit);
      serviceLocator.registerSingleton<ExpenseRecordCubit>(f.expenseCubit);
      await tester.pumpWidget(_harness(const PhotoView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final reads = [
        f.projects.reads,
        f.photos.reads,
        f.expenses.reads,
        f.evidence.reads,
      ];
      await tester.tap(find.text('项目A').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final detail = tester.widget<ProjectDetailView>(
        find.byType(ProjectDetailView),
      );
      expect(detail.projectId, 1);
      expect(identical(detail.projectCubit, f.projectCubit), isTrue);
      expect(identical(detail.photoCubit, f.photoCubit), isTrue);
      expect(identical(detail.evidenceCubit, f.evidenceCubit), isTrue);
      expect(identical(detail.expenseCubit, f.expenseCubit), isTrue);
      expect([
        f.projects.reads,
        f.photos.reads,
        f.expenses.reads,
        f.evidence.reads,
      ], reads);
      await tester.tap(find.byTooltip('Back').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(f.projectCubit.isClosed, isFalse);
      expect(f.photoCubit.isClosed, isFalse);
      expect(f.evidenceCubit.isClosed, isFalse);
      expect(f.expenseCubit.isClosed, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  for (final dark in [false, true]) {
    for (final large in [false, true]) {
      testWidgets(
        'project directory geometry ${dark ? "dark" : "light"} ${large ? "320-2x" : "390"}',
        (tester) async {
          _phone(tester, width: large ? 320 : 390);
          final f = await _folderFixture();
          final boundary = GlobalKey();
          await tester.pumpWidget(
            _harness(
              f.view(),
              dark: dark,
              scale: large ? 2 : 1,
              boundary: boundary,
            ),
          );
          await tester.pumpAndSettle();
          final prefix =
              'folders-${dark ? "dark" : "light"}-${large ? "320-2x" : "390"}';
          expect(find.text('十月7日设备说明'), findsOneWidget);
          expect(find.text('十月6日生产安排'), findsNothing);
          expect(find.byTooltip('日期目录'), findsOneWidget);
          expect(
            tester.getSize(find.byTooltip('日期目录')).height,
            greaterThanOrEqualTo(48),
          );
          await _expectDirectoryHierarchy(tester, boundary);
          expect(tester.takeException(), isNull);
          await _capture(tester, boundary, '$prefix-default');
          await _directoryAction(tester, '全部收起');
          expect(find.byType(ProjectChannelRecord), findsNothing);
          expect(tester.takeException(), isNull);
          await _capture(tester, boundary, '$prefix-collapsed');
          await _directoryAction(tester, '全部展开');
          expect(find.text('十月7日设备说明'), findsOneWidget);
          await _expectDirectoryHierarchy(tester, boundary);
          expect(tester.takeException(), isNull);
          await _capture(tester, boundary, '$prefix-expanded');
        },
      );

      testWidgets(
        'project detail geometry ${dark ? "dark" : "light"} ${large ? "320-2x" : "390"}',
        (tester) async {
          _phone(tester, width: large ? 320 : 390);
          // Earlier fake-clock tests can leave a pending file decode cached.
          // Start each visual case with streams created in its real async zone.
          PaintingBinding.instance.imageCache
            ..clear()
            ..clearLiveImages();
          final f = await _Fixture.ready();
          f.notes.entries = [
            _note(
              41,
              '设备状态：压力读数偏高，已安排复核传感器。\n生产安排：明早检查接线，验收前补充测试结果。',
              stage: '现场交付',
            ),
          ];
          f.photos.entries = [
            PhotoEntry(
              id: 40,
              ownerUserId: null,
              createdAt: _day,
              fileName: 'site.jpg',
              filePath: _photo.isEmpty
                  ? '/tmp/lifelog-test-missing-photo.jpg'
                  : _photo,
              description: '现场接线复核完成，图中右侧端子需要在验收前再次确认。',
              deviceName: '现场照片',
              projectName: '项目A',
              projectId: 1,
              projectStageName: '现场交付',
              dateIndexed: _day,
            ),
          ];
          await f.photoCubit.loadEntries();
          final boundary = GlobalKey();
          if (_photo.isNotEmpty) {
            await tester.pumpWidget(_harness(const SizedBox.shrink()));
            final provider = ResizeImage(
              FileImage(File(_photo)),
              width: 52,
              height: 52,
              policy: ResizeImagePolicy.fit,
            );
            await tester.runAsync(() async {
              final bytes = await File(_photo).readAsBytes();
              final theme = dark ? AppTheme.dark : AppTheme.light;
              final width = large ? 320.0 : 390.0;
              final columns = large ? 2 : 3;
              final label = TextPainter(
                text: TextSpan(text: '现场照片', style: theme.textTheme.bodySmall),
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.linear(large ? 2 : 1),
                maxLines: 1,
              )..layout();
              final gridWidth =
                  ((width - 32 - (columns - 1) * 8 * width / 375) / columns)
                      .ceil();
              final gridHeight =
                  ((large ? 200 : 160) - 3 * 844 / 812 - label.height).ceil();
              label.dispose();
              for (final imageProvider in [
                provider,
                ResizeImage(
                  FileImage(File(_photo)),
                  width: gridWidth,
                  height: gridHeight,
                  policy: ResizeImagePolicy.fit,
                ),
              ]) {
                final codec = await ui.instantiateImageCodec(
                  bytes,
                  targetWidth: imageProvider.width,
                );
                final frame = await codec.getNextFrame();
                final cacheKey = await imageProvider.obtainKey(
                  ImageConfiguration.empty,
                );
                PaintingBinding.instance.imageCache.evict(cacheKey);
                PaintingBinding.instance.imageCache.putIfAbsent(
                  cacheKey,
                  () => OneFrameImageStreamCompleter(
                    Future.value(ImageInfo(image: frame.image)),
                  ),
                );
                codec.dispose();
              }
            });
            await tester.pumpWidget(const SizedBox.shrink());
          }
          await tester.runAsync(() async {
            await tester.pumpWidget(
              _harness(
                f.view(),
                dark: dark,
                scale: large ? 2 : 1,
                boundary: boundary,
              ),
            );
            if (_photo.isNotEmpty) {
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
          });
          await tester.pumpAndSettle();
          final prefix =
              '${dark ? "dark" : "light"}-${large ? "320-2x" : "390"}';
          expect(tester.takeException(), isNull);
          expect(
            tester
                .getBottomLeft(
                  find.byKey(const ValueKey('project-stage-selector')),
                )
                .dy,
            lessThanOrEqualTo(
              tester
                  .getTopLeft(
                    find.byKey(const PageStorageKey('project-activity')),
                  )
                  .dy,
            ),
          );
          expect(
            tester.getSize(find.byTooltip('筛选记录')).height,
            greaterThanOrEqualTo(48),
          );
          if (_photo.isEmpty) {
            await _settleUnavailableChannelPhoto(tester);
            expect(find.text('照片文件不可用'), findsOneWidget);
          }
          await _capture(tester, boundary, '$prefix-activity');
          expect(find.byType(Tab), findsNothing);
          for (final tool in ['查看照片', '查看账目']) {
            await tester.runAsync(() async {
              await tester.tap(find.byTooltip(tool));
              await tester.pump();
            });
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (_photo.isEmpty && tool == '查看照片') {
              await _settleUnavailablePhoto(
                tester,
                scope: find.byKey(const PageStorageKey('project-photos')),
              );
              expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
            }
            await _capture(
              tester,
              boundary,
              '$prefix-${tool == "查看照片" ? "photos" : "ledger"}',
            );
            await tester.runAsync(() async {
              await tester.tap(find.byTooltip('返回项目记录'));
              await tester.pump();
            });
            await tester.pumpAndSettle();
            if (_photo.isEmpty) {
              await _settleUnavailableChannelPhoto(tester);
              expect(find.text('照片文件不可用'), findsOneWidget);
            }
          }
          await tester.tap(find.byTooltip('添加记录'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('记录支出'), findsOneWidget);
          await _capture(tester, boundary, '$prefix-add');
          Navigator.of(tester.element(find.text('记录支出'))).pop();
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('project-stage-selector')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _capture(tester, boundary, '$prefix-stages');
        },
      );
    }
  }

  testWidgets('directory collapse remains usable with reduced motion', (
    tester,
  ) async {
    _phone(tester, width: 320);
    final f = await _folderFixture();
    await tester.pumpWidget(_harness(f.view(), scale: 2, reducedMotion: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pump();
    expect(find.text('十月7日设备说明'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('channel-day-2026-10-07')));
    await tester.pump();
    expect(find.text('十月7日设备说明'), findsOneWidget);
    await _directoryAction(tester, '全部收起');
    expect(find.byType(ProjectChannelRecord), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _phone(WidgetTester tester, {double width = 390}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

double _historyOffset(WidgetTester tester, String key) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(PageStorageKey(key)),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position
    .pixels;

Finder _channelScrollable() => find
    .descendant(
      of: find.byKey(const PageStorageKey('project-activity')),
      matching: find.byType(Scrollable),
    )
    .first;

Finder _scopeCount(String label) => find.descendant(
  of: find.byType(ProjectChannelStageBar),
  matching: find.text(label),
);

ProjectChannelGroupHeader _dateHeader(WidgetTester tester, String key) =>
    tester.widget<ProjectChannelGroupHeader>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(ProjectChannelGroupHeader),
      ),
    );

ProjectChannelOutlineRow _outlineRow(WidgetTester tester, String key) =>
    tester.widget<ProjectChannelOutlineRow>(find.byKey(ValueKey(key)));

Future<void> _expectDirectoryHierarchy(
  WidgetTester tester,
  GlobalKey boundary,
) async {
  final month = find.byKey(const ValueKey('channel-month-2026-10'));
  final day = find.byKey(const ValueKey('channel-day-2026-10-07'));
  final monthTitle = find.descendant(
    of: month,
    matching: find.text('2026年10月'),
  );
  final dayTitle = find.descendant(of: day, matching: find.text('10月7日'));
  final record = find.descendant(
    of: find.byKey(const ValueKey('activity-文字-41')),
    matching: find.byType(ProjectChannelRecord),
  );
  expect(monthTitle, findsOneWidget);
  expect(dayTitle, findsOneWidget);
  expect(record, findsOneWidget);
  expect(
    tester.getTopLeft(dayTitle).dx,
    greaterThan(tester.getTopLeft(monthTitle).dx),
  );
  expect(
    tester.getTopLeft(find.text('十月7日设备说明')).dx,
    greaterThan(tester.getTopLeft(dayTitle).dx),
  );
  expect(tester.getTopLeft(record).dx, greaterThan(tester.getTopLeft(day).dx));
  for (final heading in [month, day]) {
    final button = find.descendant(
      of: heading,
      matching: find.byType(TextButton),
    );
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  }
  final surfaceColor = Theme.of(
    tester.element(month),
  ).colorScheme.surfaceContainerLow;
  Finder surface(Finder row) => find
      .descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == surfaceColor,
        ),
      )
      .first;
  final monthSurface = tester.getRect(surface(month));
  final daySurface = tester.getRect(surface(day));
  final recordSurface = tester.getRect(
    surface(find.byKey(const ValueKey('activity-文字-41'))),
  );
  // The shared month plate has no page-background gap between its lazy rows.
  expect(monthSurface.bottom, closeTo(daySurface.top, 0.01));
  expect(daySurface.bottom, closeTo(recordSurface.top, 0.01));
  expect(daySurface.left, closeTo(monthSurface.left, 0.01));
  expect(recordSurface.right, closeTo(monthSurface.right, 0.01));
  // Geometrically touching fractional edges can still expose page-background
  // hairlines after rasterization. Check a quiet column beyond record insets.
  final origin = tester.getTopLeft(find.byKey(boundary));
  await tester.runAsync(() async {
    const ratio = 2.0;
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: ratio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      final x = ((monthSurface.right - origin.dx - 4) * ratio).floor();
      for (final edge in [monthSurface.bottom, daySurface.bottom]) {
        final y = (edge - origin.dy) * ratio;
        for (var pixelY = y.floor() - 1; pixelY <= y.ceil() + 1; pixelY++) {
          final offset = (pixelY * image.width + x) * 4;
          final actual =
              (bytes[offset + 3] << 24) |
              (bytes[offset] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset + 2];
          expect(
            actual,
            surfaceColor.toARGB32(),
            reason: 'Month surface exposes a raster gap at ($x, $pixelY)',
          );
        }
      }
    } finally {
      image.dispose();
    }
  });
}

Future<void> _directoryAction(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('日期目录'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _tapChannelHeader(WidgetTester tester, String key) async {
  final header = find.byKey(ValueKey(key));
  if (header.evaluate().isNotEmpty) {
    await tester.ensureVisible(header);
  } else {
    await tester.scrollUntilVisible(
      header,
      100,
      scrollable: _channelScrollable(),
    );
  }
  await tester.tap(header);
  await tester.pumpAndSettle();
}

Future<void> _expandRecordDay(WidgetTester tester, DateTime date) async {
  final month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
  final day = '$month-${date.day.toString().padLeft(2, '0')}';
  final monthKey = 'channel-month-$month';
  final dayKey = 'channel-day-$day';
  if (!_dateHeader(tester, monthKey).expanded) {
    await _tapChannelHeader(tester, monthKey);
  }
  if (!_dateHeader(tester, dayKey).expanded) {
    await _tapChannelHeader(tester, dayKey);
  }
}

List<int> _readCounts(_Fixture fixture) => [
  fixture.projects.reads,
  fixture.photos.reads,
  fixture.expenses.reads,
  fixture.evidence.reads,
  fixture.trips.reads,
  fixture.notes.reads,
];

Future<_Fixture> _folderFixture() async {
  final fixture = await _Fixture.ready();
  fixture.photos.entries = [];
  fixture.expenses.entries = [];
  fixture.evidence.entries = [];
  fixture.notes.entries = [
    _note(41, '十月7日设备说明', date: _day, stage: '立项'),
    _note(42, '十月6日生产安排', date: DateTime(2026, 10, 6), stage: '立项'),
    _note(43, '九月30日沟通', date: DateTime(2026, 9, 30), stage: '现场交付'),
    _note(44, '九月29日验收', date: DateTime(2026, 9, 29), stage: '现场交付'),
  ];
  await Future.wait([
    fixture.photoCubit.loadEntries(),
    fixture.expenseCubit.loadEntries(),
    fixture.evidenceCubit.loadEntries(),
  ]);
  return fixture;
}

Widget _harness(
  Widget child, {
  bool dark = false,
  double scale = 1,
  bool reducedMotion = false,
  GlobalKey? boundary,
}) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (context, _) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reducedMotion,
      ),
      child: RepaintBoundary(key: boundary, child: child!),
    ),
    onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => child),
    onGenerateInitialRoutes: (initialRoute) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      MaterialPageRoute<void>(builder: (_) => child),
    ],
  ),
);
Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (_output.isEmpty) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_output).create(recursive: true);
    await File('$_output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _settleUnavailableChannelPhoto(WidgetTester tester) async {
  final photo = find.byKey(const ValueKey('activity-照片-40'));
  if (photo.evaluate().isEmpty) {
    // Narrow, large-text records can put this lazy row beyond the cache extent.
    await tester.scrollUntilVisible(
      photo,
      160,
      scrollable: _channelScrollable(),
    );
  } else {
    await tester.ensureVisible(photo);
  }
  await tester.pumpAndSettle();
  await _settleUnavailablePhoto(tester, scope: photo);
}

Future<void> _settleUnavailablePhoto(
  WidgetTester tester, {
  required Finder scope,
}) async {
  final thumbnail = tester.widget<Image>(
    find.descendant(of: scope, matching: find.byType(Image)),
  );
  var failed = false;
  await tester.runAsync(() async {
    // The date directory can mount media after its async sources finish.
    // Reload that exact provider in the real async zone to avoid inheriting a
    // fake-clock pending decode, while retaining all project and fold state.
    await thumbnail.image.evict();
    tester.binding.buildOwner!.reassemble(tester.binding.rootElement!);
    await tester.pump();
    final ready = Completer<void>();
    final stream = thumbnail.image.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (_, _) {
        if (!ready.isCompleted) ready.complete();
      },
      onError: (Object _, StackTrace? _) {
        failed = true;
        if (!ready.isCompleted) ready.complete();
      },
    );
    stream.addListener(listener);
    try {
      await ready.future.timeout(const Duration(seconds: 10));
    } finally {
      stream.removeListener(listener);
    }
  });
  expect(failed, isTrue);
  await tester.pumpAndSettle();
}

final _day = DateTime(2026, 10, 7);
ProjectNoteEntry _note(
  int id,
  String content, {
  String? stage,
  int projectId = 1,
  DateTime? date,
}) => ProjectNoteEntry(
  id: id,
  projectId: projectId,
  projectName: '项目A',
  projectStageName: stage,
  content: content,
  date: date ?? _day,
  createdAt: date ?? _day,
  updatedAt: date ?? _day,
);
ExpenseRecordEntry _expense(
  int id, {
  String merchant = '现场耗材',
  double amount = 260,
  String currency = 'CNY',
  int? projectId = 1,
  String? stage,
  String? note,
  DateTime? date,
}) => ExpenseRecordEntry(
  id: id,
  expenseDate: date ?? _day,
  projectName: '项目A',
  projectId: projectId,
  amount: amount,
  currency: currency,
  merchant: merchant,
  category: ExpenseRecordEntryCategory.office,
  projectStageName: stage,
  note: note,
);
EvidenceEntry _receipt(
  int id, {
  double? amount,
  EvidenceEntryStatus status = EvidenceEntryStatus.pending,
  int? projectId = 1,
  String merchant = '交付发票',
  String? stage,
  String? note,
}) => EvidenceEntry(
  id: id,
  projectName: '项目A',
  projectId: projectId,
  evidenceDate: _day,
  amount: amount,
  merchant: merchant,
  status: status,
  projectStageName: stage,
  note: note,
);
WorkLogEntry _trip(int id, String location) => WorkLogEntry(
  id: id,
  date: _day,
  type: WorkLogEntryType.businessTrip,
  projectName: '项目A',
  projectId: 1,
  location: location,
);

class _Fixture {
  final projects = _Projects([
    const ProjectEntry(
      id: 1,
      name: '项目A',
      status: ProjectEntryStatus.active,
      stageNames: ['立项', '现场交付'],
    ),
  ]);
  final photos = _Photos([
    PhotoEntry(
      id: 11,
      ownerUserId: null,
      createdAt: _day,
      fileName: 'site.jpg',
      filePath: _photo.isEmpty ? '/tmp/lifelog-test-missing-photo.jpg' : _photo,
      description: '现场照片',
      deviceName: 'Pixel',
      projectName: '项目A',
      projectId: 1,
      dateIndexed: _day,
    ),
  ]);
  final expenses = _Expenses([_expense(12)]);
  final evidence = _Evidence([_receipt(13, amount: 45)]);
  final trips = _WorkLogs([]);
  final notes = _Notes([]);
  late final projectCubit = ProjectCubit(
    loadEntries: LoadProjectEntries(projects),
    watchEntries: WatchProjectEntries(projects),
    saveEntry: SaveProjectEntry(projects),
  );
  late final photoCubit = PhotoCubit(
    loadEntries: LoadPhotoEntries(photos),
    watchEntries: WatchPhotoEntries(photos),
  );
  late final expenseCubit = ExpenseRecordCubit(
    loadEntries: LoadExpenseRecordEntries(expenses),
    watchEntries: WatchExpenseRecordEntries(expenses),
  );
  late final evidenceCubit = EvidenceCubit(
    loadEntries: LoadEvidenceEntries(evidence),
    watchEntries: WatchEvidenceEntries(evidence),
  );
  static Future<_Fixture> ready({bool ownsCubits = true}) async {
    final f = _Fixture();
    await Future.wait([
      f.projectCubit.loadEntries(),
      f.photoCubit.loadEntries(),
      f.expenseCubit.loadEntries(),
      f.evidenceCubit.loadEntries(),
    ]);
    if (ownsCubits) {
      addTearDown(() async {
        await Future.wait([
          f.projectCubit.close(),
          f.photoCubit.close(),
          f.expenseCubit.close(),
          f.evidenceCubit.close(),
        ]);
      });
    }
    return f;
  }

  ProjectDetailView view({
    AssignPhotoStage? assign,
    Stream<void> Function()? watchAccountScope,
  }) => ProjectDetailView(
    assignPhotoStage: assign,
    projectName: '项目A',
    projectId: 1,
    projectCubit: projectCubit,
    photoCubit: photoCubit,
    expenseCubit: expenseCubit,
    evidenceCubit: evidenceCubit,
    loadProjectWorkLogTrips: LoadProjectWorkLogTrips(trips),
    watchWorkLogEntries: WatchWorkLogEntries(trips),
    loadProjectNotes: LoadProjectNoteEntries(notes),
    watchProjectNotes: WatchProjectNoteEntries(notes),
    watchAccountScope: watchAccountScope,
  );
}

Future<void> _makeLocalArchive(_Fixture fixture) async {
  fixture.projects.entries = [
    const ProjectEntry(
      id: 1,
      name: '项目A',
      status: ProjectEntryStatus.archived,
      isLocalArchive: true,
      stageNames: ['立项', '现场交付'],
    ),
  ];
  await fixture.projectCubit.loadEntries();
}

class _Data<T> {
  List<T> entries;
  Object? failure;
  Completer<List<T>>? pending;
  final changes = StreamController<void>.broadcast();
  _Data(this.entries);
  int reads = 0;
  Future<List<T>> getAllEntries() async {
    reads++;
    if (failure != null) throw failure!;
    return pending == null ? List.of(entries) : await pending!.future;
  }

  Stream<void> watchEntries() => changes.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Projects extends _Data<ProjectEntry> implements ProjectRepositoryPort {
  _Projects(super.entries);
  Completer<void>? savePending;
  int saveCalls = 0;
  @override
  Future<ProjectEntry> saveEntry(ProjectEntry entry) async {
    saveCalls++;
    if (savePending != null) await savePending!.future;
    entries = [entry];
    return entry;
  }
}

class _Photos extends _Data<PhotoEntry> implements PhotoRepositoryPort {
  _Photos(super.entries);
  Completer<void>? deletePending;
  int deleteCalls = 0;
  @override
  Future<void> deleteEntries(List<PhotoEntry> selected) async {
    deleteCalls++;
    if (deletePending != null) await deletePending!.future;
    final ids = selected.map((e) => e.id).toSet();
    entries = entries.where((e) => !ids.contains(e.id)).toList();
  }
}

class _Expenses extends _Data<ExpenseRecordEntry>
    implements ExpenseRecordRepositoryPort {
  _Expenses(super.entries);
  final saved = <ExpenseRecordEntry>[];
  @override
  Future<void> saveEntry(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {
    saved.add(entry);
  }
}

class _ParsedAmount extends EvidenceParseService {
  final double amount;
  _ParsedAmount(this.amount);
  @override
  Future<EvidenceParseResult> parseFile(String path) async =>
      EvidenceParseResult(rawText: 'fixture', amount: amount);
}

class _Evidence extends _Data<EvidenceEntry> implements EvidenceRepositoryPort {
  _Evidence(super.entries);
}

class _WorkLogs extends _Data<WorkLogEntry> implements WorkLogRepositoryPort {
  _WorkLogs(super.entries);
  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;
}

class _Notes extends _Data<ProjectNoteEntry>
    implements ProjectNoteRepositoryPort {
  _Notes(super.entries);
  @override
  Object? captureContext() => null;
  @override
  Future<List<ProjectNoteEntry>> getEntries(ProjectRecordScope scope) async =>
      (await getAllEntries())
          .where(
            (e) => scope.contains(
              name: e.projectName,
              id: e.projectId,
              syncId: e.projectSyncId,
            ),
          )
          .toList();
  @override
  Future<ProjectNoteEntry> saveEntry(
    ProjectNoteEntry entry, {
    Object? expectedContext,
  }) async {
    entries = [...entries.where((e) => e.id != entry.id), entry];
    changes.add(null);
    return entry;
  }

  @override
  Future<void> deleteEntry(int id, {Object? expectedContext}) async {
    entries.removeWhere((e) => e.id == id);
    changes.add(null);
  }
}

void _registerExpenseEditor(_Fixture f) {
  serviceLocator.registerSingleton<SaveExpenseRecordEntry>(
    SaveExpenseRecordEntry(f.expenses),
  );
  serviceLocator.registerSingleton<DeleteExpenseRecordEntry>(
    DeleteExpenseRecordEntry(f.expenses),
  );
  serviceLocator.registerSingleton<LoadProjectEntries>(
    LoadProjectEntries(f.projects),
  );
  serviceLocator.registerSingleton<LoadProjectWorkLogTrips>(
    LoadProjectWorkLogTrips(f.trips),
  );
}

PhotoEntry _stagePhoto(int id, String? stage) => PhotoEntry(
  id: id,
  ownerUserId: null,
  createdAt: _day,
  fileName: '$id.jpg',
  filePath: '/tmp/missing-$id.jpg',
  description: '照片$id',
  deviceName: 'Pixel',
  projectName: '项目A',
  projectId: 1,
  projectStageName: stage,
  dateIndexed: _day,
);

class _StageAssignments implements PhotoStageRepositoryPort {
  final _Photos photos;
  Completer<void>? pending;
  int calls = 0;
  _StageAssignments(this.photos);
  @override
  Future<int> assignStage(List<PhotoEntry> entries, String? stageName) async {
    calls++;
    if (pending != null) await pending!.future;
    photos.entries = photos.entries
        .map(
          (photo) => entries.any((p) => p.id == photo.id)
              ? _stagePhoto(photo.id, stageName)
              : photo,
        )
        .toList();
    return entries.length;
  }
}
