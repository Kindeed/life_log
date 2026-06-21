import 'package:flutter/material.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_sheet.dart';

Future<void> showEvidenceEditorSheet(
  BuildContext context, {
  ExpenseEvidence? existing,
  String? initialProject,
  String? sourcePath,
  String? sourceExtension,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => EvidenceEditorSheet(
        existing: existing,
        initialProject: initialProject,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
        asPage: true,
      ),
    ),
  );
}

Future<void> showEvidenceEditorBottomSheet(
  BuildContext context, {
  ExpenseEvidence? existing,
  String? initialProject,
  String? sourcePath,
  String? sourceExtension,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EvidenceEditorSheet(
      existing: existing,
      initialProject: initialProject,
      sourcePath: sourcePath,
      sourceExtension: sourceExtension,
    ),
  );
}
