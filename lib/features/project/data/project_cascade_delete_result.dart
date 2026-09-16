import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/project/data/project_model.dart';

/// The result of the local, single-transaction part of project deletion.
///
/// A retained project is a sync tombstone. A null project means the project
/// had no remote identity and was purged locally. Evidence files are returned
/// separately because filesystem deletion cannot participate in an Isar
/// transaction and must happen after the database commit.
final class ProjectCascadeDeleteResult {
  final Project? deletedProject;
  final List<ExpenseEvidence> localEvidenceFiles;
  final List<ExpenseEvidence> pendingEvidenceFiles;

  const ProjectCascadeDeleteResult({
    required this.deletedProject,
    this.localEvidenceFiles = const <ExpenseEvidence>[],
    this.pendingEvidenceFiles = const <ExpenseEvidence>[],
  });
}
