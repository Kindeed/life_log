import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

abstract interface class SubscriptionRepositoryPort {
  Future<List<SubscriptionEntry>> getAllEntries();

  Future<SubscriptionEditDraft?> getEditDraft(int id);

  Future<void> deleteEntry(int id);

  Future<void> reorderEntries(List<SubscriptionEntry> entries);

  Future<void> saveEntry(SubscriptionEntry entry, {required bool markDirty});

  Stream<void> watchEntries();
}
