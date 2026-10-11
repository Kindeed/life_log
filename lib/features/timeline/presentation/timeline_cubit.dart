import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/state/coalesced_refresh.dart';
import 'package:life_log/features/timeline/application/timeline_query.dart';
import 'package:life_log/features/timeline/domain/timeline_record.dart';

final class TimelineState {
  final TimelineFilter filter;
  final TimelineDateRange? range;
  final List<TimelineRow> rows;
  final Map<String, int> rowIndexes;
  final List<TimelineRecord> allRecords;
  final int visibleCount;
  final int totalCount;
  final Set<TimelineFilter> loadingSources;
  final Map<TimelineFilter, AppFailure> failures;

  const TimelineState({
    this.filter = TimelineFilter.all,
    this.range,
    this.rows = const [],
    this.rowIndexes = const {},
    this.allRecords = const [],
    this.visibleCount = 0,
    this.totalCount = 0,
    this.loadingSources = const {},
    this.failures = const {},
  });

  String get selectionKey => '${filter.name}:${range?.key ?? 'all-dates'}';
  bool get hasMore => visibleCount < totalCount;
  Set<TimelineFilter> get selectedSources =>
      filter == TimelineFilter.all ? TimelineQuery.sources : {filter};
  bool get isLoading => loadingSources.any(selectedSources.contains);
  Map<TimelineFilter, AppFailure> get visibleFailures => Map.fromEntries(
    failures.entries.where((entry) => selectedSources.contains(entry.key)),
  );
}

/// Owns route-local snapshots and display pagination. A source failure keeps
/// only that source's cache; an account-scope change always drops every cache.
final class TimelineCubit extends Cubit<TimelineState> {
  final TimelineQuery query;
  final int pageSize;
  final _subscriptions = <StreamSubscription<void>>[];
  final _cachedSources = <TimelineFilter, List<TimelineRecord>>{};
  final _failures = <TimelineFilter, AppFailure>{};
  final _pending = <TimelineFilter>{};
  final _watchPending = <TimelineFilter>{};
  final _visibleLimits = <String, int>{};
  late CoalescedRefresh _watchRefresh = _createWatchRefresh();

  CoalescedRefresh _createWatchRefresh() => CoalescedRefresh(
    refresh: () {
      final sources = Set<TimelineFilter>.of(_watchPending);
      _watchPending.clear();
      return refresh(sources: sources);
    },
  );
  List<TimelineRecord> _allRecords = const [];
  List<TimelineRecord> _selectedRecords = const [];
  Set<TimelineFilter> _loading = {};
  TimelineFilter _filter = TimelineFilter.all;
  TimelineDateRange? _range;
  Completer<void>? _refreshCompleter;
  int _scopeGeneration = 0;
  int _refreshRun = 0;
  bool _started = false;
  bool _closing = false;

  bool get _inactive => isClosed || _closing;

  TimelineCubit({required this.query, this.pageSize = 40})
    : assert(pageSize > 0),
      super(const TimelineState());

  void start() {
    if (_started || _inactive) return;
    _started = true;
    for (final source in TimelineQuery.sources) {
      _subscriptions.add(
        query
            .watch(source)
            .listen(
              (_) => _queueWatch(source),
              onError: (Object error, StackTrace stack) => _queueWatch(source),
            ),
      );
    }
    final watchScope = query.watchScope;
    if (watchScope != null) {
      _subscriptions.add(watchScope().listen((_) => _scopeChanged()));
    }
    unawaited(refresh());
  }

  void _queueWatch(TimelineFilter source) {
    if (_inactive) return;
    _watchPending.add(source);
    _watchRefresh.schedule();
  }

  void _scopeChanged() {
    if (_inactive) return;
    _watchRefresh.dispose();
    _watchPending.clear();
    _watchRefresh = _createWatchRefresh();
    _scopeGeneration++;
    _cachedSources.clear();
    _failures.clear();
    _visibleLimits.clear();
    _allRecords = const [];
    _selectedRecords = const [];
    _loading = Set.of(TimelineQuery.sources);
    _publish();
    // A blocked read for the previous account must not delay the next account.
    // Its eventual completion is ignored by both generation and run identity.
    _refreshRun++;
    _pending.clear();
    _refreshCompleter = null;
    unawaited(refresh());
  }

  Future<void> refresh({Set<TimelineFilter>? sources}) {
    if (_inactive) return Future.value();
    _pending.addAll(
      (sources ?? TimelineQuery.sources).intersection(TimelineQuery.sources),
    );
    final active = _refreshCompleter;
    if (active != null) return active.future;
    if (_pending.isEmpty) return Future.value();
    final completer = Completer<void>();
    _refreshCompleter = completer;
    unawaited(_drain(completer, _refreshRun));
    return completer.future;
  }

  Future<void> retry() => refresh(sources: state.visibleFailures.keys.toSet());

  Future<void> _drain(Completer<void> completer, int run) async {
    try {
      while (_pending.isNotEmpty && !_inactive && run == _refreshRun) {
        final sources = Set<TimelineFilter>.of(_pending);
        _pending.clear();
        final generation = _scopeGeneration;
        _loading = sources;
        _publish();
        await query.load(
          sources,
          onLoaded: (result) {
            if (_inactive || generation != _scopeGeneration) return;
            final failure = result.failure;
            if (failure != null) {
              _failures[result.source] = failure;
            } else {
              _cachedSources[result.source] = result.records;
              _failures.remove(result.source);
            }
            _allRecords = query.merge(_cachedSources.values);
            _selectRecords();
            _loading.remove(result.source);
            _publish();
          },
        );
        if (_inactive) return;
        if (generation != _scopeGeneration) continue;
        _loading = {};
        _publish();
      }
    } finally {
      if (identical(_refreshCompleter, completer)) _refreshCompleter = null;
      completer.complete();
    }
  }

  void selectFilter(TimelineFilter filter) {
    if (_inactive || filter == _filter) return;
    _filter = filter;
    _selectRecords();
    _publish();
  }

  void selectRange(TimelineDateRange? range) {
    if (_inactive || range?.key == _range?.key) return;
    _range = range;
    _selectRecords();
    _publish();
  }

  void loadMore() {
    if (_inactive || !state.hasMore) return;
    _visibleLimits[state.selectionKey] =
        (_visibleLimits[state.selectionKey] ?? pageSize) + pageSize;
    _publish();
  }

  void _selectRecords() {
    _selectedRecords = query.select(
      _allRecords,
      filter: _filter,
      range: _range,
    );
  }

  void _publish() {
    if (_inactive) return;
    final selectionKey = '${_filter.name}:${_range?.key ?? 'all-dates'}';
    final limit = _visibleLimits[selectionKey] ?? pageSize;
    final rows = query.rows(_selectedRecords, limit: limit);
    emit(
      TimelineState(
        filter: _filter,
        range: _range,
        rows: rows,
        rowIndexes: Map.unmodifiable({
          for (var index = 0; index < rows.length; index++)
            rows[index].key: index,
        }),
        allRecords: _allRecords,
        totalCount: _selectedRecords.length,
        visibleCount: _selectedRecords.length.clamp(0, limit),
        loadingSources: Set.unmodifiable(_loading),
        failures: Map.unmodifiable(_failures),
      ),
    );
  }

  @override
  Future<void> close() async {
    if (isClosed) return;
    _closing = true;
    _watchRefresh.dispose();
    _pending.clear();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
