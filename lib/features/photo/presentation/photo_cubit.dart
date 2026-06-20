import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';

enum PhotoStatus { initial, loading, ready, failure }

enum PhotoProjectSortMode { recent, count, name }

final class PhotoProjectSummary extends Equatable {
  final String name;
  final List<PhotoEntry> photos;
  final PhotoEntry? latestPhoto;
  final int deviceCount;
  final int untitledCount;

  PhotoProjectSummary({
    required this.name,
    required List<PhotoEntry> photos,
    required this.latestPhoto,
    required this.deviceCount,
    required this.untitledCount,
  }) : photos = List<PhotoEntry>.unmodifiable(photos);

  int get photoCount => photos.length;

  @override
  List<Object?> get props => [
    name,
    photos,
    latestPhoto,
    deviceCount,
    untitledCount,
  ];
}

final class PhotoState extends Equatable {
  final PhotoStatus status;
  final List<PhotoEntry> entries;
  final List<PhotoProjectSummary> projectSummaries;
  final List<PhotoProjectSummary> filteredProjectSummaries;
  final String searchQuery;
  final PhotoProjectSortMode sortMode;
  final int totalPhotoCount;
  final AppFailure? failure;

  const PhotoState._({
    required this.status,
    required this.entries,
    required this.projectSummaries,
    required this.filteredProjectSummaries,
    required this.searchQuery,
    required this.sortMode,
    required this.totalPhotoCount,
    this.failure,
  });

  factory PhotoState.initial() {
    return PhotoState.ready(
      entries: const [],
      searchQuery: '',
      sortMode: PhotoProjectSortMode.recent,
      status: PhotoStatus.initial,
    );
  }

  factory PhotoState.ready({
    required List<PhotoEntry> entries,
    required String searchQuery,
    required PhotoProjectSortMode sortMode,
    PhotoStatus status = PhotoStatus.ready,
    AppFailure? failure,
  }) {
    final stableEntries = List<PhotoEntry>.unmodifiable(entries);
    final summaries = _projectSummaries(stableEntries, sortMode);
    final filtered = _filteredProjectSummaries(summaries, searchQuery);
    return PhotoState._(
      status: status,
      entries: stableEntries,
      projectSummaries: List<PhotoProjectSummary>.unmodifiable(summaries),
      filteredProjectSummaries: List<PhotoProjectSummary>.unmodifiable(
        filtered,
      ),
      searchQuery: searchQuery,
      sortMode: sortMode,
      totalPhotoCount: stableEntries.length,
      failure: failure,
    );
  }

  PhotoState copyWith({
    PhotoStatus? status,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return PhotoState._(
      status: status ?? this.status,
      entries: entries,
      projectSummaries: projectSummaries,
      filteredProjectSummaries: filteredProjectSummaries,
      searchQuery: searchQuery,
      sortMode: sortMode,
      totalPhotoCount: totalPhotoCount,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  List<PhotoEntry> entriesForProject(String projectName) {
    return entries.where((entry) => entry.projectName == projectName).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  PhotoProjectSummary? projectSummaryNamed(String projectName) {
    for (final summary in projectSummaries) {
      if (summary.name == projectName) return summary;
    }
    return null;
  }

  static List<PhotoProjectSummary> _projectSummaries(
    List<PhotoEntry> entries,
    PhotoProjectSortMode sortMode,
  ) {
    final groups = <String, List<PhotoEntry>>{};
    for (final entry in entries) {
      final name = entry.projectName ?? 'Default';
      groups.putIfAbsent(name, () => []).add(entry);
    }

    final summaries = groups.entries.map((entry) {
      final photos = entry.value.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final deviceNames = photos
          .map((photo) => photo.deviceName)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .toSet();
      final untitledCount = photos
          .where((photo) => photo.description?.trim().isNotEmpty != true)
          .length;

      return PhotoProjectSummary(
        name: entry.key,
        photos: photos,
        latestPhoto: photos.isEmpty ? null : photos.first,
        deviceCount: deviceNames.length,
        untitledCount: untitledCount,
      );
    }).toList();

    switch (sortMode) {
      case PhotoProjectSortMode.recent:
        summaries.sort(
          (a, b) => (b.latestPhoto?.createdAt ?? DateTime(0)).compareTo(
            a.latestPhoto?.createdAt ?? DateTime(0),
          ),
        );
        break;
      case PhotoProjectSortMode.count:
        summaries.sort((a, b) {
          final countCompare = b.photoCount.compareTo(a.photoCount);
          if (countCompare != 0) return countCompare;
          return a.name.compareTo(b.name);
        });
        break;
      case PhotoProjectSortMode.name:
        summaries.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return summaries;
  }

  static List<PhotoProjectSummary> _filteredProjectSummaries(
    List<PhotoProjectSummary> summaries,
    String query,
  ) {
    final lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) return summaries;
    return summaries
        .where((summary) => summary.name.toLowerCase().contains(lowerQuery))
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
    totalPhotoCount,
    failure,
  ];
}

final class PhotoCubit extends Cubit<PhotoState> {
  final LoadPhotoEntries _loadEntries;
  final WatchPhotoEntries _watchEntries;
  StreamSubscription<void>? _entriesSubscription;

  PhotoCubit({
    required LoadPhotoEntries loadEntries,
    required WatchPhotoEntries watchEntries,
  }) : _loadEntries = loadEntries,
       _watchEntries = watchEntries,
       super(PhotoState.initial());

  void start() {
    if (_entriesSubscription != null) return;

    unawaited(loadEntries());
    _entriesSubscription = _watchEntries().listen((_) {
      unawaited(loadEntries());
    });
  }

  Future<void> loadEntries() async {
    if (isClosed) return;
    emit(state.copyWith(status: PhotoStatus.loading, clearFailure: true));

    final result = await _loadEntries();
    if (isClosed) return;
    result.when(
      success: (entries) {
        emit(
          PhotoState.ready(
            entries: entries,
            searchQuery: state.searchQuery,
            sortMode: state.sortMode,
          ),
        );
      },
      failure: (failure) {
        emit(state.copyWith(status: PhotoStatus.failure, failure: failure));
      },
    );
  }

  void updateSearch(String value) {
    emit(
      PhotoState.ready(
        entries: state.entries,
        searchQuery: value,
        sortMode: state.sortMode,
      ),
    );
  }

  void setSortMode(PhotoProjectSortMode sortMode) {
    emit(
      PhotoState.ready(
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
