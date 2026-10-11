import 'package:flutter/material.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_sheet.dart';

Future<void> showEvidenceEditorSheet(
  BuildContext context, {
  ExpenseEvidence? existing,
  String? initialProject,
  String? initialProjectStageName,
  String? sourcePath,
  String? sourceExtension,
}) {
  return Navigator.of(context).push<void>(
    appPageRoute<void>(
      context,
      EvidenceEditorSheet(
        existing: existing,
        initialProject: initialProject,
        initialProjectStageName: initialProjectStageName,
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
  String? initialProjectStageName,
  String? sourcePath,
  String? sourceExtension,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EvidenceEditorSheet(
      existing: existing,
      initialProject: initialProject,
      initialProjectStageName: initialProjectStageName,
      sourcePath: sourcePath,
      sourceExtension: sourceExtension,
    ),
  );
}
