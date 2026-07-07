import 'package:isar/isar.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/evidence_repository.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';

final class LegacyEvidenceRepositoryAdapter implements EvidenceRepositoryPort {
  final EvidenceRepository _repository;

  const LegacyEvidenceRepositoryAdapter(this._repository);

  @override
  Future<List<EvidenceEntry>> getAllEntries() async {
    final evidence = await _repository.getAllEvidence();
    return evidence.map((item) => item.toEvidenceEntry()).toList();
  }

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async {
    final evidence = await _repository.getAllEvidence();
    final existing = evidence._firstWhereIdOrNull(id);
    if (existing == null) return null;

    return EvidenceEditDraft(
      entry: existing.toEvidenceEntry(),
      alreadyDirty: existing.isDirty,
    );
  }

  @override
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  }) async {
    final evidence = await _repository.getAllEvidence();
    final existing = evidence._firstWhereIdOrNull(entry.id);
    final record = entry.toLegacyExpenseEvidence()..isDirty = markDirty;
    record._preserveSyncMetadata(existing);

    await _repository.saveEvidence(
      record,
      sourcePath: sourcePath,
      sourceExtension: sourceExtension,
    );
  }

  @override
  Future<void> deleteEntry(int id) => _repository.deleteEvidence(id);

  @override
  Stream<void> watchEntries() => _repository.watchEvidence();
}

extension EvidenceEntryMapper on ExpenseEvidence {
  EvidenceEntry toEvidenceEntry() {
    return EvidenceEntry(
      id: id,
      projectName: projectName,
      projectId: projectId,
      projectSyncId: projectSyncId,
      projectStageName: projectStageName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      evidenceDate: evidenceDate,
      amount: amount,
      currency: currency,
      category: category.toEvidenceEntryCategory(),
      status: status.toEvidenceEntryStatus(),
      merchant: merchant,
      note: note,
      localFilePath: localFilePath,
      remoteStoragePath: remoteStoragePath,
      fileName: fileName,
      mimeType: mimeType,
      uploadedAt: uploadedAt,
      tripDate: tripDate,
    );
  }
}

extension EvidenceEntryLegacyMapper on EvidenceEntry {
  ExpenseEvidence toLegacyExpenseEvidence() {
    return ExpenseEvidence()
      ..id = id == 0 ? Isar.autoIncrement : id
      ..projectName = projectName
      ..projectId = projectId
      ..projectSyncId = projectSyncId
      ..projectStageName = projectStageName
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..evidenceDate = evidenceDate
      ..amount = amount
      ..currency = currency
      ..category = category.toLegacyEvidenceCategory()
      ..status = status.toLegacyEvidenceStatus()
      ..merchant = merchant
      ..note = note
      ..localFilePath = localFilePath
      ..remoteStoragePath = remoteStoragePath
      ..fileName = fileName
      ..mimeType = mimeType
      ..uploadedAt = uploadedAt
      ..tripDate = tripDate;
  }
}

extension on EvidenceCategory {
  EvidenceEntryCategory toEvidenceEntryCategory() {
    return switch (this) {
      EvidenceCategory.invoice => EvidenceEntryCategory.invoice,
      EvidenceCategory.payment => EvidenceEntryCategory.payment,
      EvidenceCategory.purchase => EvidenceEntryCategory.purchase,
      EvidenceCategory.travel => EvidenceEntryCategory.travel,
      EvidenceCategory.meal => EvidenceEntryCategory.meal,
      EvidenceCategory.accommodation => EvidenceEntryCategory.accommodation,
      EvidenceCategory.other => EvidenceEntryCategory.other,
    };
  }
}

extension on EvidenceEntryCategory {
  EvidenceCategory toLegacyEvidenceCategory() {
    return switch (this) {
      EvidenceEntryCategory.invoice => EvidenceCategory.invoice,
      EvidenceEntryCategory.payment => EvidenceCategory.payment,
      EvidenceEntryCategory.purchase => EvidenceCategory.purchase,
      EvidenceEntryCategory.travel => EvidenceCategory.travel,
      EvidenceEntryCategory.meal => EvidenceCategory.meal,
      EvidenceEntryCategory.accommodation => EvidenceCategory.accommodation,
      EvidenceEntryCategory.other => EvidenceCategory.other,
    };
  }
}

extension on EvidenceStatus {
  EvidenceEntryStatus toEvidenceEntryStatus() {
    return switch (this) {
      EvidenceStatus.pending => EvidenceEntryStatus.pending,
      EvidenceStatus.submitted => EvidenceEntryStatus.submitted,
      EvidenceStatus.reimbursed => EvidenceEntryStatus.reimbursed,
    };
  }
}

extension on EvidenceEntryStatus {
  EvidenceStatus toLegacyEvidenceStatus() {
    return switch (this) {
      EvidenceEntryStatus.pending => EvidenceStatus.pending,
      EvidenceEntryStatus.submitted => EvidenceStatus.submitted,
      EvidenceEntryStatus.reimbursed => EvidenceStatus.reimbursed,
    };
  }
}

extension on Iterable<ExpenseEvidence> {
  ExpenseEvidence? _firstWhereIdOrNull(int id) {
    for (final item in this) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}

extension on ExpenseEvidence {
  void _preserveSyncMetadata(ExpenseEvidence? existing) {
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
