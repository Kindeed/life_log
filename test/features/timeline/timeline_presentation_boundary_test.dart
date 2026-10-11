import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'timeline owns one query-backed browse surface rather than feature pages',
    () {
      final view = File(
        'lib/features/timeline/presentation/timeline_view.dart',
      ).readAsStringSync();
      final query = File(
        'lib/features/timeline/application/timeline_query.dart',
      ).readAsStringSync();
      expect(view, contains('TimelineCubit'));
      expect(view, contains('ListView.builder'));
      expect(view, contains('findChildIndexCallback'));
      for (final retiredState in [
        'WorkLogCubit',
        'ExpenseRecordCubit',
        'EvidenceCubit',
        'SubscriptionCubit',
      ]) {
        expect(view, isNot(contains(retiredState)));
        expect(query, isNot(contains(retiredState)));
      }
      expect(query, contains('workLogs.getAllEntries()'));
      expect(query, isNot(contains('getEntriesByMonth')));
      for (final source in [view, query]) {
        expect(source, isNot(contains('DbService')));
        expect(source, isNot(contains('SyncService')));
        expect(source, isNot(contains('PhotoItem')));
        expect(source, isNot(contains('package:get/get.dart')));
      }
    },
  );

  test('records stay secondary and keep domain feature editor launchers', () {
    final tabs = File(
      'lib/features/shell/presentation/tabs_view.dart',
    ).readAsStringSync();
    final view = File(
      'lib/features/timeline/presentation/timeline_view.dart',
    ).readAsStringSync();
    expect(tabs, isNot(contains('TimelineView()')));
    expect(tabs, contains("label: '工时'"));
    expect(tabs, contains("label: '项目'"));
    expect(tabs, contains("label: '更多'"));
    for (final launcher in [
      'openWorkLogEditorPage',
      'openExpenseRecordEditorPage',
      'showEvidenceDetailSheet',
      'openSubscriptionEditorPage',
    ]) {
      expect(view, contains(launcher));
    }
    expect(view, contains("static const title = '全部记录'"));
    expect(view, contains('currency: entry.currency'));
  });
}
