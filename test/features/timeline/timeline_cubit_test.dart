import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/timeline/application/timeline_query.dart';
import 'package:life_log/features/timeline/domain/timeline_record.dart';
import 'package:life_log/features/timeline/presentation/timeline_cubit.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

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
  });

  test(
    'new account watches do not wait for a blocked old account watch',
    () async {
      sources.work.entries = [timelineWork(1, DateTime(2026, 10, 1))];
      cubit.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final stale = Completer<List<WorkLogEntry>>();
      addTearDown(() {
        if (!stale.isCompleted) stale.complete([]);
      });
      sources.work.read = () => stale.future;
      sources.work.changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(sources.work.reads, 2);
      sources.work.read = null;
      sources.work.entries = [timelineWork(2, DateTime(2026, 10, 2))];
      sources.scope.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.allRecords.single.key, 'work:2');
      sources.work.entries = [timelineWork(3, DateTime(2026, 10, 3))];
      sources.work.changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(stale.isCompleted, isFalse);
      expect(sources.work.reads, 4);
      expect(cubit.state.allRecords.single.key, 'work:3');
      stale.complete([timelineWork(99, DateTime(2027, 1, 1))]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.allRecords.single.key, 'work:3');
    },
  );

  test(
    'full history preserves same-day siblings and stable per-type identity',
    () async {
      sources.work.entries = [
        timelineWork(1, DateTime(2025, 1, 1)),
        timelineWork(2, DateTime(2026, 10, 11)),
        timelineWork(
          3,
          DateTime(2026, 10, 11),
          type: WorkLogEntryType.businessTrip,
        ),
        timelineWork(4, DateTime(2027, 1, 1)),
      ];
      sources.expense.entries = [timelineExpense(1, DateTime(2026, 10, 11))];
      await cubit.refresh();
      expect(cubit.state.allRecords.map((record) => record.key).toSet(), {
        'work:1',
        'work:2',
        'work:3',
        'work:4',
        'expense:1',
      });
      expect(sources.work.monthReads, 0);
      expect(cubit.state.totalCount, 5);
      expect(cubit.state.visibleCount, 2);
      cubit.loadMore();
      expect(cubit.state.visibleCount, 4);
      cubit.loadMore();
      expect(cubit.state.visibleCount, 5);
      expect(cubit.state.hasMore, isFalse);
      expect(
        sources.work.reads,
        1,
        reason: 'Display pages must not repeat full reads',
      );
    },
  );

  test(
    'inclusive date scope applies identically to every record type',
    () async {
      sources.work.entries = [
        timelineWork(1, DateTime(2026, 9, 30)),
        timelineWork(2, DateTime(2026, 10, 1)),
      ];
      sources.expense.entries = [
        timelineExpense(1, DateTime(2026, 10, 1, 23, 59)),
      ];
      sources.evidence.entries = [timelineEvidence(1, DateTime(2026, 10, 2))];
      sources.subscription.entries = [
        timelineSubscription(1, DateTime(2026, 10, 1)),
      ];
      await cubit.refresh();
      cubit.selectRange(
        TimelineDateRange(DateTime(2026, 10, 1), DateTime(2026, 10, 1)),
      );
      expect(cubit.state.totalCount, 3);
      for (final filter in [
        TimelineFilter.work,
        TimelineFilter.expense,
        TimelineFilter.subscription,
      ]) {
        cubit.selectFilter(filter);
        expect(cubit.state.totalCount, 1);
        expect(
          cubit.state.rows.whereType<TimelineRecordRow>().single.record.type,
          filter,
        );
      }
      cubit.selectFilter(TimelineFilter.evidence);
      expect(cubit.state.totalCount, 0);
      cubit.selectRange(null);
      expect(cubit.state.totalCount, 1);
      expect(sources.expense.reads, 1);
    },
  );

  test(
    'one failed source does not hide other records and retry is targeted',
    () async {
      sources.work.entries = [timelineWork(1, DateTime(2025, 1, 1))];
      sources.expense.error = StateError('unavailable');
      await cubit.refresh();
      expect(cubit.state.totalCount, 1);
      expect(cubit.state.visibleFailures.keys, [TimelineFilter.expense]);
      cubit.selectFilter(TimelineFilter.expense);
      expect(cubit.state.visibleCount, 0);
      expect(cubit.state.visibleFailures, isNotEmpty);
      sources.expense.error = null;
      sources.expense.entries = [timelineExpense(1, DateTime(2026, 10, 1))];
      await cubit.retry();
      expect(cubit.state.visibleFailures, isEmpty);
      expect(cubit.state.totalCount, 1);
      expect(sources.work.reads, 1);
      expect(sources.expense.reads, 2);
    },
  );

  test(
    'failed cached refresh keeps rows, selected range and display page',
    () async {
      sources.expense.entries = List.generate(
        5,
        (index) => timelineExpense(index + 1, DateTime(2026, 10, 1)),
      );
      await cubit.refresh();
      cubit.selectFilter(TimelineFilter.expense);
      cubit.loadMore();
      final keys = cubit.state.rows.map((row) => row.key).toList();
      sources.expense.error = StateError('later read failed');
      await cubit.refresh(sources: {TimelineFilter.expense});
      expect(cubit.state.rows.map((row) => row.key), keys);
      expect(cubit.state.visibleCount, 4);
      expect(cubit.state.visibleFailures, isNotEmpty);
      cubit.selectFilter(TimelineFilter.all);
      cubit.selectFilter(TimelineFilter.expense);
      expect(cubit.state.visibleCount, 4);
    },
  );

  test(
    'completed source is visible while another source is still loading',
    () async {
      final pending = Completer<List<WorkLogEntry>>();
      sources.work.read = () => pending.future;
      sources.expense.entries = [timelineExpense(1, DateTime(2026, 10, 1))];
      final load = cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.totalCount, 1);
      expect(cubit.state.isLoading, isTrue);
      cubit.selectFilter(TimelineFilter.expense);
      expect(cubit.state.isLoading, isFalse);
      pending.complete([]);
      await load;
    },
  );

  test(
    'owner change clears cache and starts new reads before old read completes',
    () async {
      sources.work.entries = [timelineWork(1, DateTime(2026, 10, 1))];
      cubit.start();
      await Future<void>.delayed(Duration.zero);
      final staleRead = Completer<List<WorkLogEntry>>();
      sources.work.read = () => staleRead.future;
      final oldRefresh = cubit.refresh(sources: {TimelineFilter.work});
      await Future<void>.delayed(Duration.zero);
      sources.work.read = null;
      sources.work.entries = [timelineWork(2, DateTime(2026, 10, 2))];
      sources.expense.error = StateError('new owner empty cache read failure');
      sources.scope.add(null);
      expect(
        cubit.state.allRecords,
        isEmpty,
        reason: 'Old account cache must disappear immediately',
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.allRecords.map((record) => record.key), ['work:2']);
      staleRead.complete([timelineWork(99, DateTime(2027, 1, 1))]);
      await oldRefresh;
      expect(cubit.state.allRecords.map((record) => record.key), ['work:2']);
      expect(cubit.state.failures.keys, [TimelineFilter.expense]);
    },
  );

  test('close ignores pending source completions', () async {
    final pending = Completer<List<WorkLogEntry>>();
    sources.work.read = () => pending.future;
    final load = cubit.refresh();
    await cubit.close();
    pending.complete([timelineWork(1, DateTime(2026, 10, 1))]);
    await load;
    expect(cubit.state.allRecords, isEmpty);
  });

  test(
    'watch bursts read only their changed source with one trailing refresh',
    () async {
      cubit.start();
      await Future<void>.delayed(Duration.zero);
      sources.expense.changes.add(null);
      for (var index = 0; index < 10; index++) {
        sources.expense.changes.add(null);
      }
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(sources.expense.reads, 3);
      expect(sources.work.reads, 1);
      expect(sources.evidence.reads, 1);
      expect(sources.subscription.reads, 1);
    },
  );

  test(
    'projection creates page-sized data rows without duplicating date headers',
    () {
      final records = [
        TimelineWorkRecord(timelineWork(1, DateTime(2026, 10, 1))),
        TimelineExpenseRecord(timelineExpense(1, DateTime(2026, 10, 1, 12))),
        TimelineEvidenceRecord(timelineEvidence(1, DateTime(2026, 9, 1))),
      ];
      final rows = sources.query.rows(records, limit: 2);
      expect(rows.whereType<TimelineDateRow>().length, 1);
      expect(rows.whereType<TimelineRecordRow>().length, 2);
      expect(rows.map((row) => row.key).toSet().length, rows.length);
      expect(TimelineQuery.sources, isNot(contains(TimelineFilter.all)));
    },
  );
}
