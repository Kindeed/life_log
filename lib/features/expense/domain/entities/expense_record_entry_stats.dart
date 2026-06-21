import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';

extension ExpenseRecordEntryStats on Iterable<ExpenseRecordEntry> {
  Iterable<ExpenseRecordEntry> inMonth(DateTime monthYear) {
    final localMonth = dateOnlyLocal(monthYear);
    return where((entry) {
      final localDate = dateOnlyLocal(entry.expenseDate);
      return localDate.year == localMonth.year &&
          localDate.month == localMonth.month;
    });
  }

  double get totalAmount {
    return fold(0.0, (sum, entry) => sum + entry.amount);
  }
}
