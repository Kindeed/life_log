import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';

/// Receipts are supporting documents, not expense settlement transactions.
Map<String, double> projectExpenseTotals(Iterable<ExpenseRecordEntry> entries) {
  final totals = <String, double>{};
  for (final entry in entries) {
    final currency = entry.currency.trim().toUpperCase();
    final code = currency.isEmpty ? 'CNY' : currency;
    totals.update(
      code,
      (total) => total + entry.amount,
      ifAbsent: () => entry.amount,
    );
  }
  return totals;
}

String projectAmount(double amount, String currency) {
  final code = currency.trim().toUpperCase();
  return code.isEmpty || code == 'CNY'
      ? formatMoney(amount)
      : '$code ${amount.toStringAsFixed(2)}';
}
