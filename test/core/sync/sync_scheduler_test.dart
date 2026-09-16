import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';

void main() {
  group('SyncScheduler', () {
    test('passes request metadata into the sync reason', () async {
      final reasons = <String>[];
      final scheduler = SyncScheduler(
        runSync:
            ({
              required reason,
              forceFullRefresh = false,
              forceNew = false,
            }) async {
              reasons.add(reason);
              return true;
            },
      );

      final success = await scheduler.requestSync(
        reason: 'save',
        entityName: 'work_log',
        entityKey: 'abc',
      );

      expect(success, isTrue);
      expect(reasons, ['save:work_log:abc']);
    });

    test('coalesces overlapping requests into one active sync', () async {
      var runCount = 0;
      final completer = Completer<bool>();
      final scheduler = SyncScheduler(
        runSync:
            ({required reason, forceFullRefresh = false, forceNew = false}) {
              runCount++;
              return completer.future;
            },
      );

      final first = scheduler.requestSync(reason: 'first');
      final second = scheduler.requestSync(reason: 'second');

      await Future<void>.delayed(Duration.zero);
      completer.complete(true);

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(runCount, 1);
    });

    test('queues entity mutations behind an active sync', () async {
      var runCount = 0;
      final first = Completer<bool>();
      final second = Completer<bool>();
      final scheduler = SyncScheduler(
        runSync:
            ({required reason, forceFullRefresh = false, forceNew = false}) {
              runCount++;
              return runCount == 1 ? first.future : second.future;
            },
      );

      final startup = scheduler.requestSync(reason: 'startup');
      final delete = scheduler.requestSync(
        reason: 'delete',
        entityName: 'subscription',
        entityKey: 'sub-1',
      );

      first.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 2);
      expect(delete, isNot(same(startup)));

      second.complete(true);
      expect(await startup, isTrue);
      expect(await delete, isTrue);
    });

    test(
      'coalesces multiple entity mutations into one follow-up sync',
      () async {
        var runCount = 0;
        final first = Completer<bool>();
        final second = Completer<bool>();
        final scheduler = SyncScheduler(
          runSync:
              ({required reason, forceFullRefresh = false, forceNew = false}) {
                runCount++;
                return runCount == 1 ? first.future : second.future;
              },
        );

        scheduler.requestSync(reason: 'startup');
        final deleteOne = scheduler.requestSync(
          reason: 'delete',
          entityName: 'subscription',
          entityKey: 'sub-1',
        );
        final deleteTwo = scheduler.requestSync(
          reason: 'delete',
          entityName: 'subscription',
          entityKey: 'sub-2',
        );

        first.complete(true);
        await Future<void>.delayed(Duration.zero);
        expect(runCount, 2);
        expect(deleteTwo, same(deleteOne));

        second.complete(true);
        expect(await deleteOne, isTrue);
      },
    );
  });
}
