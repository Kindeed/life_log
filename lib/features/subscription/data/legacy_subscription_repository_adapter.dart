import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/subscription/data/subscription_repository.dart';

final class LegacySubscriptionRepositoryAdapter
    implements SubscriptionRepositoryPort {
  final SubscriptionRepository _repository;

  const LegacySubscriptionRepositoryAdapter(this._repository);

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    final subscriptions = await _repository.getAllSubscriptions();
    return subscriptions
        .map((subscription) => subscription.toSubscriptionEntry())
        .toList(growable: false);
  }

  @override
  Future<SubscriptionEditDraft?> getEditDraft(int id) async {
    final subscriptions = await _repository.getAllSubscriptions();
    final existing = subscriptions._firstWhereIdOrNull(id);
    if (existing == null) return null;

    return SubscriptionEditDraft(
      entry: existing.toSubscriptionEntry(),
      alreadyDirty: existing.isDirty,
    );
  }

  @override
  Future<void> deleteEntry(int id) {
    return _repository.deleteSubscription(id);
  }

  @override
  Future<void> reorderEntries(List<SubscriptionEntry> entries) async {
    final subscriptions = await _repository.getAllSubscriptions();
    final legacyEntries = entries
        .map((entry) {
          final existing = subscriptions._firstWhereIdOrNull(entry.id);
          return entry.toLegacySubscription().._preserveSyncMetadata(existing);
        })
        .toList(growable: false);

    await _repository.reorderSubscriptions(legacyEntries);
  }

  @override
  Future<void> saveEntry(
    SubscriptionEntry entry, {
    required bool markDirty,
  }) async {
    final subscriptions = await _repository.getAllSubscriptions();
    final existing = subscriptions._firstWhereIdOrNull(entry.id);
    final subscription = entry.toLegacySubscription()..isDirty = markDirty;
    subscription._preserveSyncMetadata(existing);

    await _repository.saveSubscription(subscription, subscriptions.length);
  }

  @override
  Stream<void> watchEntries() {
    return _repository.watchSubscriptions();
  }
}

extension LegacySubscriptionMapper on Subscription {
  SubscriptionEntry toSubscriptionEntry() {
    return SubscriptionEntry(
      id: id,
      name: name,
      price: price,
      cycle: cycle.toSubscriptionBillingCycle(),
      nextPaymentDate: nextPaymentDate,
      anchorDate: anchorDate,
      endDate: endDate,
      status: status.toSubscriptionEntryStatus(),
      reminderDays: reminderDays,
      note: note,
      sortIndex: sortIndex,
    );
  }
}

extension SubscriptionEntryLegacyMapper on SubscriptionEntry {
  Subscription toLegacySubscription() {
    return Subscription()
      ..id = id
      ..name = name
      ..price = price
      ..cycle = cycle.toLegacySubscriptionCycle()
      ..nextPaymentDate = nextPaymentDate
      ..anchorDate = anchorDate
      ..endDate = endDate
      ..status = status.toLegacySubscriptionStatus()
      ..reminderDays = reminderDays
      ..note = note
      ..sortIndex = sortIndex;
  }
}

extension LegacySubscriptionCycleMapper on SubscriptionCycle {
  SubscriptionBillingCycle toSubscriptionBillingCycle() {
    return switch (this) {
      SubscriptionCycle.monthly => SubscriptionBillingCycle.monthly,
      SubscriptionCycle.yearly => SubscriptionBillingCycle.yearly,
      SubscriptionCycle.oneTime => SubscriptionBillingCycle.oneTime,
      SubscriptionCycle.custom => SubscriptionBillingCycle.custom,
    };
  }
}

extension SubscriptionBillingCycleLegacyMapper on SubscriptionBillingCycle {
  SubscriptionCycle toLegacySubscriptionCycle() {
    return switch (this) {
      SubscriptionBillingCycle.monthly => SubscriptionCycle.monthly,
      SubscriptionBillingCycle.yearly => SubscriptionCycle.yearly,
      SubscriptionBillingCycle.oneTime => SubscriptionCycle.oneTime,
      SubscriptionBillingCycle.custom => SubscriptionCycle.custom,
    };
  }
}

extension LegacySubscriptionStatusMapper on SubscriptionRecordStatus {
  SubscriptionStatus toSubscriptionEntryStatus() {
    return switch (this) {
      SubscriptionRecordStatus.active => SubscriptionStatus.active,
      SubscriptionRecordStatus.paused => SubscriptionStatus.paused,
      SubscriptionRecordStatus.canceled => SubscriptionStatus.canceled,
      SubscriptionRecordStatus.archived => SubscriptionStatus.archived,
    };
  }
}

extension SubscriptionStatusLegacyMapper on SubscriptionStatus {
  SubscriptionRecordStatus toLegacySubscriptionStatus() {
    return switch (this) {
      SubscriptionStatus.active => SubscriptionRecordStatus.active,
      SubscriptionStatus.paused => SubscriptionRecordStatus.paused,
      SubscriptionStatus.canceled => SubscriptionRecordStatus.canceled,
      SubscriptionStatus.archived => SubscriptionRecordStatus.archived,
    };
  }
}

extension on Iterable<Subscription> {
  Subscription? _firstWhereIdOrNull(int id) {
    for (final subscription in this) {
      if (subscription.id == id) {
        return subscription;
      }
    }
    return null;
  }
}

extension on Subscription {
  void _preserveSyncMetadata(Subscription? existing) {
    if (existing == null) return;

    ownerUserId = existing.ownerUserId;
    remoteId = existing.remoteId;
    syncId = existing.syncId;
    remoteVersion = existing.remoteVersion;
    remoteUpdatedAt = existing.remoteUpdatedAt;
    syncedAt = existing.syncedAt;
    deletedAt = existing.deletedAt;
    pendingDelete = existing.pendingDelete;
  }
}
