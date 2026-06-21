import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncService bootstrap policy', () {
    test(
      'does not claim anonymous local records during login or startup sync',
      () {
        final source = File(
          'lib/common/services/sync_service.dart',
        ).readAsStringSync();

        expect(source, contains('syncAll(reason: reason)'));
        expect(
          source,
          isNot(contains('_claimUnownedRecordsThenSync')),
          reason:
              'Login/startup sync must not auto-claim anonymous local data.',
        );
        expect(
          source,
          isNot(contains('_claimUnownedRecordsForCurrentUser')),
          reason: 'Anonymous data migration must be an explicit user action.',
        );
        expect(
          source,
          isNot(contains('claimUnownedRecordsForCurrentUser()')),
          reason: 'Sync bootstrap must not call the DbService claim helper.',
        );
      },
    );
  });
}
