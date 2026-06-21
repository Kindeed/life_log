import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';

final class WatchExpenseRecordEntries {
  final ExpenseRecordRepositoryPort _repository;

  const WatchExpenseRecordEntries(this._repository);

  Stream<void> call() => _repository.watchEntries();
}
