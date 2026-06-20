import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';

abstract interface class EvidenceRepositoryPort {
  Future<List<EvidenceEntry>> getAllEntries();
  Future<EvidenceEditDraft?> getEditDraft(int id);
  Future<void> saveEntry(
    EvidenceEntry entry, {
    required bool markDirty,
    String? sourcePath,
    String? sourceExtension,
  });
  Future<void> deleteEntry(int id);
  Stream<void> watchEntries();
}
