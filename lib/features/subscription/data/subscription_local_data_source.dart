import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';

abstract interface class SubscriptionLocalDataSource {
  Future<List<Subscription>> getAllSubscriptions();
  Stream<void> watchSubscriptions();
  Future<int> addSubscription(Subscription subscription);
  Future<Subscription?> markSubscriptionDeleted(int id);
  Future<void> purgeDeletedSubscription(int id);
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subscriptions,
  );
}

final class DbSubscriptionLocalDataSource
    implements SubscriptionLocalDataSource {
  const DbSubscriptionLocalDataSource();

  @override
  Future<int> addSubscription(Subscription subscription) {
    return serviceLocator<DbService>().addSubscription(subscription);
  }

  @override
  Future<List<Subscription>> getAllSubscriptions() {
    return serviceLocator<DbService>().getAllSubscriptions();
  }

  @override
  Future<Subscription?> markSubscriptionDeleted(int id) {
    return serviceLocator<DbService>().markSubscriptionDeleted(id);
  }

  @override
  Future<void> purgeDeletedSubscription(int id) {
    return serviceLocator<DbService>().purgeDeletedSubscription(id);
  }

  @override
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subscriptions,
  ) {
    return serviceLocator<DbService>().reorderSubscriptions(subscriptions);
  }

  @override
  Stream<void> watchSubscriptions() {
    return serviceLocator<DbService>().watchSubscriptions();
  }
}
