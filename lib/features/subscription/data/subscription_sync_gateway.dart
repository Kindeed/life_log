import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';

abstract interface class SubscriptionSyncGateway {
  bool get isAvailable;
  Future<bool> pushSubscription(Subscription subscription);
  Future<bool> deleteSubscription(Subscription subscription);
}

final class ServiceLocatorSubscriptionSyncGateway
    implements SubscriptionSyncGateway {
  const ServiceLocatorSubscriptionSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncService>();

  @override
  Future<bool> deleteSubscription(Subscription subscription) {
    return serviceLocator<SyncService>().deleteSubscription(subscription);
  }

  @override
  Future<bool> pushSubscription(Subscription subscription) {
    return serviceLocator<SyncService>().pushSubscription(subscription);
  }
}
