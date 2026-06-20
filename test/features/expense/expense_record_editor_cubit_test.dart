import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/expense/application/delete_expense_record_entry.dart';
import 'package:life_log/features/expense/application/save_expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_editor_cubit.dart';

void main() {
  group('ExpenseRecordEditorCubit', () {
    test('initializes an edit draft from an existing entry', () {
      final cubit = _editor(
        existingEntry: _entry(
          id: 9,
          amount: 32.5,
          category: ExpenseRecordEntryCategory.travel,
          merchant: '高铁',
          projectName: '上海项目',
          note: '已报销',
        ),
        existingAlreadyDirty: true,
      );
      addTearDown(cubit.close);

      expect(cubit.state.amountText, '32.5');
      expect(cubit.state.category, ExpenseRecordEntryCategory.travel);
      expect(cubit.state.merchant, '高铁');
      expect(cubit.state.projectName, '上海项目');
      expect(cubit.state.note, '已报销');
      expect(cubit.state.existingAlreadyDirty, isTrue);
    });

    test('rejects invalid amount before saving', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository);
      addTearDown(cubit.close);

      cubit.changeAmountText('-1');

      await cubit.submit();

      expect(repository.savedEntries, isEmpty);
      expect(cubit.state.status, ExpenseRecordEditorStatus.failure);
      expect(cubit.state.failure?.code, 'expense-record/editor/invalid-amount');
    });

    test('saves a new draft as dirty expense entry', () async {
      final repository = _EditorRepository();
      final cubit = _editor(repository: repository, initialProjectName: '新项目');
      addTearDown(cubit.close);

      cubit
        ..changeAmountText('108.6')
        ..changeCategory(ExpenseRecordEntryCategory.office)
        ..changeMerchant('文具店')
        ..changeNote('办公用品');

      await cubit.submit();

      final call = repository.savedEntries.single;
      expect(call.markDirty, isTrue);
      expect(call.entry.id, 0);
      expect(call.entry.expenseDate, DateTime(2026, 5, 9));
      expect(call.entry.amount, 108.6);
      expect(call.entry.category, ExpenseRecordEntryCategory.office);
      expect(call.entry.merchant, '文具店');
      expect(call.entry.projectName, '新项目');
      expect(call.entry.note, '办公用品');
      expect(cubit.state.status, ExpenseRecordEditorStatus.saved);
    });

    test(
      'keeps an unchanged existing draft clean unless it was already dirty',
      () async {
        final repository = _EditorRepository();
        final existing = _entry(id: 12, amount: 42, note: '未改动');
        final cubit = _editor(repository: repository, existingEntry: existing);
        addTearDown(cubit.close);

        await cubit.submit();

        expect(repository.savedEntries.single.markDirty, isFalse);
        expect(repository.savedEntries.single.entry.id, 12);
      },
    );

    test('deletes the existing entry through the delete command', () async {
      final repository = _EditorRepository();
      final cubit = _editor(
        repository: repository,
        existingEntry: _entry(id: 13),
      );
      addTearDown(cubit.close);

      await cubit.delete();

      expect(repository.deletedIds, [13]);
      expect(cubit.state.status, ExpenseRecordEditorStatus.deleted);
    });
  });

  group('ExpenseRecord edit UI ownership', () {
    test('owns the edit surface from the feature folder', () {
      final featureView = File(
        'lib/features/expense/presentation/expense_record_edit_view.dart',
      );
      final legacyView = File(
        'lib/modules/expense/views/expense_record_edit_view.dart',
      );
      final todayView = File(
        'lib/features/today/presentation/today_view.dart',
      ).readAsStringSync();
      final projectGallery = File(
        'lib/features/photo/presentation/project_gallery_view.dart',
      ).readAsStringSync();

      expect(featureView.existsSync(), isTrue);
      expect(legacyView.existsSync(), isFalse);
      expect(todayView, contains('openExpenseRecordEditorPage'));
      expect(todayView, isNot(contains('ExpenseRecordEditView')));
      expect(
        todayView,
        isNot(contains('modules/expense/views/expense_record_edit_view.dart')),
      );
      expect(projectGallery, contains('openExpenseRecordEditorPage'));
      expect(
        projectGallery,
        isNot(contains('openLegacyExpenseRecordEditorPage')),
      );
      expect(projectGallery, isNot(contains('ExpenseRecordEditView')));
    });

    test(
      'routes edit writes through feature commands with local UI feedback',
      () {
        final source = File(
          'lib/features/expense/presentation/expense_record_edit_view.dart',
        ).readAsStringSync();
        final launcher = File(
          'lib/features/expense/presentation/expense_record_editor_launcher.dart',
        ).readAsStringSync();

        expect(source, contains('ExpenseRecordEditorCubit'));
        expect(source, contains('BlocListener<ExpenseRecordEditorCubit'));
        expect(source, contains('SaveExpenseRecordEntry'));
        expect(source, contains('DeleteExpenseRecordEntry'));
        expect(source, contains('ScaffoldMessenger'));
        expect(source, contains('Navigator.of(context)'));
        expect(source, isNot(contains("package:get/get.dart")));
        expect(source, isNot(contains('ExpenseRecordController')));
        expect(source, isNot(contains('saveRecord(')));
        expect(source, isNot(contains('deleteRecord(')));
        expect(source, isNot(contains('remoteId')));
        expect(source, isNot(contains('syncId')));
        expect(source, isNot(contains('remoteVersion')));
        expect(source, isNot(contains('remoteUpdatedAt')));
        expect(source, isNot(contains('syncedAt')));
        expect(source, isNot(contains('deletedAt')));
        expect(source, isNot(contains('pendingDelete')));
        expect(launcher, contains('LoadExpenseRecordEditDraft'));
        expect(launcher, contains('Navigator.of(context).push'));
        expect(launcher, isNot(contains('openLegacyExpenseRecordEditorPage')));
        expect(launcher, isNot(contains('toExpenseRecordEntry')));
        expect(launcher, isNot(contains('expense_record_model.dart')));
        expect(
          launcher,
          isNot(contains('legacy_expense_record_repository_adapter.dart')),
        );
        expect(launcher, isNot(contains('Get.to')));
      },
    );
  });
}

ExpenseRecordEditorCubit _editor({
  _EditorRepository? repository,
  ExpenseRecordEntry? existingEntry,
  bool existingAlreadyDirty = false,
  String? initialProjectName,
}) {
  final activeRepository = repository ?? _EditorRepository();
  return ExpenseRecordEditorCubit(
    saveEntry: SaveExpenseRecordEntry(activeRepository),
    deleteEntry: DeleteExpenseRecordEntry(activeRepository),
    selectedDate: DateTime(2026, 5, 9, 18),
    existingEntry: existingEntry,
    existingAlreadyDirty: existingAlreadyDirty,
    initialProjectName: initialProjectName,
  );
}

ExpenseRecordEntry _entry({
  required int id,
  double amount = 12,
  ExpenseRecordEntryCategory category = ExpenseRecordEntryCategory.meal,
  String? merchant,
  String? projectName,
  String? note,
}) {
  return ExpenseRecordEntry(
    id: id,
    expenseDate: DateTime(2026, 5, 9),
    amount: amount,
    category: category,
    merchant: merchant,
    projectName: projectName,
    note: note,
  );
}

final class _SavedEditorEntry {
  final ExpenseRecordEntry entry;
  final bool markDirty;

  const _SavedEditorEntry({required this.entry, required this.markDirty});
}

final class _EditorRepository implements ExpenseRecordRepositoryPort {
  final savedEntries = <_SavedEditorEntry>[];
  final deletedIds = <int>[];

  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async => const [];

  @override
  Future<ExpenseRecordEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    ExpenseRecordEntry entry, {
    required bool markDirty,
  }) async {
    savedEntries.add(_SavedEditorEntry(entry: entry, markDirty: markDirty));
  }

  @override
  Future<void> deleteEntry(int id) async {
    deletedIds.add(id);
  }

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
