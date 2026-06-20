import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry_stats.dart';

enum EvidenceStatus { initial, loading, ready, failure }

enum EvidenceSortMode { recent, amount, project }

final class EvidenceProjectSummary extends Equatable {
  final String projectName;
  final List<EvidenceEntry> items;

  EvidenceProjectSummary({
    required this.projectName,
    required List<EvidenceEntry> items,
  }) : items = List.unmodifiable(items);

  EvidenceEntry get latest => items.first;
  int get count => items.length;
  double get pendingAmount => items.totalPendingAmount;
  double get reimbursedAmount => items.totalReimbursedAmount;

  @override
  List<Object?> get props => [projectName, items];
}

final class EvidenceState extends Equatable {
  final EvidenceStatus status;
  final List<EvidenceEntry> entries;
  final List<EvidenceProjectSummary> projectSummaries;
  final List<EvidenceProjectSummary> filteredProjectSummaries;
  final String searchQuery;
  final EvidenceSortMode sortMode;
  final int totalEvidenceCount;
  final double totalPendingAmount;
  final AppFailure? failure;

  const EvidenceState._({
    required this.status,
    required this.entries,
    required this.projectSummaries,
    required this.filteredProjectSummaries,
    required this.searchQuery,
    required this.sortMode,
    required this.totalEvidenceCount,
    required this.totalPendingAmount,
    this.failure,
  });

  factory EvidenceState.initial() {
    return EvidenceState.ready(
      entries: const [],
      searchQuery: '',
      sortMode: EvidenceSortMode.recent,
      status: EvidenceStatus.initial,
    );
  }

  factory EvidenceState.ready({
    required List<EvidenceEntry> entries,
    required String searchQuery,
    required EvidenceSortMode sortMode,
    EvidenceStatus status = EvidenceStatus.ready,
    AppFailure? failure,
  }) {
    final stableEntries = List<EvidenceEntry>.unmodifiable(entries);
    final summaries = _projectSummaries(stableEntries, sortMode);
    final filtered = _filteredProjectSummaries(summaries, searchQuery);
    return EvidenceState._(
      status: status,
      entries: stableEntries,
      projectSummaries: List<EvidenceProjectSummary>.unmodifiable(summaries),
      filteredProjectSummaries: List<EvidenceProjectSummary>.unmodifiable(
        filtered,
      ),
      searchQuery: searchQuery,
      sortMode: sortMode,
      totalEvidenceCount: stableEntries.length,
      totalPendingAmount: stableEntries.totalPendingAmount,
      failure: failure,
    );
  }

  EvidenceState copyWith({
    EvidenceStatus? status,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return EvidenceState._(
      status: status ?? this.status,
      entries: entries,
      projectSummaries: projectSummaries,
      filteredProjectSummaries: filteredProjectSummaries,
      searchQuery: searchQuery,
      sortMode: sortMode,
      totalEvidenceCount: totalEvidenceCount,
      totalPendingAmount: totalPendingAmount,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  List<EvidenceEntry> entriesForProject(String projectName) {
    return entries.where((entry) => entry.projectName == projectName).toList()
      ..sort((a, b) => b.evidenceDate.compareTo(a.evidenceDate));
  }

  double pendingAmountForProject(String projectName) {
    return entriesForProject(projectName).totalPendingAmount;
  }

  static List<EvidenceProjectSummary> _projectSummaries(
    List<EvidenceEntry> entries,
    EvidenceSortMode sortMode,
  ) {
    final groups = <String, List<EvidenceEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.projectName, () => []).add(entry);
    }

    final summaries = groups.entries.map((entry) {
      final items = entry.value.toList()
        ..sort((a, b) => b.evidenceDate.compareTo(a.evidenceDate));
      return EvidenceProjectSummary(projectName: entry.key, items: items);
    }).toList();

    switch (sortMode) {
      case EvidenceSortMode.recent:
        summaries.sort(
          (a, b) => b.latest.evidenceDate.compareTo(a.latest.evidenceDate),
        );
        break;
      case EvidenceSortMode.amount:
        summaries.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));
        break;
      case EvidenceSortMode.project:
        summaries.sort((a, b) => a.projectName.compareTo(b.projectName));
        break;
    }
    return summaries;
  }

  static List<EvidenceProjectSummary> _filteredProjectSummaries(
    List<EvidenceProjectSummary> summaries,
    String query,
  ) {
    final lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) return summaries;
    return summaries
        .where(
          (summary) => summary.projectName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    projectSummaries,
    filteredProjectSummaries,
    searchQuery,
    sortMode,
    totalEvidenceCount,
    totalPendingAmount,
    failure,
  ];
}

final class EvidenceCubit extends Cubit<EvidenceState> {
  final LoadEvidenceEntries _loadEntries;
  final WatchEvidenceEntries _watchEntries;
  StreamSubscription<void>? _entriesSubscription;

  EvidenceCubit({
    required LoadEvidenceEntries loadEntries,
    required WatchEvidenceEntries watchEntries,
  }) : _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       super(EvidenceState.initial());

  void start() {
    if (_entriesSubscription != null) return;

    unawaited(loadEntries());
    _entriesSubscription = _watchEntries().listen((_) {
      unawaited(loadEntries());
    });
  }

  Future<void> loadEntries() async {
    if (isClosed) return;
    emit(state.copyWith(status: EvidenceStatus.loading, clearFailure: true));

    final result = await _loadEntries();
    if (isClosed) return;
    result.when(
      success: (entries) {
        emit(
          EvidenceState.ready(
            entries: entries,
            searchQuery: state.searchQuery,
            sortMode: state.sortMode,
          ),
        );
      },
      failure: (failure) {
        emit(state.copyWith(status: EvidenceStatus.failure, failure: failure));
      },
    );
  }

  void updateSearch(String value) {
    emit(
      EvidenceState.ready(
        entries: state.entries,
        searchQuery: value,
        sortMode: state.sortMode,
      ),
    );
  }

  void setSortMode(EvidenceSortMode sortMode) {
    emit(
      EvidenceState.ready(
        entries: state.entries,
        searchQuery: state.searchQuery,
        sortMode: sortMode,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }
}
