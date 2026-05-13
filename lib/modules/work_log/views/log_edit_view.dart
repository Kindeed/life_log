import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/modules/work_log/add_log_sheet.dart';
import 'package:life_log/modules/work_log/work_log_controller.dart';
import 'package:life_log/modules/work_log/work_log_model.dart';

class LogEditView extends StatelessWidget {
  final DateTime selectedDate;
  final WorkLog? existingLog;
  final LogType? initialType;

  const LogEditView({
    super.key,
    required this.selectedDate,
    this.existingLog,
    this.initialType,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<WorkLogController>()
        ? WorkLogController.to
        : null;
    final resolvedExistingLog =
        existingLog ?? controller?.getLogForDay(selectedDate);

    return Scaffold(
      body: SafeArea(
        child: AddLogSheet(
          selectedDate: selectedDate,
          existingLog: resolvedExistingLog,
          initialType: initialType,
          asPage: true,
        ),
      ),
    );
  }
}
