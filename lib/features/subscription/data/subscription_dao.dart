import 'package:isar/isar.dart';
import 'package:life_log/core/db/isar_database.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';

class SubscriptionDao {
  final IsarDatabase database;

  const SubscriptionDao(this.database);

  Isar get _isar => database.isar;

  Future<Subscription?> getById(int id) {
    return _isar.subscriptions.get(id);
  }

  Future<List<Subscription>> getAllSorted() {
    return _isar.subscriptions.where().sortByNextPaymentDate().findAll();
  }

  Future<List<Subscription>> getActiveSortedForOwner(String? ownerUserId) {
    return _isar.subscriptions
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .deletedAtIsNull()
        .sortByNextPaymentDate()
        .findAll();
  }

  Future<List<Subscription>> getAllForSync() {
    return _isar.subscriptions.where().sortByNextPaymentDate().findAll();
  }

  Future<List<Subscription>> getPendingForSync() {
    return _isar.subscriptions
        .filter()
        .remoteIdIsNull()
        .or()
        .isDirtyEqualTo(true)
        .or()
        .pendingDeleteEqualTo(true)
        .sortByNextPaymentDate()
        .findAll();
  }

  Future<List<Subscription>> getPendingForSyncForOwner(
    String? ownerUserId,
  ) async {
    final byId = <int, Subscription>{};
    for (final subs in [
      await _pendingRemoteMissingForOwner(ownerUserId),
      await _pendingDirtyForOwner(ownerUserId),
      await _pendingDeleteForOwner(ownerUserId),
    ]) {
      for (final sub in subs) {
        byId[sub.id] = sub;
      }
    }
    final pending = byId.values.toList()
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return pending;
  }

  Future<List<Subscription>> _pendingRemoteMissingForOwner(
    String? ownerUserId,
  ) {
    return _isar.subscriptions
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .remoteIdIsNull()
        .findAll();
  }

  Future<List<Subscription>> _pendingDirtyForOwner(String? ownerUserId) {
    return _isar.subscriptions
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<Subscription>> _pendingDeleteForOwner(String? ownerUserId) {
    return _isar.subscriptions
        .filter()
        .ownerMatches(ownerUserId)
        .and()
        .pendingDeleteEqualTo(true)
        .findAll();
  }

  Stream<void> watch() {
    return _isar.subscriptions.watchLazy();
  }

  Future<void> delete(int id) async {
    await database.writeTxn(() async {
      await _isar.subscriptions.delete(id);
    });
  }
}

extension _SubscriptionOwnerFilter
    on QueryBuilder<Subscription, Subscription, QFilterCondition> {
  QueryBuilder<Subscription, Subscription, QAfterFilterCondition> ownerMatches(
    String? ownerUserId,
  ) {
    return ownerUserId == null
        ? ownerUserIdIsNull()
        : ownerUserIdEqualTo(ownerUserId);
  }
}
