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
  });
}
