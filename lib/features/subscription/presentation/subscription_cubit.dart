import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';

enum SubscriptionStatus { initial, loading, ready, failure }

enum SubscriptionFilter { all, monthly, yearly, oneTime }

enum SubscriptionSortMode { manual, date, price }

final class SubscriptionState extends Equatable {
  final SubscriptionStatus status;
  final List<SubscriptionEntry> entries;
  final List<SubscriptionEntry> visibleEntries;
  final List<SubscriptionEntry> dueSoonEntries;
  final double currentMonthCost;
  final double yearlyCost;
  final SubscriptionFilter filter;
  final SubscriptionSortMode sortMode;
  final DateTime referenceDay;
  final AppFailure? failure;

  const SubscriptionState._({
    required this.status,
    required this.entries,
    required this.visibleEntries,
    required this.dueSoonEntries,
    required this.currentMonthCost,
    required this.yearlyCost,
    required this.filter,
    required this.sortMode,
    required this.referenceDay,
    this.failure,
  });

  factory SubscriptionState.initial(DateTime now) {
    return SubscriptionState.ready(
      entries: const [],
      filter: SubscriptionFilter.all,
      sortMode: SubscriptionSortMode.manual,
      referenceDay: now,
      status: SubscriptionStatus.initial,
    );
  }

  factory SubscriptionState.ready({
    required List<SubscriptionEntry> entries,
    required SubscriptionFilter filter,
    required SubscriptionSortMode sortMode,
    required DateTime referenceDay,
    SubscriptionStatus status = SubscriptionStatus.ready,
    AppFailure? failure,
  }) {
    final localReference = dateOnlyLocal(referenceDay);
    final stableEntries = List<SubscriptionEntry>.unmodifiable(entries);
    final visible = _visibleEntries(stableEntries, filter, sortMode);

    return SubscriptionState._(
      status: status,
      entries: stableEntries,
      visibleEntries: List<SubscriptionEntry>.unmodifiable(visible),
      dueSoonEntries: List<SubscriptionEntry>.unmodifiable(
        stableEntries.dueSoonFrom(localReference),
      ),
      currentMonthCost: stableEntries.totalCostForMonth(
        DateTime(localReference.year, localReference.month),
      ),
      yearlyCost: stableEntries.totalYearlyCost,
      filter: filter,
      sortMode: sortMode,
      referenceDay: localReference,
      failure: failure,
    );
  }

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return SubscriptionState._(
      status: status ?? this.status,
      entries: entries,
      visibleEntries: visibleEntries,
      dueSoonEntries: dueSoonEntries,
      currentMonthCost: currentMonthCost,
      yearlyCost: yearlyCost,
      filter: filter,
      sortMode: sortMode,
      referenceDay: referenceDay,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    visibleEntries,
    dueSoonEntries,
    currentMonthCost,
    yearlyCost,
    filter,
    sortMode,
    referenceDay,
    failure,
  ];

  static List<SubscriptionEntry> _visibleEntries(
    List<SubscriptionEntry> entries,
    SubscriptionFilter filter,
    SubscriptionSortMode sortMode,
  ) {
    final filtered = entries.where((entry) {
      return switch (filter) {
        SubscriptionFilter.all => true,
        SubscriptionFilter.monthly =>
          entry.cycle == SubscriptionBillingCycle.monthly,
        SubscriptionFilter.yearly =>
          entry.cycle == SubscriptionBillingCycle.yearly,
        SubscriptionFilter.oneTime =>
          entry.cycle == SubscriptionBillingCycle.oneTime,
      };
    }).toList();

    switch (sortMode) {
      case SubscriptionSortMode.manual:
        filtered.sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));
        break;
      case SubscriptionSortMode.date:
        filtered.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
        break;
      case SubscriptionSortMode.price:
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
    }

    return filtered;
  }
}

final class SubscriptionCubit extends Cubit<SubscriptionState> {
  final LoadSubscriptionEntries _loadEntries;
  final WatchSubscriptionEntries _watchEntries;
  final DateTime Function() _now;
  StreamSubscription<void>? _entriesSubscription;

  SubscriptionCubit({
    required LoadSubscriptionEntries loadEntries,
    required WatchSubscriptionEntries watchEntries,
    DateTime Function()? initialNow,
  }) : _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       _now = initialNow ?? DateTime.now,
       super(SubscriptionState.initial((initialNow ?? DateTime.now)()));

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
      state.copyWith(status: SubscriptionStatus.loading, clearFailure: true),
    );

    final result = await _loadEntries();
    if (isClosed) return;
    result.when(
      success: (entries) {
        emit(
          SubscriptionState.ready(
            entries: entries,
            filter: state.filter,
            sortMode: state.sortMode,
            referenceDay: _now(),
          ),
        );
      },
      failure: (failure) {
        emit(
          state.copyWith(status: SubscriptionStatus.failure, failure: failure),
        );
      },
    );
  }

  void setFilter(SubscriptionFilter filter) {
    emit(
      SubscriptionState.ready(
        entries: state.entries,
        filter: filter,
        sortMode: state.sortMode,
        referenceDay: _now(),
      ),
    );
  }

  void setSortMode(SubscriptionSortMode sortMode) {
    emit(
      SubscriptionState.ready(
        entries: state.entries,
        filter: state.filter,
        sortMode: sortMode,
        referenceDay: _now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }
}
