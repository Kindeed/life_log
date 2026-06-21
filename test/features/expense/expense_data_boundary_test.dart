import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseRecord data boundary', () {
    test('owns legacy data files from the feature data folder', () {
      final featureModel = File(
        'lib/features/expense/data/expense_record_model.dart',
      );
      final featureGenerated = File(
        'lib/features/expense/data/expense_record_model.g.dart',
      );
      final featureRepository = File(
        'lib/features/expense/data/expense_record_repository.dart',
      );
      final legacyModel = File('lib/modules/expense/expense_record_model.dart');
      final legacyGenerated = File(
        'lib/modules/expense/expense_record_model.g.dart',
      );
      final legacyRepository = File(
        'lib/modules/expense/expense_record_repository.dart',
      );

      expect(featureModel.existsSync(), isTrue);
      expect(featureGenerated.existsSync(), isTrue);
      expect(featureRepository.existsSync(), isTrue);
      expect(legacyModel.existsSync(), isFalse);
      expect(legacyGenerated.existsSync(), isFalse);
      expect(legacyRepository.existsSync(), isFalse);
    });

    test('infrastructure imports ExpenseRecord data through feature data', () {
      const files = {
        'lib/common/db/db_service.dart': [
          'features/expense/data/expense_record_model.dart',
        ],
        'lib/common/services/sync_service.dart': [
          'features/expense/data/expense_record_model.dart',
        ],
        'lib/common/utils/record_validators.dart': [
          'features/expense/data/expense_record_model.dart',
        ],
        'lib/features/project/application/delete_project_entry.dart': [
          'features/expense/application/load_expense_record_entries.dart',
          'features/expense/application/delete_expense_record_entry.dart',
        ],
        'lib/features/expense/expense_feature_di.dart': [
          'features/expense/data/expense_record_repository.dart',
        ],
        'lib/features/expense/data/legacy_expense_record_repository_adapter.dart':
            [
              'features/expense/data/expense_record_model.dart',
              'features/expense/data/expense_record_repository.dart',
            ],
      };

      for (final entry in files.entries) {
        final source = File(entry.key).readAsStringSync();
        final allowsConcreteRepository =
            entry.key.endsWith('expense_feature_di.dart') ||
            entry.key.endsWith('legacy_expense_record_repository_adapter.dart');

        expect(
          source,
          isNot(contains('modules/expense/expense_record_model.dart')),
          reason: '${entry.key} must not import the legacy model path.',
        );
        expect(
          source,
          isNot(contains('modules/expense/expense_record_repository.dart')),
          reason: '${entry.key} must not import the legacy repository path.',
        );
        if (!allowsConcreteRepository) {
          expect(
            source,
            isNot(
              contains('features/expense/data/expense_record_repository.dart'),
            ),
            reason:
                '${entry.key} must not import the concrete ExpenseRecord data repository outside data/DI compatibility paths.',
          );
        }
        for (final expectedImport in entry.value) {
          expect(
            source,
            contains(expectedImport),
            reason: '${entry.key} must import $expectedImport.',
          );
        }
      }

      final bindingSource = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();
      expect(
        bindingSource,
        isNot(contains('modules/expense/expense_record_model.dart')),
      );
      expect(
        bindingSource,
        isNot(contains('modules/expense/expense_record_repository.dart')),
      );
      expect(
        bindingSource,
        isNot(contains('features/expense/data/expense_record_repository.dart')),
      );
      expect(
        bindingSource,
        isNot(contains('Get.lazyPut(() => ExpenseRecordRepository')),
      );
    });

    test('presentation layer does not import the legacy Isar model', () {
      final files = Directory('lib/features/expense/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in files) {
        final source = file.readAsStringSync();

        expect(
          source,
          isNot(contains('features/expense/data/expense_record_model.dart')),
          reason:
              '${file.path} must depend on domain entries, not Isar records.',
        );
        expect(
          source,
          isNot(contains('expense_record_model.dart')),
          reason:
              '${file.path} must depend on domain entries, not Isar records.',
        );
      }
    });
  });
}
