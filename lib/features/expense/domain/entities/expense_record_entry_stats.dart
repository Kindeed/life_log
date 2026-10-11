import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
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

  /// Compatibility scalar is the CNY subtotal, never a sum of unlike currencies.
  double get totalAmount => totalAmountsByCurrency['CNY'] ?? 0;

  Map<String, double> get totalAmountsByCurrency {
    final grouped = <String, List<double>>{};
    for (final entry in this) {
      final code = normalizeCurrencyCode(entry.currency);
      grouped.putIfAbsent(code, () => []).add(entry.amount);
    }
    return Map.unmodifiable(
      grouped.map((code, values) => MapEntry(code, sumMoneyValues(values))),
    );
  }
}
