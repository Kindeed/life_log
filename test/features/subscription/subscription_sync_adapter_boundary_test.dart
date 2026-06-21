import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subscription SyncAdapter boundary', () {
    test('Subscription cloud sync is represented as a SyncAdapter', () {
      final adapterFile = File(
        'lib/features/subscription/sync/subscription_sync_adapter.dart',
      );
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();

      expect(adapterFile.existsSync(), isTrue);

      final adapterSource = adapterFile.readAsStringSync();
      expect(adapterSource, contains('class SubscriptionSyncAdapter'));
      expect(adapterSource, contains('implements SyncAdapter<Subscription>'));
      expect(
        adapterSource,
        contains("String get entityName => 'subscription'"),
      );
      expect(
        adapterSource,
        contains("String get tableName => 'subscriptions'"),
      );
      expect(adapterSource, contains('pendingLocalChanges()'));
      expect(adapterSource, contains('pullRemoteRows('));
      expect(adapterSource, contains('pushLocalChange('));
      expect(adapterSource, contains('mergeRemoteRow('));
      expect(adapterSource, contains('purgeLocalDeleted('));
      expect(adapterSource, contains("onConflict: 'user_id,sync_id'"));
      expect(adapterSource, contains('SyncConflictDraft'));
      expect(adapterSource, contains("'anchor_date'"));
      expect(adapterSource, contains("'next_due_date'"));
      expect(adapterSource, contains("'end_date'"));
      expect(adapterSource, contains("'status'"));
      expect(adapterSource, contains("'reminder_days'"));

      expect(syncService, contains('SubscriptionSyncAdapter('));
      expect(syncService, contains('SyncEngine('));
      expect(
        syncService,
        isNot(contains('_dbService.syncRemoteSubscriptionsToLocal')),
      );
      expect(syncService, isNot(contains('getPendingSubscriptionsForSync()')));
    });
  });
}
