import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';

final class LoadExpenseRecordEditDraft {
  final ExpenseRecordRepositoryPort _repository;

  const LoadExpenseRecordEditDraft(this._repository);

  Future<AppResult<ExpenseRecordEditDraft?>> call(int id) async {
    try {
      return AppResult.success(await _repository.getEditDraft(id));
    } catch (error, stackTrace) {
      return AppResult.failure(
        AppFailure(
          code: 'expense-record/load-edit-draft',
          message: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
