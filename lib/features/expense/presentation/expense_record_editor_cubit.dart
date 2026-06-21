import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';

enum ExpenseRecordEditorStatus {
  editing,
  submitting,
  saved,
  deleting,
  deleted,
  failure,
}

final class ExpenseRecordEditorState extends Equatable {
  final ExpenseRecordEditorStatus status;
  final DateTime selectedDate;
  final ExpenseRecordEntry? existingEntry;
  final bool existingAlreadyDirty;
  final String amountText;
  final String currency;
  final ExpenseRecordEntryCategory category;
  final String merchant;
  final String projectName;
  final String note;
  final AppFailure? failure;

  const ExpenseRecordEditorState({
    required this.status,
    required this.selectedDate,
    required this.existingEntry,
    required this.existingAlreadyDirty,
    required this.amountText,
    required this.currency,
    required this.category,
    required this.merchant,
    required this.projectName,
    required this.note,
    this.failure,
  });

  factory ExpenseRecordEditorState.initial({
    required DateTime selectedDate,
    ExpenseRecordEntry? existingEntry,
    bool existingAlreadyDirty = false,
    String? initialProjectName,
  }) {
    final entry = existingEntry;
    return ExpenseRecordEditorState(
      status: ExpenseRecordEditorStatus.editing,
      selectedDate: dateOnlyLocal(entry?.expenseDate ?? selectedDate),
      existingEntry: entry,
      existingAlreadyDirty: existingAlreadyDirty,
      amountText: _formatNumber(entry?.amount),
      currency: entry?.currency ?? 'CNY',
      category: entry?.category ?? ExpenseRecordEntryCategory.other,
      merchant: entry?.merchant ?? '',
      projectName: entry?.projectName ?? initialProjectName?.trim() ?? '',
      note: entry?.note ?? '',
    );
  }

  ExpenseRecordEditorState copyWith({
    ExpenseRecordEditorStatus? status,
    DateTime? selectedDate,
    String? amountText,
    String? currency,
    ExpenseRecordEntryCategory? category,
    String? merchant,
    String? projectName,
    String? note,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ExpenseRecordEditorState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      existingEntry: existingEntry,
      existingAlreadyDirty: existingAlreadyDirty,
      amountText: amountText ?? this.amountText,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      projectName: projectName ?? this.projectName,
      note: note ?? this.note,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedDate,
    existingEntry,
    existingAlreadyDirty,
    amountText,
    currency,
    category,
    merchant,
    projectName,
    note,
    failure,
  ];
}

final class ExpenseRecordEditorCubit extends Cubit<ExpenseRecordEditorState> {
  final SaveExpenseRecordEntry _saveEntry;
  final DeleteExpenseRecordEntry _deleteEntry;

  ExpenseRecordEditorCubit({
    required SaveExpenseRecordEntry saveEntry,
    required DeleteExpenseRecordEntry deleteEntry,
    required DateTime selectedDate,
    ExpenseRecordEntry? existingEntry,
    bool existingAlreadyDirty = false,
    String? initialProjectName,
  }) : _saveEntry = saveEntry,
       _deleteEntry = deleteEntry,
       super(
         ExpenseRecordEditorState.initial(
           selectedDate: selectedDate,
           existingEntry: existingEntry,
           existingAlreadyDirty: existingAlreadyDirty,
           initialProjectName: initialProjectName,
         ),
       );

  void changeDate(DateTime selectedDate) {
    emit(_editingState(selectedDate: dateOnlyLocal(selectedDate)));
  }

  void changeAmountText(String amountText) {
    emit(_editingState(amountText: amountText));
  }

  void changeCategory(ExpenseRecordEntryCategory category) {
    emit(_editingState(category: category));
  }

  void changeMerchant(String merchant) {
    emit(_editingState(merchant: merchant));
  }

  void changeProjectName(String projectName) {
    emit(_editingState(projectName: projectName));
  }

  void changeNote(String note) {
    emit(_editingState(note: note));
  }

  Future<void> submit() async {
    if (state.status == ExpenseRecordEditorStatus.submitting) return;

    final entry = _entryFromState();
    if (entry == null) return;

    emit(
      state.copyWith(
        status: ExpenseRecordEditorStatus.submitting,
        clearFailure: true,
      ),
    );
    final result = await _saveEntry(entry, markDirty: _shouldMarkDirty(entry));
    result.when(
      success: (_) =>
          emit(state.copyWith(status: ExpenseRecordEditorStatus.saved)),
      failure: (failure) => emit(
        state.copyWith(
          status: ExpenseRecordEditorStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> delete() async {
    if (state.status == ExpenseRecordEditorStatus.deleting) return;

    final existing = state.existingEntry;
    if (existing == null) {
      emit(
        state.copyWith(
          status: ExpenseRecordEditorStatus.failure,
          failure: const AppFailure(
            code: 'expense-record/editor/delete-missing-entry',
            message: 'Cannot delete an expense record that has not been saved.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ExpenseRecordEditorStatus.deleting,
        clearFailure: true,
      ),
    );
    final result = await _deleteEntry(existing.id);
    result.when(
      success: (_) =>
          emit(state.copyWith(status: ExpenseRecordEditorStatus.deleted)),
      failure: (failure) => emit(
        state.copyWith(
          status: ExpenseRecordEditorStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  ExpenseRecordEditorState _editingState({
    DateTime? selectedDate,
    String? amountText,
    ExpenseRecordEntryCategory? category,
    String? merchant,
    String? projectName,
    String? note,
  }) {
    return state.copyWith(
      status: ExpenseRecordEditorStatus.editing,
      selectedDate: selectedDate,
      amountText: amountText,
      category: category,
      merchant: merchant,
      projectName: projectName,
      note: note,
      clearFailure: true,
    );
  }

  ExpenseRecordEntry? _entryFromState() {
    final amount = double.tryParse(state.amountText.trim());
    if (amount == null || amount < 0) {
      emit(
        state.copyWith(
          status: ExpenseRecordEditorStatus.failure,
          failure: const AppFailure(
            code: 'expense-record/editor/invalid-amount',
            message: '请输入有效金额',
          ),
        ),
      );
      return null;
    }

    return ExpenseRecordEntry(
      id: state.existingEntry?.id ?? 0,
      expenseDate: state.selectedDate,
      amount: amount,
      currency: state.currency,
      category: state.category,
      merchant: _emptyToNull(state.merchant),
      projectId: state.existingEntry?.projectId,
      projectName: _emptyToNull(state.projectName),
      note: _emptyToNull(state.note),
    );
  }

  bool _shouldMarkDirty(ExpenseRecordEntry entry) {
    final existing = state.existingEntry;
    if (existing == null || state.existingAlreadyDirty) {
      return true;
    }
    return _hasBusinessChanges(entry, existing);
  }

  bool _hasBusinessChanges(
    ExpenseRecordEntry next,
    ExpenseRecordEntry previous,
  ) {
    return dateOnlyLocal(next.expenseDate) !=
            dateOnlyLocal(previous.expenseDate) ||
        next.amount != previous.amount ||
        next.currency != previous.currency ||
        next.category != previous.category ||
        _normalizeText(next.merchant) != _normalizeText(previous.merchant) ||
        _normalizeText(next.note) != _normalizeText(previous.note) ||
        next.projectId != previous.projectId ||
        _normalizeText(next.projectName) !=
            _normalizeText(previous.projectName);
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

String _normalizeText(String? value) => value?.trim() ?? '';
