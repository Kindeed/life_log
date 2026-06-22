import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Timeline presentation boundary', () {
    test('owns the unified Records tab in presentation only', () {
      final sourceFile = File(
        'lib/features/timeline/presentation/timeline_view.dart',
      );

      expect(sourceFile.existsSync(), isTrue);
      final source = sourceFile.readAsStringSync();

      expect(source, contains('class TimelineView'));
      expect(source, contains('enum TimelineFilter'));
      expect(source, contains('TimelineFilter.all'));
      expect(source, contains('TimelineFilter.work'));
      expect(source, contains('TimelineFilter.expense'));
      expect(source, contains('TimelineFilter.evidence'));
      expect(source, contains('TimelineFilter.subscription'));
      expect(source, contains('AppFilterChipBar<TimelineFilter>'));
      expect(source, contains("label: '全部'"));
      expect(source, contains("label: '工时'"));
      expect(source, contains("label: '支出'"));
      expect(source, contains("label: '凭证'"));
      expect(source, contains("label: '订阅'"));
      expect(source, contains('WorkLogView'));
      expect(source, contains('EvidenceListView'));
      expect(source, contains('SubscriptionView'));
      expect(source, contains('ExpenseRecordCubit'));
      expect(source, contains('class TimelineItem'));
      expect(source, contains('class _UnifiedTimeline'));
      expect(source, contains('_groupItemsByDay'));
      expect(source, contains("typeLabel: '工时'"));
      expect(source, contains("typeLabel: '支出'"));
      expect(source, contains("typeLabel: '凭证'"));
      expect(source, contains("typeLabel: '订阅'"));
      expect(source, isNot(contains('DbService')));
      expect(source, isNot(contains('SyncService')));
      expect(source, isNot(contains('PhotoItem')));
    });

    test(
      'keeps Records as a retired secondary surface outside primary shell',
      () {
        final tabsView = File(
          'lib/features/shell/presentation/tabs_view.dart',
        ).readAsStringSync();
        final timeline = File(
          'lib/features/timeline/presentation/timeline_view.dart',
        ).readAsStringSync();

        expect(tabsView, isNot(contains("label: '记录'")));
        expect(tabsView, isNot(contains('TimelineView()')));
        expect(tabsView, isNot(contains("label: '财务'")));
        expect(tabsView, contains("label: '订阅'"));
        expect(tabsView, contains('SubscriptionView()'));
        expect(timeline, contains('SubscriptionView()'));
        expect(timeline, contains("static const title = '记录'"));
        expect(timeline, contains('title: const Text(TimelineView.title)'));
      },
    );
  });
}
