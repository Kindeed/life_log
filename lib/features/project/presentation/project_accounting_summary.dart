import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry_stats.dart';

/// Receipts are supporting documents, not expense settlement transactions.
Map<String, double> projectExpenseTotals(Iterable<ExpenseRecordEntry> entries) {
  return entries.totalAmountsByCurrency;
}

String projectAmount(double amount, String currency) {
  return formatMoney(amount, currency: currency);
}
