import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/work_log/application/load_work_log_today.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_today_snapshot.dart';

enum WorkLogTodayStatus { initial, loading, ready, failure }

final class WorkLogTodayState extends Equatable {
  final WorkLogTodayStatus status;
  final WorkLogTodaySnapshot snapshot;
  final AppFailure? failure;

  const WorkLogTodayState({
    required this.status,
    required this.snapshot,
    this.failure,
  });

  factory WorkLogTodayState.initial(DateTime now) {
    return WorkLogTodayState(
      status: WorkLogTodayStatus.initial,
      snapshot: WorkLogTodaySnapshot.empty(dateOnlyLocal(now)),
    );
  }

  WorkLogTodayState copyWith({
    WorkLogTodayStatus? status,
    WorkLogTodaySnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return WorkLogTodayState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, failure];
}

final class WorkLogTodayCubit extends Cubit<WorkLogTodayState> {
  final LoadWorkLogToday _loadToday;
  final WatchWorkLogEntries _watchEntries;
  final DateTime Function() _todayProvider;
  StreamSubscription<void>? _entriesSubscription;

  WorkLogTodayCubit({
    required LoadWorkLogToday loadToday,
    required WatchWorkLogEntries watchEntries,
    DateTime Function()? todayProvider,
  }) : _loadToday = loadToday,
       _watchEntries = watchEntries,
       _todayProvider = todayProvider ?? DateTime.now,
       super(WorkLogTodayState.initial((todayProvider ?? DateTime.now)()));

  void start() {
    if (_entriesSubscription != null) return;

    unawaited(loadToday());
    _entriesSubscription = _watchEntries().listen((_) {
      unawaited(loadToday());
    });
  }

  Future<void> loadToday() async {
    if (isClosed) return;
    emit(
      state.copyWith(status: WorkLogTodayStatus.loading, clearFailure: true),
    );

    final result = await _loadToday(_todayProvider());
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        emit(
          state.copyWith(
            status: WorkLogTodayStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
      },
      failure: (failure) {
        emit(
          state.copyWith(status: WorkLogTodayStatus.failure, failure: failure),
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
