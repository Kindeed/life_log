import 'package:flutter/material.dart';
import 'package:life_log/modules/work_log/add_log_sheet.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

class LogEditView extends StatelessWidget {
  final DateTime selectedDate;
  final WorkLog? existingLog;

  const LogEditView({super.key, required this.selectedDate, this.existingLog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AddLogSheet(
          selectedDate: selectedDate,
          existingLog: existingLog,
        ),
      ),
    );
  }
}
