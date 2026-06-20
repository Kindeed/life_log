import 'package:equatable/equatable.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

final class SubscriptionTodaySnapshot extends Equatable {
  final DateTime today;
  final List<SubscriptionEntry> dueSoonEntries;
  final double currentMonthCost;

  const SubscriptionTodaySnapshot({
    required this.today,
    required this.dueSoonEntries,
    required this.currentMonthCost,
  });

  static SubscriptionTodaySnapshot empty(DateTime today) {
    return SubscriptionTodaySnapshot(
      today: today,
      dueSoonEntries: const [],
      currentMonthCost: 0,
    );
  }

  @override
  List<Object?> get props => [today, dueSoonEntries, currentMonthCost];
}
