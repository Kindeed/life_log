import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/evidence/application/delete_evidence_entry.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';

final class DeleteProjectEntry {
  final ProjectRepositoryPort _repository;
  final LoadPhotoEntries _loadPhotoEntries;
  final DeletePhotoEntries _deletePhotoEntries;
  final LoadEvidenceEntries _loadEvidenceEntries;
  final DeleteEvidenceEntry _deleteEvidenceEntry;
  final LoadExpenseRecordEntries _loadExpenseRecordEntries;
  final DeleteExpenseRecordEntry _deleteExpenseRecordEntry;
  final LoadProjectWorkLogTrips _loadProjectWorkLogTrips;
  final SaveWorkLogEntry _saveWorkLogEntry;

  const DeleteProjectEntry({
    required ProjectRepositoryPort repository,
    required LoadPhotoEntries loadPhotoEntries,
    required DeletePhotoEntries deletePhotoEntries,
    required LoadEvidenceEntries loadEvidenceEntries,
    required DeleteEvidenceEntry deleteEvidenceEntry,
    required LoadExpenseRecordEntries loadExpenseRecordEntries,
    required DeleteExpenseRecordEntry deleteExpenseRecordEntry,
    required LoadProjectWorkLogTrips loadProjectWorkLogTrips,
    required SaveWorkLogEntry saveWorkLogEntry,
  }) : _repository = repository,
       _loadPhotoEntries = loadPhotoEntries,
       _deletePhotoEntries = deletePhotoEntries,
       _loadEvidenceEntries = loadEvidenceEntries,
       _deleteEvidenceEntry = deleteEvidenceEntry,
       _loadExpenseRecordEntries = loadExpenseRecordEntries,
       _deleteExpenseRecordEntry = deleteExpenseRecordEntry,
       _loadProjectWorkLogTrips = loadProjectWorkLogTrips,
       _saveWorkLogEntry = saveWorkLogEntry;

  Future<AppResult<void>> call(ProjectEntry entry) async {
    try {
      final photoResult = await _loadPhotoEntries();
      final photoFailure = photoResult.failureOrNull;
      if (photoFailure != null) {
        throw photoFailure;
      }
      final photos = photoResult.valueOrNull!
          .where((photo) => photo.projectName == entry.name)
          .toList();
      final evidenceResult = await _loadEvidenceEntries();
      final evidenceFailure = evidenceResult.failureOrNull;
      if (evidenceFailure != null) {
        throw evidenceFailure;
      }
      final evidence = evidenceResult.valueOrNull!
          .where((item) => item.projectName == entry.name)
          .toList();
      final expenseResult = await _loadExpenseRecordEntries();
      final expenseFailure = expenseResult.failureOrNull;
      if (expenseFailure != null) {
        throw expenseFailure;
      }
      final records = expenseResult.valueOrNull!
          .where((record) => record.projectName == entry.name)
          .toList();
      final tripResult = await _loadProjectWorkLogTrips(entry.name);
      final tripFailure = tripResult.failureOrNull;
      if (tripFailure != null) {
        throw tripFailure;
      }
      final trips = tripResult.valueOrNull!;

      if (photos.isNotEmpty) {
        final result = await _deletePhotoEntries(photos);
        final failure = result.failureOrNull;
        if (failure != null) {
          throw failure;
        }
      }
      for (final item in evidence) {
        final result = await _deleteEvidenceEntry(item.id);
        final failure = result.failureOrNull;
        if (failure != null) {
          throw failure;
        }
      }
      for (final record in records) {
        final result = await _deleteExpenseRecordEntry(record.id);
        final failure = result.failureOrNull;
        if (failure != null) {
          throw failure;
        }
      }
      for (final trip in trips) {
        final result = await _saveWorkLogEntry(
          trip.copyWith(clearProject: true),
          markDirty: true,
        );
        final failure = result.failureOrNull;
        if (failure != null) {
          throw failure;
        }
      }

      await _repository.deleteEntry(entry);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'project/delete-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
