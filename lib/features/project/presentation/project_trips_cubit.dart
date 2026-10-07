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
  ProjectRecordScope _scope;
  StreamSubscription<void>? _subscription;
  int _requestId = 0;
  late final _refresh = CoalescedRefresh(refresh: loadEntries);

  ProjectTripsCubit({
    required ProjectRecordScope scope,
    LoadProjectWorkLogTrips? loadTrips,
    WatchWorkLogEntries? watchEntries,
  }) : _scope = scope,
       _loadTrips = loadTrips,
       _watchEntries = watchEntries,
       super(const ProjectTripsState());

  void start() {
    unawaited(loadEntries());
    _subscription ??= _watchEntries?.call().listen((_) => _refresh.schedule());
  }

  void setProject(ProjectRecordScope scope) {
    if (_scope == scope || isClosed) return;
    _scope = scope;
    // Do not display the previous project's children during a scope change.
    emit(const ProjectTripsState(loading: true));
    unawaited(loadEntries());
  }

  Future<void> loadEntries() async {
    if (isClosed) return;
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
    if (isClosed || requestId != _requestId) return;
    result.when(
      success: (entries) => emit(ProjectTripsState(entries: entries)),
      failure: (failure) =>
          emit(ProjectTripsState(entries: state.entries, failure: failure)),
    );
  }

  @override
  Future<void> close() async {
    _refresh.dispose();
    await _subscription?.cancel();
    return super.close();
  }
}
