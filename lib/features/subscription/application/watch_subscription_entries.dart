import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';

final class WatchSubscriptionEntries {
  final SubscriptionRepositoryPort _repository;

  const WatchSubscriptionEntries(this._repository);

  Stream<void> call() {
    return _repository.watchEntries();
  }
}
