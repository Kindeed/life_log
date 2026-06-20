import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/expense/application/load_expense_record_edit_draft.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';
import 'package:life_log/features/expense/data/legacy_expense_record_repository_adapter.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';

GetIt configureExpenseFeatureDependencies({
  GetIt? locator,
  ExpenseRecordRepositoryPort? repository,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<ExpenseRecordRepository>()) {
    activeLocator.registerLazySingleton<ExpenseRecordRepository>(
      ExpenseRecordRepository.new,
    );
  }

  if (!activeLocator.isRegistered<ExpenseRecordRepositoryPort>()) {
    activeLocator.registerLazySingleton<ExpenseRecordRepositoryPort>(
      () =>
          repository ??
          LegacyExpenseRecordRepositoryAdapter(
            activeLocator<ExpenseRecordRepository>(),
          ),
    );
  }

  if (!activeLocator.isRegistered<WatchExpenseRecordEntries>()) {
    activeLocator.registerLazySingleton<WatchExpenseRecordEntries>(
      () => WatchExpenseRecordEntries(
        activeLocator<ExpenseRecordRepositoryPort>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<LoadExpenseRecordEntries>()) {
    activeLocator.registerLazySingleton<LoadExpenseRecordEntries>(
      () => LoadExpenseRecordEntries(
        activeLocator<ExpenseRecordRepositoryPort>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<LoadExpenseRecordEditDraft>()) {
    activeLocator.registerLazySingleton<LoadExpenseRecordEditDraft>(
      () => LoadExpenseRecordEditDraft(
        activeLocator<ExpenseRecordRepositoryPort>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<SaveExpenseRecordEntry>()) {
    activeLocator.registerLazySingleton<SaveExpenseRecordEntry>(
      () =>
          SaveExpenseRecordEntry(activeLocator<ExpenseRecordRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<DeleteExpenseRecordEntry>()) {
    activeLocator.registerLazySingleton<DeleteExpenseRecordEntry>(
      () => DeleteExpenseRecordEntry(
        activeLocator<ExpenseRecordRepositoryPort>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<ExpenseRecordCubit>()) {
    activeLocator.registerFactory<ExpenseRecordCubit>(
      () => ExpenseRecordCubit(
        loadEntries: activeLocator<LoadExpenseRecordEntries>(),
        watchEntries: activeLocator<WatchExpenseRecordEntries>(),
      ),
    );
  }

  return activeLocator;
}
