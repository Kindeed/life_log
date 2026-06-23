import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

enum WorkLogEditorStatus {
  editing,
  submitting,
  saved,
  deleting,
  deleted,
  failure,
}

final class WorkLogEditorState extends Equatable {
  final WorkLogEditorStatus status;
  final DateTime selectedDate;
  final WorkLogEntry? existingEntry;
  final bool existingAlreadyDirty;
  final WorkLogEntryType type;
  final double overtimeHours;
  final String note;
  final String tripLocation;
  final String transport;
  final String expenseText;
  final bool isReimbursed;
  final int? projectId;
  final String? projectSyncId;
  final String projectName;
  final String projectStageName;
  final String leaveType;
  final String customLeave;
  final AppFailure? failure;

  const WorkLogEditorState({
    required this.status,
    required this.selectedDate,
    required this.existingEntry,
    required this.existingAlreadyDirty,
    required this.type,
    required this.overtimeHours,
    required this.note,
    required this.tripLocation,
    required this.transport,
    required this.expenseText,
    required this.isReimbursed,
    required this.projectId,
    required this.projectSyncId,
    required this.projectName,
    required this.projectStageName,
    required this.leaveType,
    required this.customLeave,
    this.failure,
  });

  factory WorkLogEditorState.initial({
    required DateTime selectedDate,
    WorkLogEntry? existingEntry,
    WorkLogEntryType? initialType,
    bool existingAlreadyDirty = false,
  }) {
    final entry = existingEntry;
    final type = entry?.type ?? initialType ?? WorkLogEntryType.work;
    var leaveType = '年假';
    var customLeave = '';

    if (entry?.type == WorkLogEntryType.leave) {
      final location = entry?.location;
      if (location == '年假' ||
          location == '事假' ||
          location == '病假' ||
          location == '调休') {
        leaveType = location!;
      } else {
        leaveType = '其他';
        customLeave = location ?? '';
      }
    }

    return WorkLogEditorState(
      status: WorkLogEditorStatus.editing,
      selectedDate: dateOnlyLocal(entry?.date ?? selectedDate),
      existingEntry: entry,
      existingAlreadyDirty: existingAlreadyDirty,
      type: type,
      overtimeHours: entry?.type == WorkLogEntryType.work
          ? entry?.overtimeHours ?? 0
          : 0,
      note: entry?.note ?? '',
      tripLocation: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.location ?? ''
          : '',
      transport: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.transport ?? '高铁'
          : '高铁',
      expenseText: entry?.type == WorkLogEntryType.businessTrip
          ? _formatNumber(entry?.expenses)
          : '',
      isReimbursed: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.isReimbursed ?? false
          : false,
      projectId: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.projectId
          : null,
      projectSyncId: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.projectSyncId
          : null,
      projectName: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.projectName ?? ''
          : '',
      projectStageName: entry?.type == WorkLogEntryType.businessTrip
          ? entry?.projectStageName ?? ''
          : '',
      leaveType: leaveType,
      customLeave: customLeave,
    );
  }

  WorkLogEditorState copyWith({
    WorkLogEditorStatus? status,
    WorkLogEntryType? type,
    double? overtimeHours,
    String? note,
    String? tripLocation,
    String? transport,
    String? expenseText,
    bool? isReimbursed,
    int? projectId,
    String? projectSyncId,
    String? projectName,
    String? projectStageName,
    bool clearProject = false,
    String? leaveType,
    String? customLeave,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return WorkLogEditorState(
      status: status ?? this.status,
      selectedDate: selectedDate,
      existingEntry: existingEntry,
      existingAlreadyDirty: existingAlreadyDirty,
      type: type ?? this.type,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      note: note ?? this.note,
      tripLocation: tripLocation ?? this.tripLocation,
      transport: transport ?? this.transport,
      expenseText: expenseText ?? this.expenseText,
      isReimbursed: isReimbursed ?? this.isReimbursed,
      projectId: clearProject ? null : projectId ?? this.projectId,
      projectSyncId: clearProject ? null : projectSyncId ?? this.projectSyncId,
      projectName: clearProject ? '' : projectName ?? this.projectName,
      projectStageName: clearProject
          ? ''
          : projectStageName ?? this.projectStageName,
      leaveType: leaveType ?? this.leaveType,
      customLeave: customLeave ?? this.customLeave,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedDate,
    existingEntry,
    existingAlreadyDirty,
    type,
    overtimeHours,
    note,
    tripLocation,
    transport,
    expenseText,
    isReimbursed,
    projectId,
    projectSyncId,
    projectName,
    projectStageName,
    leaveType,
    customLeave,
    failure,
  ];
}

final class WorkLogEditorCubit extends Cubit<WorkLogEditorState> {
  final SaveWorkLogEntry _saveEntry;
  final DeleteWorkLogEntry _deleteEntry;

  WorkLogEditorCubit({
    required SaveWorkLogEntry saveEntry,
    required DeleteWorkLogEntry deleteEntry,
    required DateTime selectedDate,
    WorkLogEntry? existingEntry,
    WorkLogEntryType? initialType,
    bool existingAlreadyDirty = false,
  }) : _saveEntry = saveEntry,
       _deleteEntry = deleteEntry,
       super(
         WorkLogEditorState.initial(
           selectedDate: selectedDate,
           existingEntry: existingEntry,
           initialType: initialType,
           existingAlreadyDirty: existingAlreadyDirty,
         ),
       );

  void changeType(WorkLogEntryType type) {
    emit(
      _editingState(
        type: type,
        clearProject: type != WorkLogEntryType.businessTrip,
      ),
    );
  }

  void changeNote(String note) {
    emit(_editingState(note: note));
  }

  void changeOvertime(double overtimeHours) {
    emit(_editingState(overtimeHours: overtimeHours));
  }

  void changeTripLocation(String location) {
    emit(_editingState(tripLocation: location));
  }

  void changeTransport(String transport) {
    emit(_editingState(transport: transport));
  }

  void changeExpenseText(String expenseText) {
    emit(_editingState(expenseText: expenseText));
  }

  void changeReimbursed(bool isReimbursed) {
    emit(_editingState(isReimbursed: isReimbursed));
  }

  void changeProject({int? id, String? syncId, String? name}) {
    final trimmedName = name?.trim() ?? '';
    emit(
      _editingState(
        projectId: id,
        projectSyncId: syncId,
        projectName: trimmedName,
        projectStageName: '',
        clearProject: id == null && syncId == null && trimmedName.isEmpty,
      ),
    );
  }

  void changeProjectStageName(String projectStageName) {
    emit(_editingState(projectStageName: projectStageName.trim()));
  }

  void changeLeaveType(String leaveType) {
    emit(_editingState(leaveType: leaveType));
  }

  void changeCustomLeave(String customLeave) {
    emit(_editingState(customLeave: customLeave));
  }

  Future<void> submit() async {
    if (state.status == WorkLogEditorStatus.submitting) return;

    final entry = _entryFromState();
    if (entry == null) return;

    emit(
      state.copyWith(
        status: WorkLogEditorStatus.submitting,
        clearFailure: true,
      ),
    );
    final result = await _saveEntry(entry, markDirty: _shouldMarkDirty(entry));
    result.when(
      success: (_) => emit(state.copyWith(status: WorkLogEditorStatus.saved)),
      failure: (failure) => emit(
        state.copyWith(status: WorkLogEditorStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> delete() async {
    if (state.status == WorkLogEditorStatus.deleting) return;

    final existing = state.existingEntry;
    if (existing == null) {
      emit(
        state.copyWith(
          status: WorkLogEditorStatus.failure,
          failure: const AppFailure(
            code: 'work-log/editor/delete-missing-entry',
            message: 'Cannot delete a work-log entry that has not been saved.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: WorkLogEditorStatus.deleting, clearFailure: true),
    );
    final result = await _deleteEntry(existing.id);
    result.when(
      success: (_) => emit(state.copyWith(status: WorkLogEditorStatus.deleted)),
      failure: (failure) => emit(
        state.copyWith(status: WorkLogEditorStatus.failure, failure: failure),
      ),
    );
  }

  WorkLogEditorState _editingState({
    WorkLogEntryType? type,
    double? overtimeHours,
    String? note,
    String? tripLocation,
    String? transport,
    String? expenseText,
    bool? isReimbursed,
    int? projectId,
    String? projectSyncId,
    String? projectName,
    String? projectStageName,
    bool clearProject = false,
    String? leaveType,
    String? customLeave,
  }) {
    return state.copyWith(
      status: WorkLogEditorStatus.editing,
      type: type,
      overtimeHours: overtimeHours,
      note: note,
      tripLocation: tripLocation,
      transport: transport,
      expenseText: expenseText,
      isReimbursed: isReimbursed,
      projectId: projectId,
      projectSyncId: projectSyncId,
      projectName: projectName,
      projectStageName: projectStageName,
      clearProject: clearProject,
      leaveType: leaveType,
      customLeave: customLeave,
      clearFailure: true,
    );
  }

  WorkLogEntry? _entryFromState() {
    double? expenses;
    if (state.type == WorkLogEntryType.businessTrip) {
      final expenseText = state.expenseText.trim();
      if (expenseText.isNotEmpty) {
        expenses = double.tryParse(expenseText);
        if (expenses == null || expenses < 0) {
          emit(
            state.copyWith(
              status: WorkLogEditorStatus.failure,
              failure: const AppFailure(
                code: 'work-log/editor/invalid-expense',
                message: '垫付金额格式不正确',
              ),
            ),
          );
          return null;
        }
      }
    }

    return switch (state.type) {
      WorkLogEntryType.work => WorkLogEntry(
        id: state.existingEntry?.id ?? 0,
        syncId: state.existingEntry?.syncId,
        date: state.selectedDate,
        type: state.type,
        overtimeHours: state.overtimeHours,
        note: state.note,
        createdAt: state.existingEntry?.createdAt,
        updatedAt: state.existingEntry?.updatedAt,
      ),
      WorkLogEntryType.rest => WorkLogEntry(
        id: state.existingEntry?.id ?? 0,
        syncId: state.existingEntry?.syncId,
        date: state.selectedDate,
        type: state.type,
        note: state.note,
        createdAt: state.existingEntry?.createdAt,
        updatedAt: state.existingEntry?.updatedAt,
      ),
      WorkLogEntryType.leave => WorkLogEntry(
        id: state.existingEntry?.id ?? 0,
        syncId: state.existingEntry?.syncId,
        date: state.selectedDate,
        type: state.type,
        location: state.leaveType == '其他'
            ? (state.customLeave.trim().isEmpty
                  ? '请假'
                  : state.customLeave.trim())
            : state.leaveType,
        note: state.note,
        createdAt: state.existingEntry?.createdAt,
        updatedAt: state.existingEntry?.updatedAt,
      ),
      WorkLogEntryType.businessTrip => WorkLogEntry(
        id: state.existingEntry?.id ?? 0,
        syncId: state.existingEntry?.syncId,
        date: state.selectedDate,
        type: state.type,
        location: state.tripLocation,
        transport: state.transport,
        expenses: expenses,
        isReimbursed: state.isReimbursed,
        projectId: state.projectId,
        projectSyncId: _emptyToNull(state.projectSyncId ?? ''),
        projectName: _emptyToNull(state.projectName),
        projectStageName: _emptyToNull(state.projectStageName),
        note: state.note,
        createdAt: state.existingEntry?.createdAt,
        updatedAt: state.existingEntry?.updatedAt,
      ),
    };
  }

  bool _shouldMarkDirty(WorkLogEntry entry) {
    final existing = state.existingEntry;
    if (existing == null || state.existingAlreadyDirty) {
      return true;
    }
    return _hasBusinessChanges(entry, existing);
  }

  bool _hasBusinessChanges(WorkLogEntry next, WorkLogEntry previous) {
    return dateOnlyLocal(next.date) != dateOnlyLocal(previous.date) ||
        next.type != previous.type ||
        next.overtimeHours != previous.overtimeHours ||
        next.location != previous.location ||
        next.transport != previous.transport ||
        next.expenses != previous.expenses ||
        next.projectId != previous.projectId ||
        next.projectSyncId != previous.projectSyncId ||
        next.projectName != previous.projectName ||
        next.projectStageName != previous.projectStageName ||
        next.isReimbursed != previous.isReimbursed ||
        next.note != previous.note;
  }
}

String _formatNumber(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
