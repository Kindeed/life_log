import 'package:life_log/common/utils/date_utils.dart';
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

  double get totalPendingAmount {
    return where(
      (entry) => entry.status != EvidenceEntryStatus.reimbursed,
    ).fold(0.0, (sum, entry) => sum + (entry.amount ?? 0.0));
  }

  double get totalReimbursedAmount {
    return where(
      (entry) => entry.status == EvidenceEntryStatus.reimbursed,
    ).fold(0.0, (sum, entry) => sum + (entry.amount ?? 0.0));
  }
}
