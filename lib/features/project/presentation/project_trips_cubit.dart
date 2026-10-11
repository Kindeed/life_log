import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/state/coalesced_refresh.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

final class ProjectTripsState extends Equatable {
  final List<WorkLogEntry> entries;
  final bool loading;
  final AppFailure? failure;

  const ProjectTripsState({
    this.entries = const [],
    this.loading = false,
    this.failure,
  });

  @override
  List<Object?> get props => [entries, loading, failure];
}

final class ProjectTripsCubit extends Cubit<ProjectTripsState> {
  final LoadProjectWorkLogTrips? _loadTrips;
  final WatchWorkLogEntries? _watchEntries;
  final Stream<void> Function()? _watchScope;
  ProjectRecordScope _scope;
  StreamSubscription<void>? _subscription;
  StreamSubscription<void>? _scopeSubscription;
  bool _started = false;
  bool _closing = false;
  int _requestId = 0;
  late CoalescedRefresh _refresh = _createRefresh();

  CoalescedRefresh _createRefresh() => CoalescedRefresh(refresh: loadEntries);

  bool get _inactive => isClosed || _closing;

  ProjectTripsCubit({
    required ProjectRecordScope scope,
    LoadProjectWorkLogTrips? loadTrips,
    WatchWorkLogEntries? watchEntries,
    Stream<void> Function()? watchScope,
  }) : _scope = scope,
       _loadTrips = loadTrips,
       _watchEntries = watchEntries,
       _watchScope = watchScope,
       super(const ProjectTripsState());

  void start() {
    if (_started || _inactive) return;
    _started = true;
    _scopeSubscription = _watchScope?.call().listen((_) => _invalidateScope());
    unawaited(loadEntries());
    _subscription ??= _watchEntries?.call().listen((_) => _refresh.schedule());
  }

  void setProject(ProjectRecordScope scope) {
    if (_scope == scope || _inactive) return;
    _scope = scope;
    _invalidateScope();
  }

  void _invalidateScope() {
    if (_inactive) return;
    _requestId++;
    // A blocked read for the previous account/project must not hold the next
    // scope's table watcher behind the old coalescer's running Future.
    _refresh.dispose();
    _refresh = _createRefresh();
    // Do not display the previous project's children during a scope change.
    emit(const ProjectTripsState(loading: true));
    unawaited(loadEntries());
  }

  Future<void> loadEntries() async {
    if (_inactive) return;
    final requestId = ++_requestId;
    final loader = _loadTrips;
    if (loader == null) {
      emit(const ProjectTripsState());
      return;
    }
    emit(ProjectTripsState(entries: state.entries, loading: true));
    final result = await loader(
      _scope.name,
      projectId: _scope.id,
      projectSyncId: _scope.syncId,
    );
    if (_inactive || requestId != _requestId) return;
    result.when(
      success: (entries) => emit(ProjectTripsState(entries: entries)),
      failure: (failure) =>
          emit(ProjectTripsState(entries: state.entries, failure: failure)),
    );
  }

  @override
  Future<void> close() async {
    _closing = true;
    _requestId++;
    _refresh.dispose();
    await _subscription?.cancel();
    await _scopeSubscription?.cancel();
    return super.close();
  }
}
