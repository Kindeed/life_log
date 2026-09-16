import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry_stats.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';

enum SubscriptionReadStatus { initial, loading, ready, failure }

enum SubscriptionFilter { all, monthly, yearly, oneTime }

enum SubscriptionSortMode { manual, date, price }

final class SubscriptionState extends Equatable {
  final SubscriptionReadStatus status;
  final List<SubscriptionEntry> entries;
  final List<SubscriptionEntry> visibleEntries;
  final List<SubscriptionEntry> dueSoonEntries;
  final List<SubscriptionEntry> reminderEntries;
  final double currentMonthCost;
  final double yearlyCost;
  final SubscriptionExchangeRates exchangeRates;
  final bool exchangeRatesLoading;
  final SubscriptionFilter filter;
  final SubscriptionSortMode sortMode;
  final DateTime referenceDay;
  final AppFailure? failure;

  const SubscriptionState._({
    required this.status,
    required this.entries,
    required this.visibleEntries,
    required this.dueSoonEntries,
    required this.reminderEntries,
    required this.currentMonthCost,
    required this.yearlyCost,
    required this.exchangeRates,
    required this.exchangeRatesLoading,
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
      status: SubscriptionReadStatus.initial,
    );
  }

  factory SubscriptionState.ready({
    required List<SubscriptionEntry> entries,
    required SubscriptionFilter filter,
    required SubscriptionSortMode sortMode,
    required DateTime referenceDay,
    SubscriptionExchangeRates? exchangeRates,
    bool exchangeRatesLoading = false,
    SubscriptionReadStatus status = SubscriptionReadStatus.ready,
    AppFailure? failure,
  }) {
    final localReference = dateOnlyLocal(referenceDay);
    final stableEntries = List<SubscriptionEntry>.unmodifiable(entries);
    final visible = _visibleEntries(stableEntries, filter, sortMode);
    final rates =
        exchangeRates ?? SubscriptionExchangeRates.cnyOnly(localReference);

    return SubscriptionState._(
      status: status,
      entries: stableEntries,
      visibleEntries: List<SubscriptionEntry>.unmodifiable(visible),
      dueSoonEntries: List<SubscriptionEntry>.unmodifiable(
        stableEntries.dueSoonFrom(localReference),
      ),
      reminderEntries: List<SubscriptionEntry>.unmodifiable(
        stableEntries.dueForReminderFrom(localReference),
      ),
      currentMonthCost: stableEntries.totalCostForMonthInCny(
        DateTime(localReference.year, localReference.month),
        rates,
      ),
      yearlyCost: stableEntries.totalYearlyCostInCny(rates),
      exchangeRates: rates,
      exchangeRatesLoading: exchangeRatesLoading,
      filter: filter,
      sortMode: sortMode,
      referenceDay: localReference,
      failure: failure,
    );
  }

  SubscriptionState copyWith({
    SubscriptionReadStatus? status,
    AppFailure? failure,
    SubscriptionExchangeRates? exchangeRates,
    bool? exchangeRatesLoading,
    bool clearFailure = false,
  }) {
    return SubscriptionState.ready(
      entries: entries,
      filter: filter,
      sortMode: sortMode,
      referenceDay: referenceDay,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      exchangeRatesLoading: exchangeRatesLoading ?? this.exchangeRatesLoading,
      status: status ?? this.status,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  Set<SubscriptionCurrency> get currenciesWithoutRates =>
      entries.currenciesWithoutRates(exchangeRates);

  @override
  List<Object?> get props => [
    status,
    entries,
    visibleEntries,
    dueSoonEntries,
    reminderEntries,
    currentMonthCost,
    yearlyCost,
    exchangeRates,
    exchangeRatesLoading,
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
  final Future<SubscriptionExchangeRates> Function(DateTime)?
  _loadExchangeRates;
  StreamSubscription<void>? _entriesSubscription;
  int _loadRequestId = 0;

  SubscriptionCubit({
    required LoadSubscriptionEntries loadEntries,
    required WatchSubscriptionEntries watchEntries,
    DateTime Function()? initialNow,
    Future<SubscriptionExchangeRates> Function(DateTime)? loadExchangeRates,
  }) : _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       _now = initialNow ?? DateTime.now,
       _loadExchangeRates = loadExchangeRates,
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
    final requestId = ++_loadRequestId;
    emit(
      state.copyWith(
        status: SubscriptionReadStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _loadEntries();
    if (isClosed || requestId != _loadRequestId) return;
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
        final loadRates = _loadExchangeRates;
        if (loadRates != null &&
            entries.any(
              (entry) =>
                  entry.currency != SubscriptionCurrency.cny &&
                  (entry.price ?? 0) > 0,
            )) {
          emit(state.copyWith(exchangeRatesLoading: true));
          unawaited(_refreshExchangeRates(requestId, loadRates));
        }
      },
      failure: (failure) {
        emit(
          state.copyWith(
            status: SubscriptionReadStatus.failure,
            failure: failure,
          ),
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
        exchangeRates: state.exchangeRates,
        exchangeRatesLoading: state.exchangeRatesLoading,
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
        exchangeRates: state.exchangeRates,
        exchangeRatesLoading: state.exchangeRatesLoading,
      ),
    );
  }

  Future<void> _refreshExchangeRates(
    int requestId,
    Future<SubscriptionExchangeRates> Function(DateTime) loadRates,
  ) async {
    try {
      final rates = await loadRates(_now());
      if (isClosed || requestId != _loadRequestId) return;
      emit(
        SubscriptionState.ready(
          entries: state.entries,
          filter: state.filter,
          sortMode: state.sortMode,
          referenceDay: _now(),
          exchangeRates: rates,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _loadRequestId) return;
      emit(
        SubscriptionState.ready(
          entries: state.entries,
          filter: state.filter,
          sortMode: state.sortMode,
          referenceDay: _now(),
          exchangeRates: SubscriptionExchangeRates.cnyOnly(
            _now(),
            warning: '汇率暂不可用，外币订阅暂不计入人民币统计',
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }
}
