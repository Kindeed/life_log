import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';

void main() {
  group('ExpenseRecordCubit', () {
    test('loads entries and derives month and project totals', () async {
      final repository = _ExpenseRecordCubitRepository(
        entries: [
          _entry(
            id: 1,
            amount: 10,
            expenseDate: DateTime(2026, 5, 2),
            projectName: 'A',
          ),
          _entry(
            id: 2,
            amount: 30,
            expenseDate: DateTime(2026, 5, 8),
            projectName: 'A',
          ),
          _entry(
            id: 3,
            amount: 90,
            expenseDate: DateTime(2026, 6, 1),
            projectName: 'B',
          ),
        ],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, ExpenseRecordStatus.ready);
      expect(cubit.state.currentMonthTotal, 40);
      expect(cubit.state.totalForProject('A'), 40);
      expect(cubit.state.entriesForProject('A').map((entry) => entry.id), [
        2,
        1,
      ]);
    });

    test('reloads entries when repository emits changes', () async {
      final repository = _ExpenseRecordCubitRepository(
        entries: [_entry(id: 1, amount: 10)],
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      cubit.start();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.entries.single.id, 1);

      repository.entries = [_entry(id: 2, amount: 20)];
      repository.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.entries.single.id, 2);
      expect(cubit.state.currentMonthTotal, 20);
    });

    test('emits failure state when loading entries fails', () async {
      final repository = _ExpenseRecordCubitRepository(
        entries: const [],
        loadError: StateError('expenses down'),
      );
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.loadEntries();

      expect(cubit.state.status, ExpenseRecordStatus.failure);
      expect(cubit.state.failure?.code, 'expense-record/load-entries');
      expect(cubit.state.failure?.message, contains('expenses down'));
    });
  });

  group('ExpenseRecord read UI ownership', () {
    test('routes Today expense quick actions through the feature cubit', () {
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();

      expect(todayView, contains('BlocProvider<ExpenseRecordCubit>'));
      expect(todayView, contains('openExpenseRecordEditorPage'));
      expect(todayView, contains('context.read<ExpenseRecordCubit>()'));
      expect(todayView, contains('loadEntries()'));
      expect(todayView, isNot(contains('ExpenseRecordController')));
      expect(todayView, isNot(contains('Get.find<ExpenseRecordController>')));
      expect(todayView, isNot(contains('currentMonthTotal')));
      expect(todayView, isNot(contains('totalForMonth(')));
    });

    test('routes project expense display through domain entries', () {
      final photoView = File(
        'lib/features/photo/presentation/photo_view.dart',
      ).readAsStringSync();
      final projectGallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();

      expect(photoView, contains('ExpenseRecordCubit'));
      expect(photoView, contains('ExpenseRecordEntry'));
      expect(photoView, isNot(contains('ExpenseRecordController')));
      expect(photoView, isNot(contains('expense_record_model.dart')));
      expect(photoView, isNot(contains('ExpenseRecord>')));

      expect(projectGallery, contains('ExpenseRecordCubit'));
      expect(projectGallery, contains('ExpenseRecordEntry'));
      expect(projectGallery, isNot(contains('ExpenseRecordController')));
      expect(projectGallery, isNot(contains('expense_record_model.dart')));
      expect(
        projectGallery,
        isNot(contains('openLegacyExpenseRecordEditorPage')),
      );
    });

    test('retires the legacy ExpenseRecordController runtime path', () {
      final controller = File(
        'lib/modules/expense/expense_record_controller.dart',
      );
      final tabsBinding = File(
        'lib/common/bindings/tabs_binding.dart',
      ).readAsStringSync();

      expect(controller.existsSync(), isFalse);
      expect(tabsBinding, isNot(contains('ExpenseRecordController')));
      expect(tabsBinding, isNot(contains('expense_record_controller.dart')));
    });
  });
}

ExpenseRecordCubit _cubit(_ExpenseRecordCubitRepository repository) {
  return ExpenseRecordCubit(
    loadEntries: LoadExpenseRecordEntries(repository),
    watchEntries: WatchExpenseRecordEntries(repository),
    initialNow: () => DateTime(2026, 5, 1, 9),
  );
}

ExpenseRecordEntry _entry({
  required int id,
  double amount = 10,
  DateTime? expenseDate,
  String? projectName,
}) {
  return ExpenseRecordEntry(
    id: id,
    expenseDate: expenseDate ?? DateTime(2026, 5, 10),
    amount: amount,
    projectName: projectName,
  );
}

final class _ExpenseRecordCubitRepository
    implements ExpenseRecordRepositoryPort {
  final _controller = StreamController<void>.broadcast();
  Object? loadError;
  List<ExpenseRecordEntry> entries;

  _ExpenseRecordCubitRepository({required this.entries, this.loadError});

  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return entries;
  }

  @override
  Future<ExpenseRecordEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => _controller.stream;

  void emitChange() {
    _controller.add(null);
  }
}
