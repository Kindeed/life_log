import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';

class ProjectStageSummary {
  final String name;
  int photos = 0;
  int expenses = 0;
  int evidence = 0;
  int trips = 0;
  int notes = 0;
  final Map<String, double> totals = {};
  ProjectStageSummary(this.name);
}

/// Recover names referenced by historical rows without guessing a phase for
/// unassigned records. Counts are computed once, not by repeatedly scanning.
List<ProjectStageSummary> projectStageSummaries({
  required Iterable<String> definitions,
  required Iterable<PhotoEntry> photos,
  required Iterable<ExpenseRecordEntry> expenses,
  required Iterable<EvidenceEntry> evidence,
  required Iterable<WorkLogEntry> trips,
  Iterable<ProjectNoteEntry> notes = const [],
}) {
  final groups = <String, ProjectStageSummary>{};
  final amounts = <String, Map<String, List<double>>>{};
  ProjectStageSummary group(String? name) {
    final normalized = name?.trim() ?? '';
    return groups.putIfAbsent(
      normalized,
      () => ProjectStageSummary(normalized),
    );
  }

  for (final name in definitions) {
    if (name.trim().isNotEmpty) group(name);
  }
  for (final entry in photos) {
    group(entry.projectStageName).photos++;
  }
  for (final entry in expenses) {
    final summary = group(entry.projectStageName);
    summary.expenses++;
    final currency = entry.currency.trim().toUpperCase();
    final code = currency.isEmpty ? 'CNY' : currency;
    amounts
        .putIfAbsent(summary.name, () => {})
        .putIfAbsent(code, () => [])
        .add(entry.amount);
  }
  for (final entry in evidence) {
    group(entry.projectStageName).evidence++;
  }
  for (final entry in trips) {
    group(entry.projectStageName).trips++;
  }
  for (final entry in notes) {
    group(entry.projectStageName).notes++;
  }
  for (final stage in amounts.entries) {
    for (final currency in stage.value.entries) {
      groups[stage.key]!.totals[currency.key] = sumMoneyValues(currency.value);
    }
  }
  group('');
  return groups.values.toList();
}
