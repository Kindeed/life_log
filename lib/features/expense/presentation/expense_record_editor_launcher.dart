import 'package:flutter/material.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/expense/application/load_expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_edit_view.dart';

Future<void> openExpenseRecordEditorPage(
  BuildContext context, {
  ExpenseRecordEntry? entry,
  DateTime? initialDate,
  String? initialProjectName,
  Future<void> Function()? onSavedOrDeleted,
}) async {
  final input = await _resolveEditorInput(context, entry: entry);
  if (!context.mounted) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ExpenseRecordEditView(
        existingEntry: input.entry,
        existingAlreadyDirty: input.alreadyDirty,
        initialDate: initialDate,
        initialProjectName: initialProjectName,
        onSavedOrDeleted: onSavedOrDeleted,
      ),
    ),
  );
}

Future<_ExpenseRecordEditorInput> _resolveEditorInput(
  BuildContext context, {
  ExpenseRecordEntry? entry,
}) async {
  final activeEntry = entry;
  if (activeEntry == null || activeEntry.id == 0) {
    return _ExpenseRecordEditorInput(entry: activeEntry);
  }

  final result = await serviceLocator<LoadExpenseRecordEditDraft>().call(
    activeEntry.id,
  );
  final failure = result.failureOrNull;
  if (failure != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('读取消费编辑状态失败：${failure.message}')));
    }
    return _ExpenseRecordEditorInput(entry: activeEntry);
  }

  final draft = result.valueOrNull;
  if (draft == null) {
    return _ExpenseRecordEditorInput(entry: activeEntry);
  }
  return _ExpenseRecordEditorInput(
    entry: draft.entry,
    alreadyDirty: draft.alreadyDirty,
  );
}

final class _ExpenseRecordEditorInput {
  final ExpenseRecordEntry? entry;
  final bool alreadyDirty;

  const _ExpenseRecordEditorInput({
    required this.entry,
    this.alreadyDirty = false,
  });
}
