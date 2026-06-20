import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';

ExpenseEvidence legacyEvidenceFromEntry(EvidenceEntry entry) {
  return ExpenseEvidence()
    ..id = entry.id
    ..projectName = entry.projectName
    ..projectId = entry.projectId
    ..evidenceDate = entry.evidenceDate
    ..amount = entry.amount
    ..currency = entry.currency
    ..category = entry.category.toLegacyEvidenceCategory()
    ..status = entry.status.toLegacyEvidenceStatus()
    ..merchant = entry.merchant
    ..note = entry.note
    ..localFilePath = entry.localFilePath
    ..remoteStoragePath = entry.remoteStoragePath
    ..fileName = entry.fileName
    ..mimeType = entry.mimeType
    ..uploadedAt = entry.uploadedAt
    ..tripDate = entry.tripDate;
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

extension on EvidenceEntryStatus {
  EvidenceStatus toLegacyEvidenceStatus() {
    return switch (this) {
      EvidenceEntryStatus.pending => EvidenceStatus.pending,
      EvidenceEntryStatus.submitted => EvidenceStatus.submitted,
      EvidenceEntryStatus.reimbursed => EvidenceStatus.reimbursed,
    };
  }
}
