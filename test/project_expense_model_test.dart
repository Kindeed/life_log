import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/project/data/project_model.dart';

void main() {
  test('ExpenseRecord monthly total supports today dashboard aggregation', () {
    final records = [
      ExpenseRecord()
        ..expenseDate = DateTime(2026, 5, 6)
        ..amount = 12
        ..category = ExpenseCategory.meal,
      ExpenseRecord()
        ..expenseDate = DateTime(2026, 5, 8)
        ..amount = 8
        ..category = ExpenseCategory.transport,
      ExpenseRecord()
        ..expenseDate = DateTime(2026, 6, 1)
        ..amount = 99
        ..category = ExpenseCategory.other,
    ];

    expect(records.inMonth(DateTime(2026, 5)).totalAmount, 20);
  });

  test('Project status labels are stable for project filters', () {
    expect(ProjectStatus.active.label, '进行中');
    expect(ProjectStatus.archived.label, '已归档');
  });
}
