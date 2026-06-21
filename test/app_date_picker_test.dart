import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App date picker', () {
    test('uses a single themed Chinese date picker wrapper', () {
      final picker = File('lib/common/widgets/app_date_picker.dart');
      final mobileEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(picker.existsSync(), isTrue);
      final pickerSource = picker.readAsStringSync();
      expect(pickerSource, contains('showLifeLogDatePicker'));
      expect(pickerSource, contains('showDatePicker'));
      expect(pickerSource, contains('DatePickerTheme'));
      expect(pickerSource, contains("helpText: '选择日期'"));
      expect(pickerSource, contains("cancelText: '取消'"));
      expect(pickerSource, contains("confirmText: '确定'"));
      expect(mobileEntry, contains('GlobalMaterialLocalizations.delegates'));
      expect(mobileEntry, contains("Locale('zh', 'CN')"));
      expect(pubspec, contains('flutter_localizations:'));
    });

    test('blocks direct feature-level showDatePicker calls', () {
      final featureFiles = [
        'lib/features/work_log/presentation/widgets/calendar_header.dart',
        'lib/features/expense/presentation/expense_record_edit_view.dart',
        'lib/features/subscription/presentation/add_subscription_sheet.dart',
        'lib/features/evidence/presentation/evidence_editor_sheet.dart',
      ];

      for (final path in featureFiles) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains('showLifeLogDatePicker'),
          reason: '$path should use the shared app date picker',
        );
        expect(
          source,
          isNot(contains('showDatePicker(')),
          reason: '$path should not style date pickers locally',
        );
      }
    });
  });
}
