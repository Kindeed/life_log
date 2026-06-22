import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sync scheduler boundary', () {
    test(
      'feature sync gateways request SyncScheduler instead of entity pushes',
      () {
        final gatewayPaths = [
          'lib/features/work_log/data/work_log_sync_gateway.dart',
          'lib/features/subscription/data/subscription_sync_gateway.dart',
          'lib/features/project/data/project_sync_gateway.dart',
          'lib/features/expense/data/expense_record_sync_gateway.dart',
          'lib/features/evidence/data/evidence_sync_gateway.dart',
        ];

        for (final path in gatewayPaths) {
          final source = File(path).readAsStringSync();
          expect(source, contains('SyncScheduler'));
          expect(source, contains('requestSync('));
          expect(source, isNot(contains('pushWorkLog(')), reason: path);
          expect(source, isNot(contains('deleteWorkLog(')), reason: path);
          expect(source, isNot(contains('pushSubscription(')), reason: path);
          expect(source, isNot(contains('deleteSubscription(')), reason: path);
          expect(source, isNot(contains('pushProject(')), reason: path);
          expect(source, isNot(contains('deleteProject(')), reason: path);
          expect(source, isNot(contains('pushExpenseRecord(')), reason: path);
          expect(source, isNot(contains('deleteExpenseRecord(')), reason: path);
          expect(source, isNot(contains('pushEvidence(')), reason: path);
          expect(source, isNot(contains('deleteEvidence(')), reason: path);
        }
      },
    );

    test('repositories request sync through the gateway scheduler method', () {
      final repositoryPaths = [
        'lib/features/work_log/data/work_log_repository.dart',
        'lib/features/subscription/data/subscription_repository.dart',
        'lib/features/project/data/project_repository.dart',
        'lib/features/expense/data/expense_record_repository.dart',
        'lib/features/evidence/data/evidence_repository.dart',
      ];
      final forbidden = RegExp(r'_syncGateway\.(push|delete)');

      for (final path in repositoryPaths) {
        final file = File(path);
        final source = file.readAsStringSync();
        expect(source, contains('_syncGateway.requestSync('));
        expect(source, isNot(matches(forbidden)), reason: file.path);
      }
    });

    test(
      'SyncService no longer exposes entity-level push or delete entrypoints',
      () {
        final source = File(
          'lib/common/services/sync_service.dart',
        ).readAsStringSync();
        for (final methodName in [
          'pushWorkLog',
          'deleteWorkLog',
          'pushSubscription',
          'deleteSubscription',
          'pushProject',
          'deleteProject',
          'pushExpenseRecord',
          'deleteExpenseRecord',
          'pushEvidence',
          'deleteEvidence',
        ]) {
          expect(source, isNot(contains('Future<bool> $methodName(')));
        }
      },
    );
  });
}
