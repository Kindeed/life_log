import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/work_log/data/work_log_repository.dart';

final class LegacyWorkLogRepositoryAdapter implements WorkLogRepositoryPort {
  final WorkLogRepository _repository;

  const LegacyWorkLogRepositoryAdapter(this._repository);

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    final logs = await _repository.getAllLogs();
    return logs.map((log) => log.toWorkLogEntry()).toList(growable: false);
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async {
    final logs = await _repository.getAllLogs();
    for (final log in logs) {
      if (log.id == id) {
        return WorkLogEditDraft(
          entry: log.toWorkLogEntry(),
          alreadyDirty: log.isDirty,
        );
      }
    }
    return null;
  }

  @override
  Future<void> normalizeDuplicateDays() {
    return _repository.normalizeDuplicateDays();
  }

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) {
    final log = entry.toLegacyWorkLog()..isDirty = markDirty;
    return _repository.saveLog(log);
  }

  @override
  Future<void> deleteEntry(int id) {
    return _repository.deleteLog(id);
  }

  @override
  Stream<void> watchEntries() {
    return _repository.watchLogs();
  }
}

extension LegacyWorkLogMapper on WorkLog {
  WorkLogEntry toWorkLogEntry() {
    return WorkLogEntry(
      id: id,
      date: date,
      type: type.toWorkLogEntryType(),
      overtimeHours: overtimeHours,
      location: location,
      transport: transport,
      expenses: expenses,
      isReimbursed: isReimbursed,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension LegacyLogTypeMapper on LogType {
  WorkLogEntryType toWorkLogEntryType() {
    return switch (this) {
      LogType.work => WorkLogEntryType.work,
      LogType.rest => WorkLogEntryType.rest,
      LogType.leave => WorkLogEntryType.leave,
      LogType.businessTrip => WorkLogEntryType.businessTrip,
    };
  }
}

extension WorkLogEntryLegacyMapper on WorkLogEntry {
  WorkLog toLegacyWorkLog() {
    return WorkLog()
      ..id = id
      ..date = date
      ..type = type.toLegacyLogType()
      ..overtimeHours = overtimeHours
      ..location = location
      ..transport = transport
      ..expenses = expenses
      ..isReimbursed = isReimbursed
      ..note = note
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension WorkLogEntryTypeLegacyMapper on WorkLogEntryType {
  LogType toLegacyLogType() {
    return switch (this) {
      WorkLogEntryType.work => LogType.work,
      WorkLogEntryType.rest => LogType.rest,
      WorkLogEntryType.leave => LogType.leave,
      WorkLogEntryType.businessTrip => LogType.businessTrip,
    };
  }
}
