import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/expense/expense_record_model.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

void main() {
  test('month grouping normalizes the target month to local date', () {
    final localMayFromUtcBoundary = DateTime.utc(2026, 4, 30, 16);

    final logs = [
      WorkLog()
        ..id = 1
        ..date = DateTime(2026, 5, 1)
        ..type = LogType.work
        ..overtimeHours = 2,
    ];
    final evidence = [
      ExpenseEvidence()
        ..projectName = 'Trip'
        ..evidenceDate = DateTime(2026, 5, 1)
        ..amount = 30,
    ];
    final expenses = [
      ExpenseRecord()
        ..expenseDate = DateTime(2026, 5, 1)
        ..amount = 12
        ..category = ExpenseCategory.meal,
    ];

    expect(logs.inMonth(localMayFromUtcBoundary).length, 1);
    expect(logs.getMonthStats(localMayFromUtcBoundary).workHours, 2);
    expect(evidence.inMonth(localMayFromUtcBoundary).length, 1);
    expect(expenses.inMonth(localMayFromUtcBoundary).totalAmount, 12);
  });
}
