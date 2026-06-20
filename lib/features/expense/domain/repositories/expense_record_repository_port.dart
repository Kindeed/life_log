import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';

abstract interface class ExpenseRecordRepositoryPort {
  Future<List<ExpenseRecordEntry>> getAllEntries();
  Future<ExpenseRecordEditDraft?> getEditDraft(int id);
  Future<void> saveEntry(ExpenseRecordEntry entry, {required bool markDirty});
  Future<void> deleteEntry(int id);
  Stream<void> watchEntries();
}
