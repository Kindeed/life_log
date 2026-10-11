import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_status_colors.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_pill.dart';
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
import 'package:life_log/features/photo/presentation/photo_view.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/project/presentation/project_status_badge.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('project lifecycle badge uses shared status roles dark=$dark', (
      tester,
    ) async {
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                for (final status in ProjectEntryStatus.values)
                  ProjectStatusBadge(status: status),
              ],
            ),
          ),
        ),
      );
      for (final status in ProjectEntryStatus.values) {
        final badge = find.byWidgetPredicate(
          (widget) => widget is ProjectStatusBadge && widget.status == status,
        );
        final pill = tester.widget<AppPill>(
          find.descendant(of: badge, matching: find.byType(AppPill)),
        );
        expect(pill.label, status.label);
        expect(
          pill.color,
          status == ProjectEntryStatus.active
              ? theme.semanticColors.project
              : theme.colorScheme.onSurfaceVariant,
        );
        final colors = AppStatusColors.fromTint(theme, pill.color);
        expect(
          AppStatusColors.contrast(colors.foreground, colors.container),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(tester.takeException(), isNull);
    });

    for (final spec in [
      (width: 390.0, scale: 1.0),
      (width: 320.0, scale: 2.0),
    ]) {
      testWidgets(
        'real project list retains lifecycle, stage count and record context '
        'dark=$dark width=${spec.width} scale=${spec.scale}',
        (tester) async {
          await _show(tester, dark: dark, width: spec.width, scale: spec.scale);

          final active = await _card(tester, '进行中项目');
          expect(_textIn(active, '进行中'), findsOneWidget);
          expect(_textIn(active, '已设 2 个阶段'), findsOneWidget);
          expect(_textIn(active, '尚未添加照片或账目'), findsOneWidget);
          expect(_textIn(active, '1/2'), findsNothing);
          _insideViewport(tester, active, spec.width);

          final archived = await _card(tester, '已归档项目');
          expect(_textIn(archived, '已归档'), findsOneWidget);
          expect(_textIn(archived, '已设 1 个阶段'), findsOneWidget);
          expect(_textIn(archived, '1 份凭证 · 1 笔支出'), findsOneWidget);
          expect(_textIn(archived, '等待添加资料'), findsNothing);
          _insideViewport(tester, archived, spec.width);

          final noStages = await _card(tester, '未设阶段项目');
          expect(_textIn(noStages, '阶段未设置'), findsOneWidget);

          final photo = await _card(tester, '照片项目');
          expect(
            find.descendant(
              of: photo,
              matching: find.textContaining('最近照片 10.10 09:30'),
            ),
            findsOneWidget,
          );
          expect(_textIn(photo, '等待添加资料'), findsNothing);

          final historical = await _card(tester, '历史资料');
          expect(
            find.descendant(
              of: historical,
              matching: find.byType(ProjectStatusBadge),
            ),
            findsNothing,
          );
          expect(_textIn(historical, '1 份凭证'), findsOneWidget);
          expect(_textIn(historical, '阶段未设置'), findsNothing);
          _insideViewport(tester, historical, spec.width);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Finder _textIn(Finder parent, String text) =>
    find.descendant(of: parent, matching: find.text(text));

Future<Finder> _card(WidgetTester tester, String name) async {
  final card = find.byKey(ValueKey('project-card-$name'));
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    card,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  return card;
}

void _insideViewport(WidgetTester tester, Finder card, double width) {
  final rect = tester.getRect(card);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(width));
  for (final badge
      in find
          .descendant(of: card, matching: find.byType(ProjectStatusBadge))
          .evaluate()) {
    final badgeRect = tester.getRect(find.byWidget(badge.widget));
    expect(badgeRect.left, greaterThanOrEqualTo(rect.left));
    expect(badgeRect.right, lessThanOrEqualTo(rect.right));
  }
}

Future<void> _show(
  WidgetTester tester, {
  required bool dark,
  required double width,
  required double scale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await serviceLocator.reset();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final projects = _Projects();
  final photos = _Photos();
  final evidence = _Evidence();
  final expenses = _Expenses();
  serviceLocator.registerFactory<ProjectCubit>(
    () => ProjectCubit(
      loadEntries: LoadProjectEntries(projects),
      watchEntries: WatchProjectEntries(projects),
      saveEntry: SaveProjectEntry(projects),
    ),
  );
  serviceLocator.registerFactory<PhotoCubit>(
    () => PhotoCubit(
      loadEntries: LoadPhotoEntries(photos),
      watchEntries: WatchPhotoEntries(photos),
    ),
  );
  serviceLocator.registerFactory<EvidenceCubit>(
    () => EvidenceCubit(
      loadEntries: LoadEvidenceEntries(evidence),
      watchEntries: WatchEvidenceEntries(evidence),
    ),
  );
  serviceLocator.registerFactory<ExpenseRecordCubit>(
    () => ExpenseRecordCubit(
      loadEntries: LoadExpenseRecordEntries(expenses),
      watchEntries: WatchExpenseRecordEntries(expenses),
    ),
  );
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const PhotoView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Projects implements ProjectRepositoryPort {
  @override
  Future<List<ProjectEntry>> getAllEntries() async => const [
    ProjectEntry(
      id: 1,
      name: '进行中项目',
      status: ProjectEntryStatus.active,
      stageNames: ['立项', '现场交付', '立项 ', ' '],
    ),
    ProjectEntry(
      id: 2,
      name: '已归档项目',
      status: ProjectEntryStatus.archived,
      stageNames: ['结项'],
    ),
    ProjectEntry(id: 3, name: '未设阶段项目', status: ProjectEntryStatus.active),
    ProjectEntry(id: 4, name: '照片项目', status: ProjectEntryStatus.active),
    // Match the first named entry used when opening the project detail.
    ProjectEntry(id: 5, name: '进行中项目', status: ProjectEntryStatus.archived),
  ];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Photos implements PhotoRepositoryPort {
  @override
  Future<List<PhotoEntry>> getAllEntries() async => [
    PhotoEntry(
      id: 1,
      ownerUserId: null,
      createdAt: DateTime(2026, 10, 10, 9, 30),
      fileName: 'missing.jpg',
      filePath: 'missing-project-list-fixture.jpg',
      description: '现场',
      deviceName: null,
      projectName: '照片项目',
      projectId: 4,
      dateIndexed: DateTime(2026, 10, 10),
    ),
  ];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Evidence implements EvidenceRepositoryPort {
  @override
  Future<List<EvidenceEntry>> getAllEntries() async => [
    for (final name in ['已归档项目', '历史资料'])
      EvidenceEntry(
        id: name == '已归档项目' ? 1 : 2,
        projectName: name,
        evidenceDate: DateTime(2026, 10, 9),
      ),
  ];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Expenses implements ExpenseRecordRepositoryPort {
  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async => [
    ExpenseRecordEntry(
      id: 1,
      projectName: '已归档项目',
      expenseDate: DateTime(2026, 10, 8),
      amount: 10,
    ),
  ];
  @override
  Stream<void> watchEntries() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
