import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI Contract Pack', () {
    test('documents AI UI ownership, state contracts, and forbidden paths', () {
      final contract = File('docs/ui/ui-contract.md');
      final catalog = File('docs/ui/component-catalog.md');

      expect(contract.existsSync(), isTrue);
      expect(catalog.existsSync(), isTrue);

      final contractSource = contract.readAsStringSync();
      expect(contractSource, contains('Today / Records / Projects'));
      expect(contractSource, contains('UI models may edit'));
      expect(contractSource, contains('UI models must not edit'));
      expect(contractSource, contains('lib/features/*/presentation/'));
      expect(contractSource, contains('lib/common/widgets/'));
      expect(contractSource, contains('lib/common/theme/'));
      expect(contractSource, contains('lib/common/db/'));
      expect(contractSource, contains('lib/core/sync/'));
      expect(contractSource, contains('supabase/migrations/'));
      expect(contractSource, contains('Photos are local-only'));
      expect(contractSource, contains('ViewState'));
      expect(contractSource, contains('Cubit'));
      expect(contractSource, contains('Golden tests'));

      final catalogSource = catalog.readAsStringSync();
      expect(catalogSource, contains('Hero Card'));
      expect(catalogSource, contains('Summary Row'));
      expect(catalogSource, contains('Timeline Item'));
      expect(catalogSource, contains('Action Sheet'));
      expect(catalogSource, contains('Quiet Card'));
      expect(catalogSource, contains('AppCard'));
      expect(catalogSource, contains('AppListPage'));
      expect(catalogSource, contains('AppMetricGrid'));
    });

    test('provides mock state fixtures without data or sync imports', () {
      final fixture = File(
        'lib/features/today/presentation/fixtures/today_mock_state.dart',
      );

      expect(fixture.existsSync(), isTrue);
      final source = fixture.readAsStringSync();
      expect(source, contains('todayMockState'));
      expect(source, contains('TodayMockState'));
      expect(source, contains('QuickActionFixture'));
      expect(source, contains('PendingTaskFixture'));
      expect(source, contains('RecentRecordFixture'));
      expect(source, isNot(contains('/data/')));
      expect(source, isNot(contains('DbService')));
      expect(source, isNot(contains('SyncService')));
      expect(source, isNot(contains('PhotoItem')));
    });

    test('updates the handoff doc to point UI agents at the contract pack', () {
      final source = File('docs/ui_ai_handoff.md').readAsStringSync();

      expect(source, contains('docs/ui/ui-contract.md'));
      expect(source, contains('docs/ui/component-catalog.md'));
      expect(source, contains('Today / Records / Projects'));
      expect(source, contains('mock state'));
    });
  });
}
