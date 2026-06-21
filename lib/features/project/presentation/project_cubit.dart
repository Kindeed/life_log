import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';

enum ProjectReadStatus { initial, loading, ready, failure }

final class ProjectState extends Equatable {
  final ProjectReadStatus status;
  final List<ProjectEntry> entries;
  final int totalProjectCount;
  final AppFailure? failure;

  const ProjectState._({
    required this.status,
    required this.entries,
    required this.totalProjectCount,
    this.failure,
  });

  factory ProjectState.initial() {
    return ProjectState.ready(
      entries: const [],
      status: ProjectReadStatus.initial,
    );
  }

  factory ProjectState.ready({
    required List<ProjectEntry> entries,
    ProjectReadStatus status = ProjectReadStatus.ready,
    AppFailure? failure,
  }) {
    final stableEntries = List<ProjectEntry>.unmodifiable(entries);
    return ProjectState._(
      status: status,
      entries: stableEntries,
      totalProjectCount: stableEntries.length,
      failure: failure,
    );
  }

  ProjectState copyWith({
    ProjectReadStatus? status,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ProjectState._(
      status: status ?? this.status,
      entries: entries,
      totalProjectCount: totalProjectCount,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  ProjectEntry? entryNamed(String name) {
    for (final entry in entries) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  @override
  List<Object?> get props => [status, entries, totalProjectCount, failure];
}

final class ProjectCubit extends Cubit<ProjectState> {
  final LoadProjectEntries _loadEntries;
  final WatchProjectEntries _watchEntries;
  StreamSubscription<void>? _entriesSubscription;

  ProjectCubit({
    required LoadProjectEntries loadEntries,
    required WatchProjectEntries watchEntries,
  }) : _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       super(ProjectState.initial());

  void start() {
    if (_entriesSubscription != null) return;

    unawaited(loadEntries());
    _entriesSubscription = _watchEntries().listen((_) {
      unawaited(loadEntries());
    });
  }

  Future<void> loadEntries() async {
    if (isClosed) return;
    emit(state.copyWith(status: ProjectReadStatus.loading, clearFailure: true));

    final result = await _loadEntries();
    if (isClosed) return;
    result.when(
      success: (entries) {
        emit(ProjectState.ready(entries: entries));
      },
      failure: (failure) {
        emit(
          state.copyWith(status: ProjectReadStatus.failure, failure: failure),
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
