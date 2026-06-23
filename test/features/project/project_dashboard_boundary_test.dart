import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project dashboard boundary', () {
    test(
      'project detail is a dashboard with four overview and record tabs',
      () {
        final source = File(
          'lib/features/photo/presentation/project_gallery_view.dart',
        ).readAsStringSync();

        expect(source, contains('TabController(length: 4'));
        expect(source, contains("text: '概览'"));
        expect(source, contains("text: '时间线'"));
        expect(source, contains("text: '照片'"));
        expect(source, contains("text: '凭证'"));
        expect(
          source,
          isNot(contains("Tab(icon: Icon(Icons.payments_rounded)")),
        );
        expect(source, contains('_buildEvidenceAndExpenseList'));
        expect(source, contains("'事件日期'"));
        expect(source, contains("'导入日期'"));
        expect(source, contains('_timelineSortMode'));
        expect(source, contains('capturedAt ?? entry.createdAt'));
        expect(source, contains('entry.createdAt ?? entry.evidenceDate'));
        expect(source, contains('entry.createdAt ?? entry.expenseDate'));
        expect(source, contains('_buildProjectOverview'));
        expect(source, contains('_buildProjectTimeline'));
        expect(source, contains('PhotoEntry'));
        expect(source, contains('EvidenceEntry'));
        expect(source, contains('ExpenseRecordEntry'));
        expect(source, contains('WorkLogEntry'));
        expect(source, contains('LoadProjectWorkLogTrips'));
        expect(source, contains('includeUnlinked: true'));
        expect(source, contains("type: '出差'"));
        expect(source, contains('entriesForProjectTrips'));
        expect(source, contains('疑似重复'));
        expect(source, contains('添加项目费用'));
        expect(source, contains('evidenceDisplayTitle(legacyItem)'));
        expect(source, contains('evidenceDisplaySubtitle(legacyItem)'));
        expect(source, isNot(contains('PhotoItem')));
        expect(source, isNot(contains('SyncService')));
        expect(source, isNot(contains('remoteStoragePath')));
      },
    );
  });
}
