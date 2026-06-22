import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/sync/sync_scheduler.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';

abstract interface class SubscriptionSyncGateway {
  bool get isAvailable;
  Future<bool> requestSync(Subscription subscription, {required String reason});
}

final class ServiceLocatorSubscriptionSyncGateway
    implements SubscriptionSyncGateway {
  const ServiceLocatorSubscriptionSyncGateway();

  @override
  bool get isAvailable => serviceLocator.isRegistered<SyncScheduler>();

  @override
  Future<bool> requestSync(
    Subscription subscription, {
    required String reason,
  }) {
    return serviceLocator<SyncScheduler>().requestSync(
      reason: reason,
      entityName: 'subscription',
      entityKey: subscription.syncId ?? subscription.id.toString(),
    );
  }
}
