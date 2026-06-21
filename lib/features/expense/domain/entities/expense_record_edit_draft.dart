import 'package:equatable/equatable.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';

final class ExpenseRecordEditDraft extends Equatable {
  final ExpenseRecordEntry entry;
  final bool alreadyDirty;

  const ExpenseRecordEditDraft({
    required this.entry,
    this.alreadyDirty = false,
  });

  @override
  List<Object?> get props => [entry, alreadyDirty];
}
