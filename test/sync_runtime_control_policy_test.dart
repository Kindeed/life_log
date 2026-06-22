import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sync runtime control policy', () {
    test(
      'SyncService wires retry queue and pause/cancel hooks into SyncEngine',
      () {
        final source = File(
          'lib/common/services/sync_service.dart',
        ).readAsStringSync();

        expect(source, contains('IsarSyncQueue'));
        expect(source, isNot(contains('InMemorySyncQueue()')));
        expect(source, contains('pauseSync()'));
        expect(source, contains('resumeSync()'));
        expect(source, contains('cancelSync()'));
        expect(source, contains('queue: _syncQueue'));
        expect(source, contains('runControl: SyncRunControl('));
        expect(source, contains('_waitWhilePaused'));
      },
    );
  });
}
