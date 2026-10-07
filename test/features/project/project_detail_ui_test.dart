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
import 'package:life_log/features/project/presentation/project_detail_view.dart';
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
      await tester.tap(find.widgetWithText(Tab, '账目'));
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
      await tester.tap(find.widgetWithText(Tab, '账目'));
      await tester.pumpAndSettle();
      expect(find.text('¥88.00'), findsNWidgets(2));
    },
  );

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
      await tester.tap(find.text('添加记录'));
      await tester.pumpAndSettle();
      expect(find.text('添加到「改名后的项目」'), findsOneWidget);
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
      expect(find.text('项目还没有动态'), findsNothing);
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
      expect(find.text('2026-10-07'), findsOneWidget);
      await tester.tap(find.byTooltip('筛选动态'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, '凭证'));
      await tester.pumpAndSettle();
      expect(find.text('交付发票'), findsOneWidget);
      expect(find.text('现场耗材'), findsNothing);
      await tester.tap(find.widgetWithText(Tab, '照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, '动态'));
      await tester.pumpAndSettle();
      expect(find.text('交付发票'), findsOneWidget);
      expect(find.text('现场耗材'), findsNothing);
    },
  );

  testWidgets(
    'large histories build visible activity and ledger cards on demand',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      f.expenses.entries = [
        for (var i = 0; i < 1000; i++) _expense(i, merchant: '支出 $i'),
      ];
      await f.expenseCubit.loadEntries();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      expect(find.byType(AppCard).evaluate().length, lessThan(20));
      await tester.tap(find.widgetWithText(Tab, '账目'));
      await tester.pumpAndSettle();
      expect(find.byType(AppCard).evaluate().length, lessThan(20));
    },
  );

  testWidgets(
    'unavailable batch deletion reports failure and retains selected photos',
    (tester) async {
      _phone(tester);
      final f = await _Fixture.ready();
      await tester.pumpWidget(_harness(f.view()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, '照片'));
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
      await tester.tap(find.widgetWithText(Tab, '照片'));
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
    await tester.tap(find.widgetWithText(Tab, '照片'));
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
    expect(find.text('添加记录'), findsOneWidget);
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
        'project detail geometry ${dark ? "dark" : "light"} ${large ? "320-2x" : "390"}',
        (tester) async {
          _phone(tester, width: large ? 320 : 390);
          final f = await _Fixture.ready();
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
            tester.getSize(find.byTooltip('筛选动态')).height,
            greaterThanOrEqualTo(48),
          );
          await _capture(tester, boundary, '$prefix-activity');
          for (final tab in ['照片', '账目']) {
            await tester.tap(find.widgetWithText(Tab, tab));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await _capture(
              tester,
              boundary,
              '$prefix-${tab == "照片" ? "photos" : "ledger"}',
            );
          }
          await tester.tap(find.text('添加记录'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('记录支出'), findsOneWidget);
          await _capture(tester, boundary, '$prefix-add');
        },
      );
    }
  }
}

void _phone(WidgetTester tester, {double width = 390}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness(
  Widget child, {
  bool dark = false,
  double scale = 1,
  GlobalKey? boundary,
}) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (context, _) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
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
  if (_photo.isNotEmpty) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
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

final _day = DateTime(2026, 10, 7);
ExpenseRecordEntry _expense(
  int id, {
  String merchant = '现场耗材',
  double amount = 260,
  String currency = 'CNY',
  int? projectId = 1,
}) => ExpenseRecordEntry(
  id: id,
  expenseDate: _day,
  projectName: '项目A',
  projectId: projectId,
  amount: amount,
  currency: currency,
  merchant: merchant,
  category: ExpenseRecordEntryCategory.office,
);
EvidenceEntry _receipt(
  int id, {
  double? amount,
  EvidenceEntryStatus status = EvidenceEntryStatus.pending,
  int? projectId = 1,
  String merchant = '交付发票',
}) => EvidenceEntry(
  id: id,
  projectName: '项目A',
  projectId: projectId,
  evidenceDate: _day,
  amount: amount,
  merchant: merchant,
  status: status,
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

  ProjectDetailView view() => ProjectDetailView(
    projectName: '项目A',
    projectId: 1,
    projectCubit: projectCubit,
    photoCubit: photoCubit,
    expenseCubit: expenseCubit,
    evidenceCubit: evidenceCubit,
    loadProjectWorkLogTrips: LoadProjectWorkLogTrips(trips),
    watchWorkLogEntries: WatchWorkLogEntries(trips),
  );
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
}

class _Evidence extends _Data<EvidenceEntry> implements EvidenceRepositoryPort {
  _Evidence(super.entries);
}

class _WorkLogs extends _Data<WorkLogEntry> implements WorkLogRepositoryPort {
  _WorkLogs(super.entries);
  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;
}
