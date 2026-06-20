import 'package:flutter/material.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/add_log_sheet.dart';

class LogEditView extends StatelessWidget {
  final DateTime selectedDate;
  final WorkLogEntry? existingEntry;
  final bool existingAlreadyDirty;
  final WorkLogEntryType? initialType;
  final Future<void> Function()? onSavedOrDeleted;

  const LogEditView({
    super.key,
    required this.selectedDate,
    this.existingEntry,
    this.existingAlreadyDirty = false,
    this.initialType,
    this.onSavedOrDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AddLogSheet(
          selectedDate: selectedDate,
          existingEntry: existingEntry,
          existingAlreadyDirty: existingAlreadyDirty,
          initialType: initialType,
          asPage: true,
          onSavedOrDeleted: onSavedOrDeleted,
        ),
      ),
    );
  }
}
