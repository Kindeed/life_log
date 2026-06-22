import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project dashboard boundary', () {
    test('project detail is a dashboard with overview and record tabs', () {
      final source = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();

      expect(source, contains('TabController(length: 5'));
      expect(source, contains("text: '概览'"));
      expect(source, contains("text: '时间线'"));
      expect(source, contains("text: '照片'"));
      expect(source, contains("text: '凭证'"));
      expect(source, contains("text: '支出'"));
      expect(source, contains('_buildProjectOverview'));
      expect(source, contains('_buildProjectTimeline'));
      expect(source, contains('PhotoEntry'));
      expect(source, contains('EvidenceEntry'));
      expect(source, contains('ExpenseRecordEntry'));
      expect(source, isNot(contains('PhotoItem')));
      expect(source, isNot(contains('SyncService')));
      expect(source, isNot(contains('remoteStoragePath')));
    });
  });
}
