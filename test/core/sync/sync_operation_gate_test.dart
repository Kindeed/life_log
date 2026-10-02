import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/sync/sync_operation_gate.dart';

void main() {
  test(
    'remote decision waits for issued sync and keeps new runs blocked',
    () async {
      final gate = SyncOperationGate();
      final issuedRequest = Completer<void>();
      final decision = Completer<void>();
      final events = <String>[];
      final operation = gate.run(
        invalidateAndDrain: () async {
          events.add('invalidate-old-context');
          await issuedRequest.future;
          events.add('old-request-completed');
        },
        action: () async {
          events.add('fetch-current-remote-and-resolve');
          await decision.future;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(gate.isBlocked, isTrue);
      expect(events, ['invalidate-old-context']);
      issuedRequest.complete();
      await Future<void>.delayed(Duration.zero);
      expect(events.last, 'fetch-current-remote-and-resolve');
      expect(gate.isBlocked, isTrue);
      decision.complete();
      await operation;
      expect(gate.isBlocked, isFalse);
    },
  );

  test(
    'a failed decision releases the gate and the next decision still runs',
    () async {
      final gate = SyncOperationGate();
      final first = gate.run(
        invalidateAndDrain: () async {},
        action: () async => throw StateError('remote changed'),
      );
      await expectLater(first, throwsStateError);
      expect(gate.isBlocked, isFalse);
      var resolved = false;
      await gate.run(
        invalidateAndDrain: () async {},
        action: () async => resolved = true,
      );
      await gate.drained;
      expect(resolved, isTrue);
      expect(gate.isBlocked, isFalse);
    },
  );

  test(
    'overlapping decisions serialize their drain and local commits',
    () async {
      final gate = SyncOperationGate();
      final firstCommit = Completer<void>();
      final events = <int>[];
      final first = gate.run(
        invalidateAndDrain: () async => events.add(1),
        action: () async {
          await firstCommit.future;
          events.add(2);
        },
      );
      final second = gate.run(
        invalidateAndDrain: () async => events.add(3),
        action: () async => events.add(4),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, [1]);
      firstCommit.complete();
      await Future.wait([first, second]);
      expect(events, [1, 2, 3, 4]);
    },
  );
}
