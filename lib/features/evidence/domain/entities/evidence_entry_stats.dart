import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';

extension EvidenceEntryStats on Iterable<EvidenceEntry> {
  Iterable<EvidenceEntry> inMonth(DateTime monthYear) {
    final localMonth = dateOnlyLocal(monthYear);
    return where((entry) {
      final localDate = dateOnlyLocal(entry.evidenceDate);
      return localDate.year == localMonth.year &&
          localDate.month == localMonth.month;
    });
  }

  /// Compatibility scalars are CNY subtotals, never mixed-currency totals.
  double get totalPendingAmount => pendingAmountsByCurrency['CNY'] ?? 0;

  double get totalReimbursedAmount => reimbursedAmountsByCurrency['CNY'] ?? 0;

  Map<String, double> get pendingAmountsByCurrency => _amountsByCurrency(
    where((entry) => entry.status != EvidenceEntryStatus.reimbursed),
  );

  Map<String, double> get reimbursedAmountsByCurrency => _amountsByCurrency(
    where((entry) => entry.status == EvidenceEntryStatus.reimbursed),
  );
}

Map<String, double> _amountsByCurrency(Iterable<EvidenceEntry> entries) {
  final grouped = <String, List<double>>{};
  for (final entry in entries) {
    if (entry.amount == null) continue;
    final code = normalizeCurrencyCode(entry.currency);
    grouped.putIfAbsent(code, () => []).add(entry.amount!);
  }
  return Map.unmodifiable(
    grouped.map((code, values) => MapEntry(code, sumMoneyValues(values))),
  );
}
