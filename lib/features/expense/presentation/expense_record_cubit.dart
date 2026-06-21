import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry_stats.dart';

enum ExpenseRecordStatus { initial, loading, ready, failure }

final class ExpenseRecordState extends Equatable {
  final ExpenseRecordStatus status;
  final List<ExpenseRecordEntry> entries;
  final DateTime referenceDay;
  final double currentMonthTotal;
  final AppFailure? failure;

  const ExpenseRecordState._({
    required this.status,
    required this.entries,
    required this.referenceDay,
    required this.currentMonthTotal,
    this.failure,
  });

  factory ExpenseRecordState.initial(DateTime now) {
    return ExpenseRecordState.ready(
      entries: const [],
      referenceDay: now,
      status: ExpenseRecordStatus.initial,
    );
  }

  factory ExpenseRecordState.ready({
    required List<ExpenseRecordEntry> entries,
    required DateTime referenceDay,
    ExpenseRecordStatus status = ExpenseRecordStatus.ready,
    AppFailure? failure,
  }) {
    final localReference = dateOnlyLocal(referenceDay);
    final stableEntries = List<ExpenseRecordEntry>.unmodifiable(entries);
    return ExpenseRecordState._(
      status: status,
      entries: stableEntries,
      referenceDay: localReference,
      currentMonthTotal: stableEntries
          .inMonth(DateTime(localReference.year, localReference.month))
          .totalAmount,
      failure: failure,
    );
  }

  ExpenseRecordState copyWith({
    ExpenseRecordStatus? status,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ExpenseRecordState._(
      status: status ?? this.status,
      entries: entries,
      referenceDay: referenceDay,
      currentMonthTotal: currentMonthTotal,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  List<ExpenseRecordEntry> entriesForProject(String projectName) {
    return entries.where((entry) => entry.projectName == projectName).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  double totalForProject(String projectName) {
    return entriesForProject(
      projectName,
    ).fold(0.0, (sum, entry) => sum + entry.amount);
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    referenceDay,
    currentMonthTotal,
    failure,
  ];
}

final class ExpenseRecordCubit extends Cubit<ExpenseRecordState> {
  final LoadExpenseRecordEntries _loadEntries;
  final WatchExpenseRecordEntries _watchEntries;
  final DateTime Function() _now;
  StreamSubscription<void>? _entriesSubscription;

  ExpenseRecordCubit({
    required LoadExpenseRecordEntries loadEntries,
    required WatchExpenseRecordEntries watchEntries,
    DateTime Function()? initialNow,
  }) : _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       _now = initialNow ?? DateTime.now,
       super(ExpenseRecordState.initial((initialNow ?? DateTime.now)()));

  void start() {
    if (_entriesSubscription != null) return;

    unawaited(loadEntries());
    _entriesSubscription = _watchEntries().listen((_) {
      unawaited(loadEntries());
    });
  }

  Future<void> loadEntries() async {
    if (isClosed) return;
    emit(
      state.copyWith(status: ExpenseRecordStatus.loading, clearFailure: true),
    );

    final result = await _loadEntries();
    if (isClosed) return;
    result.when(
      success: (entries) {
        emit(ExpenseRecordState.ready(entries: entries, referenceDay: _now()));
      },
      failure: (failure) {
        emit(
          state.copyWith(status: ExpenseRecordStatus.failure, failure: failure),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }
}
