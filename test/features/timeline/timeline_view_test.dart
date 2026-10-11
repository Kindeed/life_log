import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/expense/application/load_expense_record_edit_draft.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_edit_view.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/timeline/presentation/timeline_cubit.dart';
import 'package:life_log/features/timeline/presentation/timeline_view.dart';

import 'timeline_test_sources.dart';

void main() {
  late TimelineTestSources sources;
  late TimelineCubit cubit;

  setUp(() {
    sources = TimelineTestSources();
    cubit = TimelineCubit(query: sources.query, pageSize: 2);
  });
  tearDown(() async {
    await cubit.close();
    await sources.close();
    await serviceLocator.reset();
  });

  Widget harness({
    Future<void> Function(BuildContext, TimelineRecord)? open,
    Future<void> Function(BuildContext, TimelineFilter)? create,
    bool dark = false,
    double textScale = 1,
  }) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: TimelineView(cubit: cubit, openRecord: open, createRecord: create),
  );

  testWidgets(
    'expense failure is retryable and never shown as an empty dataset',
    (tester) async {
      sources.expense.error = StateError('database down');
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      await tester.tap(find.text('支出').first);
      await tester.pumpAndSettle();
      expect(find.text('支出读取失败，请重试。'), findsOneWidget);
      expect(find.text('暂无支出记录'), findsNothing);
      sources.expense.error = null;
      sources.expense.entries = [
        timelineExpense(1, DateTime(2026, 10, 1), currency: 'USD'),
      ];
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('支出 1'), findsOneWidget);
      expect(find.textContaining('USD'), findsOneWidget);
      expect(find.text('支出读取失败，请重试。'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'every category opens records through the same action and creates its type',
    (tester) async {
      final date = DateTime(2025, 1, 1);
      sources.work.entries = [timelineWork(1, date)];
      sources.expense.entries = [timelineExpense(1, date)];
      sources.evidence.entries = [timelineEvidence(1, date)];
      sources.subscription.entries = [timelineSubscription(1, date)];
      final opened = <TimelineFilter>[];
      final created = <TimelineFilter>[];
      await tester.pumpWidget(
        harness(
          open: (context, record) async {
            opened.add(record.type);
          },
          create: (context, type) async {
            created.add(type);
          },
        ),
      );
      await tester.pumpAndSettle();
      for (final filter in [
        TimelineFilter.work,
        TimelineFilter.expense,
        TimelineFilter.evidence,
        TimelineFilter.subscription,
      ]) {
        await tester.tap(find.text(filter.label).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppCard).first);
        await tester.pumpAndSettle();
        expect(opened.last, filter);
        expect(cubit.state.filter, filter);
        await tester.tap(find.byTooltip('新增记录'));
        await tester.pumpAndSettle();
        expect(created.last, filter);
      }
      expect(opened.length, 4);
      expect(created.length, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all-types add sheet preserves a single explicit record type choice',
    (tester) async {
      TimelineFilter? created;
      await tester.pumpWidget(
        harness(
          create: (context, type) async {
            created = type;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('新增记录'));
      await tester.pumpAndSettle();
      expect(find.text('记录工时'), findsOneWidget);
      expect(find.text('记录支出'), findsOneWidget);
      expect(find.text('添加凭证'), findsOneWidget);
      expect(find.text('添加订阅'), findsOneWidget);
      await tester.tap(find.text('记录支出'));
      await tester.pumpAndSettle();
      expect(created, TimelineFilter.expense);
      expect(cubit.state.filter, TimelineFilter.all);
    },
  );

  testWidgets(
    'expense category opens the real editor and refreshes after saving',
    (tester) async {
      sources.expense.entries = [
        timelineExpense(1, DateTime(2025, 1, 1), currency: 'USD'),
      ];
      serviceLocator.registerSingleton(
        LoadExpenseRecordEditDraft(sources.expense),
      );
      serviceLocator.registerSingleton(SaveExpenseRecordEntry(sources.expense));
      serviceLocator.registerSingleton(
        DeleteExpenseRecordEntry(sources.expense),
      );
      serviceLocator.registerSingleton(LoadProjectWorkLogTrips(sources.work));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => harness(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('支出').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('支出 1'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseRecordEditView), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, '商家／用途'), '修改后的支出');
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseRecordEditView), findsNothing);
      expect(find.text('修改后的支出'), findsOneWidget);
      expect(cubit.state.filter, TimelineFilter.expense);
      expect(sources.expense.entries.single.currency, 'USD');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'page-sized records remain lazy and loading more does not repeat DB reads',
    (tester) async {
      sources.expense.entries = List.generate(
        1000,
        (index) => timelineExpense(index + 1, DateTime(2026, 10, 1)),
      );
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(find.byType(AppCard).evaluate().length, lessThanOrEqualTo(2));
      expect(find.text('支出 1000'), findsOneWidget);
      expect(find.text('支出 1'), findsNothing);
      final initialReads = sources.expense.reads;
      await tester.ensureVisible(find.text('加载更多（已显示 2 / 1000 条）'));
      await tester.tap(find.text('加载更多（已显示 2 / 1000 条）'));
      await tester.pumpAndSettle();
      expect(cubit.state.visibleCount, 4);
      expect(sources.expense.reads, initialReads);
      expect(find.byType(AppCard).evaluate().length, lessThan(100));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cached refresh failure retains category rows with a visible retry',
    (tester) async {
      sources.expense.entries = [timelineExpense(1, DateTime(2026, 10, 1))];
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      await tester.tap(find.text('支出').first);
      await tester.pumpAndSettle();
      sources.expense.error = StateError('later failure');
      await cubit.refresh(sources: {TimelineFilter.expense});
      await tester.pumpAndSettle();
      expect(find.text('支出 1'), findsOneWidget);
      expect(find.text('支出未能更新，当前显示已读取的记录。'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    },
  );

  testWidgets('refresh and visible failure preserve an already scrolled list', (
    tester,
  ) async {
    sources.expense.entries = List.generate(
      50,
      (index) => timelineExpense(index + 1, DateTime(2026, 10, 1)),
    );
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    cubit.selectFilter(TimelineFilter.expense);
    for (var index = 0; index < 10; index++) {
      cubit.loadMore();
    }
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final before = scrollable.position.pixels;
    expect(before, greaterThan(0));
    sources.expense.error = StateError('cached failure');
    await cubit.refresh(sources: {TimelineFilter.expense});
    await tester.pumpAndSettle();
    final after = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(after.position.pixels, closeTo(before, 1));
    expect(find.text('支出未能更新，当前显示已读取的记录。'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'narrow 2x text layout remains usable in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 740);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        sources.expense.entries = [
          timelineExpense(1, DateTime(2026, 10, 1), currency: 'USD'),
        ];
        await tester.pumpWidget(harness(dark: dark, textScale: 2));
        await tester.pumpAndSettle();
        expect(find.text('全部记录'), findsOneWidget);
        expect(find.text('全部日期'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('支出').first);
        await tester.pumpAndSettle();
        expect(find.text('支出 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        cubit.selectRange(
          TimelineDateRange(DateTime(2026, 1, 1), DateTime(2026, 12, 31)),
        );
        await tester.pumpAndSettle();
        expect(find.text('清除日期筛选'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('清除日期筛选'));
        await tester.pumpAndSettle();
        expect(find.text('全部日期'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
