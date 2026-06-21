import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Today presentation boundary', () {
    test('keeps TodayView under the feature presentation boundary', () {
      final featureView = File(
        'lib/features/today/presentation/today_view.dart',
      );
      final legacyView = File('lib/modules/today/today_view.dart');

      expect(featureView.existsSync(), isTrue);
      expect(legacyView.existsSync(), isFalse);
    });

    test('keeps dashboard reads on feature Cubits and launchers', () {
      final source = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();

      expect(source, contains('WorkLogTodayCubit'));
      expect(source, contains('SubscriptionTodayCubit'));
      expect(source, contains('ExpenseRecordCubit'));
      expect(source, contains('EvidenceCubit'));
      expect(source, contains('openWorkLogEditorPage'));
      expect(source, contains('openSubscriptionEditorPage'));
      expect(source, contains('openExpenseRecordEditorPage'));
      expect(source, contains('showEvidenceAddActions'));
      expect(source, isNot(contains('WorkLogController')));
      expect(source, isNot(contains('SubscriptionController')));
      expect(source, isNot(contains('ExpenseRecordController')));
      expect(source, isNot(contains('EvidenceController')));
    });

    test(
      'uses local quick-action sheets instead of global action overlays',
      () {
        final source = File(
          'lib/features/today/presentation/today_view.dart',
        ).readAsStringSync();

        expect(source, isNot(contains('AppActionSheet.show')));
        expect(source, isNot(contains('AppActionSheetItem')));
        expect(source, contains('showModalBottomSheet'));
        expect(source, contains('Navigator.of(sheetContext).pop'));
      },
    );

    test(
      'keeps the home tab focused on today instead of duplicate summaries',
      () {
        final source = File(
          'lib/features/today/presentation/today_view.dart',
        ).readAsStringSync();

        expect(source, contains('待处理'));
        expect(source, contains('最近工时'));
        expect(source, isNot(contains('AppMetricTile')));
        expect(source, isNot(contains('本月工时')));
        expect(source, isNot(contains('本月支出')));
        expect(source, isNot(contains('凭证待报销')));
        expect(source, isNot(contains("toStringAsFixed(1)}h")));
      },
    );
  });
}
