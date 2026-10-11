import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/state/coalesced_refresh.dart';
import 'package:life_log/features/project/application/load_project_note_entries.dart';
import 'package:life_log/features/project/application/watch_project_note_entries.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';

final class ProjectNoteState extends Equatable {
  final List<ProjectNoteEntry> entries;
  final bool loading;
  final AppFailure? failure;

  const ProjectNoteState({
    this.entries = const [],
    this.loading = false,
    this.failure,
  });

  @override
  List<Object?> get props => [entries, loading, failure];
}

final class ProjectNoteCubit extends Cubit<ProjectNoteState> {
  final LoadProjectNoteEntries? _loadEntries;
  final WatchProjectNoteEntries? _watchEntries;
  ProjectRecordScope _scope;
  StreamSubscription<void>? _subscription;
  StreamSubscription<void>? _scopeSubscription;
  bool _started = false;
  int _requestId = 0;
  late var _refresh = CoalescedRefresh(
    refresh: () => loadEntries(background: true),
  );

  ProjectNoteCubit({
    required ProjectRecordScope scope,
    LoadProjectNoteEntries? loadEntries,
    WatchProjectNoteEntries? watchEntries,
  }) : _scope = scope,
       _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       super(const ProjectNoteState());

  ProjectRecordScope get scope => _scope;

  void start() {
    if (_started || isClosed) return;
    _started = true;
    _scopeSubscription = _watchEntries?.watchScope().listen((_) {
      if (isClosed) return;
      _requestId++;
      _resetRefresh();
      emit(const ProjectNoteState(loading: true));
      unawaited(loadEntries());
    });
    _subscription = _watchEntries?.call().listen(
      (_) => _refresh.schedule(),
      onError: (Object error, StackTrace stackTrace) {
        if (isClosed) return;
        emit(
          ProjectNoteState(
            entries: state.entries,
            failure: AppFailure(
              code: 'project/watch-notes',
              message: '项目记录更新失败，请重试',
              cause: error,
              stackTrace: stackTrace,
            ),
          ),
        );
      },
    );
    unawaited(loadEntries());
  }

  void setProject(ProjectRecordScope scope) {
    if (_scope == scope || isClosed) return;
    _scope = scope;
    _resetRefresh();
    emit(const ProjectNoteState(loading: true));
    unawaited(loadEntries());
  }

  void _resetRefresh() {
    _refresh.dispose();
    _refresh = CoalescedRefresh(refresh: () => loadEntries(background: true));
  }

  Future<void> loadEntries({bool background = false}) async {
    if (isClosed) return;
    final requestId = ++_requestId;
    final loader = _loadEntries;
    if (loader == null) {
      emit(const ProjectNoteState());
      return;
    }
    if (!background) {
      emit(ProjectNoteState(entries: state.entries, loading: true));
    }
    final result = await loader(_scope);
    if (isClosed || requestId != _requestId) return;
    result.when(
      success: (entries) => emit(
        ProjectNoteState(entries: List<ProjectNoteEntry>.unmodifiable(entries)),
      ),
      failure: (failure) => emit(
        ProjectNoteState(
          entries: failure.code == 'project/notes-context-changed'
              ? const []
              : state.entries,
          failure: failure,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    _requestId++;
    _refresh.dispose();
    await _subscription?.cancel();
    await _scopeSubscription?.cancel();
    return super.close();
  }
}
