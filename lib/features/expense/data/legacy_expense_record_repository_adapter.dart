import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';

final class LegacyExpenseRecordRepositoryAdapter
    implements ExpenseRecordRepositoryPort {
  final ExpenseRecordRepository _repository;

  const LegacyExpenseRecordRepositoryAdapter(this._repository);

  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async {
    final records = await _repository.getAllExpenseRecords();
    return records.map((record) => record.toExpenseRecordEntry()).toList();
  }

  @override
  Future<ExpenseRecordEditDraft?> getEditDraft(int id) async {
    final records = await _repository.getAllExpenseRecords();
    final existing = records._firstWhereIdOrNull(id);
    if (existing == null) return null;

    return ExpenseRecordEditDraft(
      entry: existing.toExpenseRecordEntry(),
      alreadyDirty: existing.isDirty,
    );
  }

  @override
  Future<void> saveEntry(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {
    final records = await _repository.getAllExpenseRecords();
    final existing = records._firstWhereIdOrNull(entry.id);
    final record = entry.toLegacyExpenseRecord()..isDirty = markDirty;
    record._preserveSyncMetadata(existing);

    await _repository.saveExpenseRecord(record);
  }

  @override
  Future<void> deleteEntry(int id) => _repository.deleteExpenseRecord(id);

  @override
  Stream<void> watchEntries() => _repository.watchExpenseRecords();
}

extension ExpenseRecordEntryMapper on ExpenseRecord {
  ExpenseRecordEntry toExpenseRecordEntry() {
    return ExpenseRecordEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expenseDate: expenseDate,
      amount: amount,
      currency: currency,
      category: category.toExpenseRecordEntryCategory(),
      merchant: merchant,
      note: note,
      projectId: projectId,
      projectSyncId: projectSyncId,
      projectName: projectName,
      tripWorkLogId: tripWorkLogId,
      tripWorkLogSyncId: tripWorkLogSyncId,
    );
  }
}

extension ExpenseRecordEntryLegacyMapper on ExpenseRecordEntry {
  ExpenseRecord toLegacyExpenseRecord() {
    return ExpenseRecord()
      ..id = id
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..expenseDate = expenseDate
      ..amount = amount
      ..currency = currency
      ..category = category.toLegacyExpenseCategory()
      ..merchant = merchant
      ..note = note
      ..projectId = projectId
      ..projectSyncId = projectSyncId
      ..projectName = projectName
      ..tripWorkLogId = tripWorkLogId
      ..tripWorkLogSyncId = tripWorkLogSyncId;
  }
}

extension on ExpenseCategory {
  ExpenseRecordEntryCategory toExpenseRecordEntryCategory() {
    return switch (this) {
      ExpenseCategory.meal => ExpenseRecordEntryCategory.meal,
      ExpenseCategory.transport => ExpenseRecordEntryCategory.transport,
      ExpenseCategory.shopping => ExpenseRecordEntryCategory.shopping,
      ExpenseCategory.travel => ExpenseRecordEntryCategory.travel,
      ExpenseCategory.office => ExpenseRecordEntryCategory.office,
      ExpenseCategory.other => ExpenseRecordEntryCategory.other,
    };
  }
}

extension on ExpenseRecordEntryCategory {
  ExpenseCategory toLegacyExpenseCategory() {
    return switch (this) {
      ExpenseRecordEntryCategory.meal => ExpenseCategory.meal,
      ExpenseRecordEntryCategory.transport => ExpenseCategory.transport,
      ExpenseRecordEntryCategory.shopping => ExpenseCategory.shopping,
      ExpenseRecordEntryCategory.travel => ExpenseCategory.travel,
      ExpenseRecordEntryCategory.office => ExpenseCategory.office,
      ExpenseRecordEntryCategory.other => ExpenseCategory.other,
    };
  }
}

extension on Iterable<ExpenseRecord> {
  ExpenseRecord? _firstWhereIdOrNull(int id) {
    for (final record in this) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }
}

extension on ExpenseRecord {
  void _preserveSyncMetadata(ExpenseRecord? existing) {
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
