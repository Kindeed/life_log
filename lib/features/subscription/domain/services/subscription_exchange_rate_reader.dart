import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';

abstract interface class SubscriptionExchangeRateReader {
  Future<SubscriptionExchangeRates> load(DateTime now);
}
