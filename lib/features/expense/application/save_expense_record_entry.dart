import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';

final class SaveExpenseRecordEntry {
  final ExpenseRecordRepositoryPort _repository;

  const SaveExpenseRecordEntry(this._repository);

  Future<AppResult<void>> call(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {
    try {
      await _repository.saveEntry(entry, markDirty: markDirty);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'expense-record/save-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
