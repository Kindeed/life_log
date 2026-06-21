import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionDao boundary', () {
    test(
      'DbService delegates Subscription storage primitives to a feature DAO',
      () {
        final daoFile = File(
          'lib/features/subscription/data/subscription_dao.dart',
        );
        final dbService = File(
          'lib/common/db/db_service.dart',
        ).readAsStringSync();

        expect(daoFile.existsSync(), isTrue);

        final daoSource = daoFile.readAsStringSync();
        expect(daoSource, contains('class SubscriptionDao'));
        expect(daoSource, contains('Future<Subscription?> getById'));
        expect(daoSource, contains('Future<List<Subscription>> getAllSorted'));
        expect(
          daoSource,
          contains('Future<List<Subscription>> getActiveSortedForOwner'),
        );
        expect(
          daoSource,
          contains('Future<List<Subscription>> getPendingForSync'),
        );
        expect(
          daoSource,
          contains('Future<List<Subscription>> getPendingForSyncForOwner'),
        );
        expect(daoSource, contains('Stream<void> watch'));
        expect(daoSource, contains('Future<void> delete'));

        expect(dbService, contains('late SubscriptionDao _subscriptionDao'));
        expect(
          dbService,
          contains('_subscriptionDao = SubscriptionDao(database)'),
        );
        expect(
          dbService,
          contains('_subscriptionDao.getActiveSortedForOwner('),
        );
        expect(
          dbService,
          contains('_subscriptionDao.getPendingForSyncForOwner('),
        );
        expect(dbService, contains('_subscriptionDao.getById('));
        expect(dbService, contains('_subscriptionDao.watch()'));
        expect(dbService, contains('_subscriptionDao.delete('));
      },
    );
  });
}
