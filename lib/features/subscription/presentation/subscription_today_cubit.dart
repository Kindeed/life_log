import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/subscription/application/load_subscription_today.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_today_snapshot.dart';

enum SubscriptionTodayStatus { initial, loading, ready, failure }

final class SubscriptionTodayState extends Equatable {
  final SubscriptionTodayStatus status;
  final SubscriptionTodaySnapshot snapshot;
  final AppFailure? failure;

  const SubscriptionTodayState({
    required this.status,
    required this.snapshot,
    this.failure,
  });

  factory SubscriptionTodayState.initial(DateTime now) {
    return SubscriptionTodayState(
      status: SubscriptionTodayStatus.initial,
      snapshot: SubscriptionTodaySnapshot.empty(dateOnlyLocal(now)),
    );
  }

  SubscriptionTodayState copyWith({
    SubscriptionTodayStatus? status,
    SubscriptionTodaySnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return SubscriptionTodayState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, failure];
}

final class SubscriptionTodayCubit extends Cubit<SubscriptionTodayState> {
  final LoadSubscriptionToday _loadToday;
  final WatchSubscriptionEntries _watchEntries;
  final DateTime Function() _todayProvider;
  StreamSubscription<void>? _entriesSubscription;

  SubscriptionTodayCubit({
    required LoadSubscriptionToday loadToday,
    required WatchSubscriptionEntries watchEntries,
    DateTime Function()? todayProvider,
  }) : _loadToday = loadToday,
       _watchEntries = watchEntries,
       _todayProvider = todayProvider ?? DateTime.now,
       super(SubscriptionTodayState.initial((todayProvider ?? DateTime.now)()));

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
      state.copyWith(
        status: SubscriptionTodayStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _loadToday(_todayProvider());
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        emit(
          state.copyWith(
            status: SubscriptionTodayStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
      },
      failure: (failure) {
        emit(
          state.copyWith(
            status: SubscriptionTodayStatus.failure,
            failure: failure,
          ),
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
