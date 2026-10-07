import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_press_feedback.dart';
import 'package:life_log/common/widgets/app_tab_header.dart';
import 'package:life_log/core/di/service_locator.dart';
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
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/project/application/create_project_entry.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/shell/presentation/tabs_controller.dart';
import 'package:life_log/features/shell/presentation/tabs_view.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_day_metadata.dart';
import 'package:life_log/features/work_log/presentation/widgets/day_cell.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';
import 'package:table_calendar/table_calendar.dart';

const _reviewDirectory = String.fromEnvironment('UI_REVIEW_DIR');
const _reviewFont = String.fromEnvironment('UI_REVIEW_FONT');
const _reviewIcons = String.fromEnvironment('UI_REVIEW_ICONS');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    for (final entry in {
      'Roboto': _reviewFont,
      'MaterialIcons': _reviewIcons,
    }.entries) {
      if (entry.value.isNotEmpty) {
        final font = FontLoader(entry.key);
        font.addFont(
          Future.value(
            ByteData.sublistView(await File(entry.value).readAsBytes()),
          ),
        );
        await font.load();
      }
    }
  });
  tearDown(() async => serviceLocator.reset());

  testWidgets(
    'a recorded day keeps festival, overtime, holiday and multiple-entry information',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 52,
              height: 76,
              child: DayCell(
                day: DateTime(2026, 9, 25),
                focusedDay: DateTime(2026, 9),
                selectedDay: DateTime(2026, 9, 28),
                calendarFormat: CalendarFormat.month,
                event: WorkLogEntry(
                  id: 1,
                  date: DateTime(2026, 9, 25),
                  type: WorkLogEntryType.work,
                  overtimeHours: 2,
                ),
                entryCount: 2,
                metadata: WorkLogDayMetadata(
                  day: DateTime(2026, 9, 25),
                  text: '中秋节',
                  kind: WorkLogDayMetadataKind.festival,
                  holidayIsWork: false,
                ),
                isDark: false,
                textPrimary: Colors.black,
              ),
            ),
          ),
        ),
      );
      expect(find.text('25'), findsOneWidget);
      expect(find.text('中秋节'), findsOneWidget);
      expect(find.text('+2h'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('休'), findsOneWidget);
      expect(find.byTooltip('2026年9月25日，中秋节，法定休息，+2h，共2条记录'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion suppresses press movement while preserving the action',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AppPressFeedback(
                child: TextButton(
                  onPressed: () => calls++,
                  child: const Text('按压'),
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('按压')),
      );
      await tester.pump();
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 1);
      expect(scale.duration, Duration.zero);
      await gesture.up();
      expect(calls, 1);
    },
  );

  testWidgets('reduced motion switches tabs without an intermediate page', (
    tester,
  ) async {
    _phone(tester, 390);
    _register();
    await tester.pumpWidget(_harness(reduceMotion: true));
    await tester.pumpAndSettle();
    final tabs = serviceLocator<TabsController>();
    final pages = tester.widget<PageView>(find.byType(PageView).first);
    tabs.goToMore();
    await tester.pump();
    expect(pages.controller!.page, 2);
    tabs.goToWork();
    await tester.pump();
    expect(pages.controller!.page, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a requested tab stays selected through intermediate animation frames',
    (tester) async {
      _phone(tester, 390);
      _register();
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final tabs = serviceLocator<TabsController>();
      final selected = <int>[];
      tabs.addListener(() => selected.add(tabs.currentIndex));
      tabs.goToMore();
      await tester.pump();
      for (var frame = 0; frame < 15; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tabs.currentIndex, 2);
      }
      await tester.pumpAndSettle();
      expect(selected, [2]);
      expect(
        tester.widget<PageView>(find.byType(PageView).first).controller!.page,
        2,
      );
    },
  );

  testWidgets(
    'project thumbnails use bounded decoding and retain photo-only projects',
    (tester) async {
      _phone(tester, 390);
      _register(
        photoEntries: [
          for (var id = 1; id <= 6; id++)
            PhotoEntry(
              id: id,
              ownerUserId: null,
              createdAt: DateTime(2026, 10, 7, id),
              fileName: '$id.jpg',
              filePath: '/fixture-missing/$id.jpg',
              description: '照片 $id',
              deviceName: '手机',
              projectName: id <= 4
                  ? '仅照片项目'
                  : id == 5
                  ? '单张封面'
                  : null,
              projectId: null,
              dateIndexed: DateTime(2026, 10, 7),
            ),
        ],
      );
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      serviceLocator<TabsController>().goToProject();
      await tester.pumpAndSettle();
      expect(find.text('仅照片项目'), findsOneWidget);
      expect(find.text('单张封面'), findsOneWidget);
      expect(find.text('Default'), findsNothing);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, greaterThanOrEqualTo(5));
      for (final image in images) {
        expect(image.image, isA<ResizeImage>());
        final decodedWidth = (image.image as ResizeImage).width!;
        expect(decodedWidth, inInclusiveRange(1, 110));
      }
      await tester.enterText(find.byType(TextField).first, '仅照片');
      await tester.pumpAndSettle();
      expect(find.text('仅照片项目'), findsOneWidget);
      expect(find.text('单张封面'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid navigation taps retain the last destination and allow later swipes',
    (tester) async {
      _phone(tester, 390);
      _register();
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final tabs = serviceLocator<TabsController>();
      tabs.goToMore();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      tabs.goToWork();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      tabs.goToProject();
      await tester.pumpAndSettle();
      expect(tabs.currentIndex, 1);
      expect(
        tester.widget<PageView>(find.byType(PageView).first).controller!.page,
        1,
      );
      await tester.drag(find.byType(PageView), const Offset(-390, 0));
      await tester.pumpAndSettle();
      expect(tabs.currentIndex, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a press interrupted by disabling recovers without activating', (
    tester,
  ) async {
    var enabled = true;
    var calls = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AppPressFeedback(
                enabled: enabled,
                child: TextButton(
                  onPressed: enabled ? () => calls++ : null,
                  child: const Text('保存'),
                ),
              );
            },
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('保存')),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.98,
    );
    update(() => enabled = false);
    await tester.pump();
    await gesture.up();
    update(() => enabled = true);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(calls, 0);
  });

  testWidgets('the first calendar frame updates when cached metadata arrives', (
    tester,
  ) async {
    _phone(tester, 390);
    _register();
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text('白露'), findsOneWidget);
    expect(find.text('秋分'), findsOneWidget);
    expect(find.text('中秋节'), findsOneWidget);
    expect(find.text('9月加班'), findsOneWidget);
    expect(find.text('4 小时'), findsOneWidget);
    final recordedSolarTerm = tester
        .widgetList<DayCell>(find.byType(DayCell))
        .singleWhere(
          (cell) => DateUtils.isSameDay(cell.day, DateTime(2026, 9, 7)),
        );
    expect(recordedSolarTerm.metadata?.kind, WorkLogDayMetadataKind.solarTerm);
    expect(recordedSolarTerm.event?.overtimeHours, 2);
    final multipleEntryDay = tester
        .widgetList<DayCell>(find.byType(DayCell))
        .singleWhere(
          (cell) => DateUtils.isSameDay(cell.day, DateTime(2026, 9, 28)),
        );
    expect(multipleEntryDay.metadata?.text, '十八');
    expect(multipleEntryDay.entryCount, 2);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'three real tabs reflow dark=$dark width=$width text=$scale',
          (tester) async {
            _phone(tester, width);
            _register();
            final boundary = GlobalKey();
            await tester.pumpWidget(
              _harness(dark: dark, scale: scale, boundary: boundary),
            );
            await tester.pumpAndSettle();
            final tabs = serviceLocator<TabsController>();
            for (final entry in {'work': 0, 'project': 1, 'more': 2}.entries) {
              tabs.changePage(entry.value);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: entry.key);
              if (entry.key == 'work') {
                final cell = find.byType(DayCell).first;
                final summary = find.ancestor(
                  of: find.text('9月加班'),
                  matching: find.byType(AppCard),
                );
                final calendar = find.ancestor(
                  of: cell,
                  matching: find.byType(AppCard),
                );
                expect(
                  tester.getSize(summary).width,
                  closeTo(tester.getSize(calendar).width, 0.1),
                );
                final size = tester.getSize(cell);
                final tile = tester.widget<AnimatedContainer>(
                  find.descendant(
                    of: cell,
                    matching: find.byType(AnimatedContainer),
                  ),
                );
                final corners =
                    (tile.decoration! as BoxDecoration).borderRadius!
                        as BorderRadius;
                expect(corners.topLeft.x, lessThan(size.width / 3));
                if (scale == 1) {
                  expect(size.height, lessThan(size.width * 1.8));
                } else {
                  expect(size.height, lessThanOrEqualTo(114));
                }
              }
              if (entry.key == 'project') {
                final summary = find.ancestor(
                  of: find.text('项目支出'),
                  matching: find.byType(AppCard),
                );
                final search = find.byType(AppTextField).first;
                expect(
                  tester.getSize(summary).width,
                  closeTo(tester.getSize(search).width, 0.1),
                );
              }
              final title = switch (entry.key) {
                'work' => '工时',
                'project' => '项目',
                _ => '更多',
              };
              final header = find.ancestor(
                of: find.text(title).hitTestable(),
                matching: find.byType(AppTabHeader),
              );
              expect(header, findsOneWidget);
              final rect = tester.getRect(header);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
              final action = tester.widget<AppTabHeader>(header).action;
              expect(
                tester.getSize(find.byWidget(action)).height,
                greaterThanOrEqualTo(48),
              );
              if (_reviewDirectory.isNotEmpty && scale == 1 && width == 390) {
                await _capture(
                  tester,
                  boundary,
                  '${entry.key}-${dark ? 'dark' : 'light'}',
                );
              }
              final scroll = find.byType(Scrollable).hitTestable().last;
              await tester.drag(scroll, const Offset(0, -500));
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${entry.key} scrolling',
              );
            }
          },
        );
      }
    }
  }

  testWidgets(
    'tab changes preserve work date, project query, filter and scroll',
    (tester) async {
      _phone(tester, 390);
      _register(longProjectList: true);
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final tabs = serviceLocator<TabsController>();
      await tester.tap(find.text('29').hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('项目').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '搜索项目'), '北辰');
      await tester.pumpAndSettle();
      await tester.tap(find.text('名称').hitTestable());
      await tester.pumpAndSettle();
      final scroll = find.byType(CustomScrollView).hitTestable().last;
      await tester.drag(scroll, const Offset(0, -260));
      await tester.pumpAndSettle();
      final element = tester.element(scroll);
      final position = Scrollable.of(element).position;
      // The PageView is an ancestor of the scroll; inspect the actual inner one.
      final inner = tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      final offset = inner.pixels;
      expect(offset, greaterThan(0));
      await tester.tap(find.text('更多').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('项目').last);
      await tester.pumpAndSettle();
      expect(inner.pixels, offset);
      expect(position.hasPixels, isTrue);
      final queryField = find
          .descendant(of: scroll, matching: find.byType(TextFormField))
          .first;
      final query = tester.widget<TextFormField>(queryField);
      expect(
        query.controller?.text ??
            tester.state<FormFieldState<String>>(queryField).value,
        '北辰',
      );
      final photo = serviceLocator<PhotoCubit>();
      expect(photo.state.searchQuery, '北辰');
      expect(photo.state.sortMode, PhotoProjectSortMode.name);
      tabs.goToWork();
      await tester.pumpAndSettle();
      expect(find.text('9月29日'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'project draft cannot disappear during a single in-flight creation',
    (tester) async {
      _phone(tester, 390);
      final project = _register(delayedCreate: true);
      final tabs = serviceLocator<TabsController>();
      tabs.goToProject();
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      await tester.tap(find.text('创建项目'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '项目名称'), '新项目');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final sheetContext = tester.element(
        find.widgetWithText(TextFormField, '项目名称'),
      );
      await Navigator.of(sheetContext).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('放弃未保存的修改？'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '创建项目').last);
      await tester.pump();
      expect(project.createCalls, 1);
      await Navigator.of(sheetContext).maybePop();
      await tester.pump();
      expect(find.text('放弃未保存的修改？'), findsNothing);
      expect(find.widgetWithText(TextFormField, '项目名称'), findsOneWidget);
      project.pending.completeError(StateError('fixture creation failure'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, '创建项目').last, findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '创建项目').last,
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late project creation does not dismiss its parent screen', (
    tester,
  ) async {
    _phone(tester, 390);
    final project = _register(delayedCreate: true);
    serviceLocator<TabsController>().goToProject();
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建项目'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '项目名称'), '新项目');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final sheetContext = tester.element(
      find.widgetWithText(TextFormField, '项目名称'),
    );
    await tester.tap(find.widgetWithText(FilledButton, '创建项目').last);
    await tester.pump();
    expect(project.createCalls, 1);
    // Route replacement can remove an editor independently of its exit guard.
    Navigator.of(sheetContext).removeRoute(ModalRoute.of(sheetContext)!);
    await tester.pumpAndSettle();
    project.pending.complete(
      const ProjectEntry(id: 4, name: '新项目', status: ProjectEntryStatus.active),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabsView), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '项目名称'), findsNothing);
    expect(find.text('创建项目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _phone(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness({
  bool dark = false,
  double scale = 1,
  bool reduceMotion = false,
  GlobalKey? boundary,
}) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduceMotion,
      ),
      child: RepaintBoundary(key: boundary, child: child!),
    ),
    home: const TabsView(),
  ),
);

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  final render =
      boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    await Directory(_reviewDirectory).create(recursive: true);
    final snapshot = await render.toImage(pixelRatio: 2);
    final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$_reviewDirectory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    snapshot.dispose();
  });
}

_ProjectPort _register({
  bool delayedCreate = false,
  bool longProjectList = false,
  List<PhotoEntry> photoEntries = const [],
}) {
  configureWorkLogFeatureDependencies(
    repository: _WorkPort(),
    initialNow: () => DateTime(2026, 9, 28),
  );
  serviceLocator.registerSingleton(TabsController());
  final project = _ProjectPort(
    delayedCreate: delayedCreate,
    longProjectList: longProjectList,
  );
  serviceLocator.registerSingleton(CreateProjectEntry(project));
  serviceLocator.registerFactory<ProjectCubit>(
    () => ProjectCubit(
      loadEntries: LoadProjectEntries(project),
      watchEntries: WatchProjectEntries(project),
      saveEntry: SaveProjectEntry(project),
    ),
  );
  final photo = _PhotoPort(photoEntries);
  // This instance is obtained by PhotoView and retained across tab switches.
  serviceLocator.registerLazySingleton<PhotoCubit>(
    () => PhotoCubit(
      loadEntries: LoadPhotoEntries(photo),
      watchEntries: WatchPhotoEntries(photo),
    ),
  );
  final evidence = _EvidencePort();
  serviceLocator.registerFactory<EvidenceCubit>(
    () => EvidenceCubit(
      loadEntries: LoadEvidenceEntries(evidence),
      watchEntries: WatchEvidenceEntries(evidence),
    ),
  );
  final expense = _ExpensePort();
  serviceLocator.registerFactory<ExpenseRecordCubit>(
    () => ExpenseRecordCubit(
      loadEntries: LoadExpenseRecordEntries(expense),
      watchEntries: WatchExpenseRecordEntries(expense),
    ),
  );
  return project;
}

class _ProjectPort implements ProjectRepositoryPort {
  final bool delayedCreate;
  final bool longProjectList;
  final pending = Completer<ProjectEntry>();
  int createCalls = 0;
  _ProjectPort({this.delayedCreate = false, this.longProjectList = false});
  @override
  Future<List<ProjectEntry>> getAllEntries() async => [
    const ProjectEntry(
      id: 1,
      name: '北辰园区现场交付',
      status: ProjectEntryStatus.active,
    ),
    const ProjectEntry(
      id: 2,
      name: '城市能源数据平台',
      status: ProjectEntryStatus.active,
    ),
    const ProjectEntry(
      id: 3,
      name: '秋季个人计划',
      status: ProjectEntryStatus.active,
    ),
    if (longProjectList)
      for (var id = 4; id <= 14; id++)
        ProjectEntry(
          id: id,
          name: '北辰现场 $id',
          status: ProjectEntryStatus.active,
        ),
  ];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  Future<ProjectEntry> ensureEntry(String name) {
    createCalls++;
    return delayedCreate
        ? pending.future
        : Future.value(
            ProjectEntry(id: 4, name: name, status: ProjectEntryStatus.active),
          );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _PhotoPort implements PhotoRepositoryPort {
  final List<PhotoEntry> entries;
  _PhotoPort(this.entries);
  @override
  Future<List<PhotoEntry>> getAllEntries() async => entries;
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _EvidencePort implements EvidenceRepositoryPort {
  @override
  Future<List<EvidenceEntry>> getAllEntries() async => [];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _ExpensePort implements ExpenseRecordRepositoryPort {
  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async => [];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _WorkPort implements WorkLogRepositoryPort {
  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async => [
    for (final day in [
      1,
      2,
      3,
      4,
      7,
      8,
      9,
      10,
      11,
      14,
      15,
      16,
      17,
      18,
      21,
      22,
      24,
      28,
      29,
    ])
      WorkLogEntry(
        id: day,
        date: DateTime(2026, 9, day),
        type: WorkLogEntryType.work,
        overtimeHours: day == 7 || day == 18 ? 2 : 0,
        note: day == 28 ? '完成园区现场联调，整理验收资料' : null,
      ),
    WorkLogEntry(
      id: 50,
      date: DateTime(2026, 9, 28),
      type: WorkLogEntryType.businessTrip,
      location: '上海',
      transport: '高铁',
      projectName: '北辰园区现场交付',
    ),
  ];
  @override
  Future<List<WorkLogEntry>> getAllEntries() =>
      getEntriesByMonth(DateTime(2026, 9));
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;
  @override
  Future<void> normalizeDuplicateDays() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
