import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

abstract interface class WorkLogRepositoryPort {
  Future<List<WorkLogEntry>> getAllEntries();

  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month);

  Future<WorkLogEditDraft?> getEditDraft(int id);

  Future<void> normalizeDuplicateDays();

  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty});

  Future<void> deleteEntry(int id);

  Stream<void> watchEntries();
}
