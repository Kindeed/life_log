import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';

enum EvidenceEditorStatus {
  editing,
  submitting,
  saved,
  deleting,
  deleted,
  failure,
}

final class EvidenceEditorState extends Equatable {
  final EvidenceEditorStatus status;
  final DateTime evidenceDate;
  final DateTime? tripDate;
  final EvidenceEntry? existingEntry;
  final bool existingAlreadyDirty;
  final String amountText;
  final String currency;
  final EvidenceEntryCategory category;
  final EvidenceEntryStatus evidenceStatus;
  final String merchant;
  final String projectName;
  final String projectStageName;
  final String note;
  final String? pendingSourcePath;
  final String? pendingSourceExtension;
  final AppFailure? failure;

  const EvidenceEditorState({
    required this.status,
    required this.evidenceDate,
    required this.tripDate,
    required this.existingEntry,
    required this.existingAlreadyDirty,
    required this.amountText,
    required this.currency,
    required this.category,
    required this.evidenceStatus,
    required this.merchant,
    required this.projectName,
    required this.projectStageName,
    required this.note,
    this.pendingSourcePath,
    this.pendingSourceExtension,
    this.failure,
  });

  factory EvidenceEditorState.initial({
    required DateTime selectedDate,
    EvidenceEntry? existingEntry,
    bool existingAlreadyDirty = false,
    String? initialProjectName,
    String? sourcePath,
    String? sourceExtension,
  }) {
    final entry = existingEntry;
    return EvidenceEditorState(
      status: EvidenceEditorStatus.editing,
      evidenceDate: dateOnlyLocal(entry?.evidenceDate ?? selectedDate),
      tripDate: entry?.tripDate == null
          ? null
          : dateOnlyLocal(entry!.tripDate!),
      existingEntry: entry,
      existingAlreadyDirty: existingAlreadyDirty,
      amountText: _formatNumber(entry?.amount),
      currency: entry?.currency ?? 'CNY',
      category: entry?.category ?? EvidenceEntryCategory.invoice,
      evidenceStatus: entry?.status ?? EvidenceEntryStatus.pending,
      merchant: entry?.merchant ?? '',
      projectName: entry?.projectName ?? initialProjectName?.trim() ?? '',
      projectStageName: entry?.projectStageName ?? '',
      note: entry?.note ?? '',
      pendingSourcePath: sourcePath,
      pendingSourceExtension: sourceExtension,
    );
  }

  EvidenceEditorState copyWith({
    EvidenceEditorStatus? status,
    DateTime? evidenceDate,
    Object? tripDate = _sentinel,
    String? amountText,
    String? currency,
    EvidenceEntryCategory? category,
    EvidenceEntryStatus? evidenceStatus,
    String? merchant,
    String? projectName,
    String? projectStageName,
    String? note,
    Object? pendingSourcePath = _sentinel,
    Object? pendingSourceExtension = _sentinel,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return EvidenceEditorState(
      status: status ?? this.status,
      evidenceDate: evidenceDate ?? this.evidenceDate,
      tripDate: identical(tripDate, _sentinel)
          ? this.tripDate
          : tripDate as DateTime?,
      existingEntry: existingEntry,
      existingAlreadyDirty: existingAlreadyDirty,
      amountText: amountText ?? this.amountText,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      evidenceStatus: evidenceStatus ?? this.evidenceStatus,
      merchant: merchant ?? this.merchant,
      projectName: projectName ?? this.projectName,
      projectStageName: projectStageName ?? this.projectStageName,
      note: note ?? this.note,
      pendingSourcePath: identical(pendingSourcePath, _sentinel)
          ? this.pendingSourcePath
          : pendingSourcePath as String?,
      pendingSourceExtension: identical(pendingSourceExtension, _sentinel)
          ? this.pendingSourceExtension
          : pendingSourceExtension as String?,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    evidenceDate,
    tripDate,
    existingEntry,
    existingAlreadyDirty,
    amountText,
    currency,
    category,
    evidenceStatus,
    merchant,
    projectName,
    projectStageName,
    note,
    pendingSourcePath,
    pendingSourceExtension,
    failure,
  ];
}

final class EvidenceEditorCubit extends Cubit<EvidenceEditorState> {
  final SaveEvidenceEntry _saveEntry;
  final DeleteEvidenceEntry _deleteEntry;

  EvidenceEditorCubit({
    required SaveEvidenceEntry saveEntry,
    required DeleteEvidenceEntry deleteEntry,
    required DateTime selectedDate,
    EvidenceEntry? existingEntry,
    bool existingAlreadyDirty = false,
    String? initialProjectName,
    String? sourcePath,
    String? sourceExtension,
  }) : _saveEntry = saveEntry,
       _deleteEntry = deleteEntry,
       super(
         EvidenceEditorState.initial(
           selectedDate: selectedDate,
           existingEntry: existingEntry,
           existingAlreadyDirty: existingAlreadyDirty,
           initialProjectName: initialProjectName,
           sourcePath: sourcePath,
           sourceExtension: sourceExtension,
         ),
       );

  void changeEvidenceDate(DateTime evidenceDate) {
    emit(_editingState(evidenceDate: dateOnlyLocal(evidenceDate)));
  }

  void changeTripDate(DateTime? tripDate) {
    emit(
      _editingState(
        tripDate: tripDate == null ? null : dateOnlyLocal(tripDate),
      ),
    );
  }

  void changeAmountText(String amountText) {
    emit(_editingState(amountText: amountText));
  }

  void changeCategory(EvidenceEntryCategory category) {
    emit(_editingState(category: category));
  }

  void changeEvidenceStatus(EvidenceEntryStatus evidenceStatus) {
    emit(_editingState(evidenceStatus: evidenceStatus));
  }

  void changeMerchant(String merchant) {
    emit(_editingState(merchant: merchant));
  }

  void changeProjectName(String projectName) {
    emit(_editingState(projectName: projectName, projectStageName: ''));
  }

  void changeProjectStageName(String projectStageName) {
    emit(_editingState(projectStageName: projectStageName.trim()));
  }

  void changeNote(String note) {
    emit(_editingState(note: note));
  }

  void changeAttachment(String sourcePath, {String? sourceExtension}) {
    emit(
      _editingState(
        pendingSourcePath: sourcePath,
        pendingSourceExtension: sourceExtension,
      ),
    );
  }

  Future<void> submit() async {
    if (state.status == EvidenceEditorStatus.submitting) return;

    final entry = _entryFromState();
    if (entry == null) return;

    emit(
      state.copyWith(
        status: EvidenceEditorStatus.submitting,
        clearFailure: true,
      ),
    );
    final result = await _saveEntry(
      entry,
      markDirty: _shouldMarkDirty(entry),
      sourcePath: state.pendingSourcePath,
      sourceExtension: state.pendingSourceExtension,
    );
    result.when(
      success: (_) => emit(state.copyWith(status: EvidenceEditorStatus.saved)),
      failure: (failure) => emit(
        state.copyWith(status: EvidenceEditorStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> delete() async {
    if (state.status == EvidenceEditorStatus.deleting) return;

    final existing = state.existingEntry;
    if (existing == null) {
      emit(
        state.copyWith(
          status: EvidenceEditorStatus.failure,
          failure: const AppFailure(
            code: 'evidence/editor/delete-missing-entry',
            message: 'Cannot delete evidence that has not been saved.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: EvidenceEditorStatus.deleting, clearFailure: true),
    );
    final result = await _deleteEntry(existing.id);
    result.when(
      success: (_) =>
          emit(state.copyWith(status: EvidenceEditorStatus.deleted)),
      failure: (failure) => emit(
        state.copyWith(status: EvidenceEditorStatus.failure, failure: failure),
      ),
    );
  }

  EvidenceEditorState _editingState({
    DateTime? evidenceDate,
    Object? tripDate = _sentinel,
    String? amountText,
    String? currency,
    EvidenceEntryCategory? category,
    EvidenceEntryStatus? evidenceStatus,
    String? merchant,
    String? projectName,
    String? projectStageName,
    String? note,
    Object? pendingSourcePath = _sentinel,
    Object? pendingSourceExtension = _sentinel,
  }) {
    return state.copyWith(
      status: EvidenceEditorStatus.editing,
      evidenceDate: evidenceDate,
      tripDate: tripDate,
      amountText: amountText,
      currency: currency,
      category: category,
      evidenceStatus: evidenceStatus,
      merchant: merchant,
      projectName: projectName,
      projectStageName: projectStageName,
      note: note,
      pendingSourcePath: pendingSourcePath,
      pendingSourceExtension: pendingSourceExtension,
      clearFailure: true,
    );
  }

  EvidenceEntry? _entryFromState() {
    final projectName = state.projectName.trim();
    if (projectName.isEmpty) {
      emit(
        state.copyWith(
          status: EvidenceEditorStatus.failure,
          failure: const AppFailure(
            code: 'evidence/editor/missing-project',
            message: '请输入项目名称',
          ),
        ),
      );
      return null;
    }

    final amountText = state.amountText.trim();
    final amount = amountText.isEmpty ? null : double.tryParse(amountText);
    if (amountText.isNotEmpty && (amount == null || amount < 0)) {
      emit(
        state.copyWith(
          status: EvidenceEditorStatus.failure,
          failure: const AppFailure(
            code: 'evidence/editor/invalid-amount',
            message: '请输入有效金额',
          ),
        ),
      );
      return null;
    }

    return EvidenceEntry(
      id: state.existingEntry?.id ?? 0,
      projectName: projectName,
      projectId: state.existingEntry?.projectId,
      projectSyncId: state.existingEntry?.projectSyncId,
      projectStageName: _emptyToNull(state.projectStageName),
      evidenceDate: state.evidenceDate,
      amount: amount,
      currency: state.currency,
      category: state.category,
      status: state.evidenceStatus,
      merchant: _emptyToNull(state.merchant),
      note: _emptyToNull(state.note),
      localFilePath: state.existingEntry?.localFilePath,
      remoteStoragePath: state.existingEntry?.remoteStoragePath,
      fileName: state.existingEntry?.fileName,
      mimeType: state.existingEntry?.mimeType,
      uploadedAt: state.existingEntry?.uploadedAt,
      tripDate: state.tripDate,
    );
  }

  bool _shouldMarkDirty(EvidenceEntry entry) {
    final existing = state.existingEntry;
    if (existing == null ||
        state.existingAlreadyDirty ||
        state.pendingSourcePath != null) {
      return true;
    }
    return _hasBusinessChanges(entry, existing);
  }

  bool _hasBusinessChanges(EvidenceEntry next, EvidenceEntry previous) {
    return dateOnlyLocal(next.evidenceDate) !=
            dateOnlyLocal(previous.evidenceDate) ||
        next.amount != previous.amount ||
        next.currency != previous.currency ||
        next.category != previous.category ||
        next.status != previous.status ||
        _normalizeText(next.merchant) != _normalizeText(previous.merchant) ||
        _normalizeText(next.note) != _normalizeText(previous.note) ||
        _normalizeText(next.projectName) !=
            _normalizeText(previous.projectName) ||
        _normalizeText(next.projectSyncId) !=
            _normalizeText(previous.projectSyncId) ||
        _normalizeText(next.projectStageName) !=
            _normalizeText(previous.projectStageName) ||
        _dateOnlyOrNull(next.tripDate) != _dateOnlyOrNull(previous.tripDate);
  }
}

const Object _sentinel = Object();

DateTime? _dateOnlyOrNull(DateTime? value) {
  return value == null ? null : dateOnlyLocal(value);
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

String _normalizeText(String? value) => value?.trim() ?? '';
