import 'package:flutter/material.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/application/load_work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/add_log_sheet.dart';
import 'package:life_log/features/work_log/presentation/log_edit_view.dart';

Future<void> openWorkLogEditorPage(
  BuildContext context, {
  required DateTime selectedDate,
  WorkLogEntry? existingEntry,
  WorkLogEntryType? initialType,
  Future<void> Function()? onSavedOrDeleted,
}) async {
  final draft = await _loadEditDraft(context, existingEntry);
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LogEditView(
        selectedDate: selectedDate,
        existingEntry: draft.entry,
        existingAlreadyDirty: draft.alreadyDirty,
        initialType: initialType,
        onSavedOrDeleted: onSavedOrDeleted,
      ),
    ),
  );
}

Future<void> openWorkLogEditorSheet(
  BuildContext context, {
  required DateTime selectedDate,
  required WorkLogEntry existingEntry,
  Future<void> Function()? onSavedOrDeleted,
}) async {
  final draft = await _loadEditDraft(context, existingEntry);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddLogSheet(
      selectedDate: selectedDate,
      existingEntry: draft.entry,
      existingAlreadyDirty: draft.alreadyDirty,
      onSavedOrDeleted: onSavedOrDeleted,
    ),
  );
}

Future<_EditorDraftInput> _loadEditDraft(
  BuildContext context,
  WorkLogEntry? existingEntry,
) async {
  if (existingEntry == null) {
    return const _EditorDraftInput(entry: null);
  }

  final result = await serviceLocator<LoadWorkLogEditDraft>().call(
    existingEntry.id,
  );
  final failure = result.failureOrNull;
  if (failure != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('读取工时编辑状态失败：${failure.message}')));
    }
    return _EditorDraftInput(entry: existingEntry);
  }

  final draft = result.valueOrNull;
  if (draft == null) {
    return _EditorDraftInput(entry: existingEntry);
  }
  return _EditorDraftInput(
    entry: draft.entry,
    alreadyDirty: draft.alreadyDirty,
  );
}

final class _EditorDraftInput {
  final WorkLogEntry? entry;
  final bool alreadyDirty;

  const _EditorDraftInput({required this.entry, this.alreadyDirty = false});
}
