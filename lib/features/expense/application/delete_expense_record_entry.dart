import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';

final class DeleteExpenseRecordEntry {
  final ExpenseRecordRepositoryPort _repository;

  const DeleteExpenseRecordEntry(this._repository);

  Future<AppResult<void>> call(int id) async {
    try {
      await _repository.deleteEntry(id);
      return const AppResult.success(null);
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'expense-record/delete-entry',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
