import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/save_subscription_entry.dart';
import 'package:life_log/features/subscription/data/legacy_subscription_repository_adapter.dart';
import 'package:life_log/features/subscription/data/subscription_local_data_source.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/subscription/data/subscription_repository.dart';
import 'package:life_log/features/subscription/data/subscription_sync_gateway.dart';
import 'package:life_log/features/subscription/presentation/add_subscription_sheet.dart';
import 'package:life_log/features/subscription/presentation/subscription_edit_view.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/application/save_work_log_entry.dart';
import 'package:life_log/features/work_log/application/delete_work_log_entry.dart';
import 'package:life_log/features/work_log/presentation/add_log_sheet.dart';
import 'package:life_log/features/work_log/presentation/log_edit_view.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_cubit.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';

void main() {
  setUp(() => serviceLocator.registerSingleton(LogService()));
  tearDown(() async => serviceLocator.reset());

  test(
    'subscription acknowledges durable commit before pending cloud sync',
    () async {
      final local = _LocalSubscriptions()..writeGate = Completer<void>();
      final cloud = _CloudSync();
      addTearDown(cloud.finish);
      final repository = SubscriptionRepository(
        localDataSource: local,
        syncGateway: cloud,
      );
      final entry = _subscription();
      var finished = false;
      final save = repository
          .saveSubscription(entry, 0)
          .then((_) => finished = true);
      await _settle();
      expect(finished, isFalse);
      expect(cloud.calls, 0);
      local.writeGate!.complete();
      await _settle();
      expect(finished, isTrue);
      expect(cloud.pending.isCompleted, isFalse);
      expect(local.rows, [entry]);
      expect(cloud.calls, 1);
      expect(cloud.reasons, ['subscription-save']);
      cloud.pending.complete(false);
      await save;
      await _settle();
      expect(entry.isDirty, isTrue);
      expect(entry.remoteVersion, 4);
      expect(serviceLocator<LogService>().logs.last.message, contains('保留待同步'));
    },
  );

  test(
    'failed background sync leaves the committed subscription dirty',
    () async {
      final local = _LocalSubscriptions();
      final cloud = _CloudSync();
      final entry = _subscription();
      await SubscriptionRepository(
        localDataSource: local,
        syncGateway: cloud,
      ).saveSubscription(entry, 0);
      cloud.pending.completeError(StateError('network failure'));
      await _settle();
      expect(local.rows, [entry]);
      expect(entry.isDirty, isTrue);
      expect(entry.remoteId, 7);
      expect(
        serviceLocator<LogService>().logs.last.message,
        contains('云端同步失败'),
      );
    },
  );

  test('failed local commit never starts background sync', () async {
    final local = _LocalSubscriptions()..failWrite = true;
    final cloud = _CloudSync();
    addTearDown(cloud.finish);
    await expectLater(
      SubscriptionRepository(
        localDataSource: local,
        syncGateway: cloud,
      ).saveSubscription(_subscription(), 0),
      throwsStateError,
    );
    expect(local.rows, isEmpty);
    expect(cloud.calls, 0);
  });

  testWidgets('work success exits immediately while refresh remains pending', (
    tester,
  ) async {
    final repository = _WorkRepository()..saveGate = Completer<void>();
    configureWorkLogFeatureDependencies(repository: repository);
    final refresh = Completer<void>();
    var refreshCalls = 0;
    await _open(
      tester,
      LogEditView(
        selectedDate: DateTime(2026, 10, 6),
        onSavedOrDeleted: () {
          refreshCalls++;
          return refresh.future;
        },
      ),
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('正在保存…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LogEditView),
        matching: find.byWidgetPredicate(
          (widget) => widget is AbsorbPointer && widget.absorbing,
        ),
      ),
      findsWidgets,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNull,
    );
    repository.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LogEditView), findsNothing);
    expect(find.text('工时已保存'), findsOneWidget);
    expect(refresh.isCompleted, isFalse);
    expect(refreshCalls, 1);
    expect(repository.saves, 1);
    refresh.completeError(StateError('refresh failure'));
    await tester.pumpAndSettle();
    expect(find.text('工时已保存，页面刷新失败，请重试'), findsOneWidget);
    expect(find.textContaining('保存失败'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('work failure is visible within modal and permits retry', (
    tester,
  ) async {
    final repository = _WorkRepository()..saveGate = Completer<void>();
    configureWorkLogFeatureDependencies(repository: repository);
    await _open(
      tester,
      AddLogSheet(selectedDate: DateTime(2026, 10, 6)),
      sheet: true,
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    repository.saveGate!.completeError(StateError('disk failure'));
    await tester.pumpAndSettle();
    expect(find.byType(AddLogSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AddLogSheet),
        matching: find.textContaining('保存失败'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppFormFeedback), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    repository.saveGate = null;
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.byType(AddLogSheet), findsNothing);
    expect(find.text('工时已保存'), findsOneWidget);
    expect(repository.saves, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'subscription edit closes and reports success before cloud responds',
    (tester) async {
      final original = _subscription()..isDirty = false;
      final local = _LocalSubscriptions()..rows.add(original);
      final cloud = _CloudSync();
      addTearDown(cloud.finish);
      final repository = SubscriptionRepository(
        localDataSource: local,
        syncGateway: cloud,
      );
      serviceLocator.registerSingleton(
        SaveSubscriptionEntry(LegacySubscriptionRepositoryAdapter(repository)),
      );
      await _open(
        tester,
        SubscriptionEditView(existingEntry: original.toSubscriptionEntry()),
      );
      await tester.enterText(find.byType(TextFormField).first, '修改后的订阅');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionEditView), findsNothing);
      expect(find.text('订阅已保存'), findsOneWidget);
      expect(cloud.pending.isCompleted, isFalse);
      expect(cloud.calls, 1);
      expect(local.rows.single.name, '修改后的订阅');
      expect(local.rows.single.isDirty, isTrue);
      expect(local.rows.single.remoteVersion, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('subscription local failure stays visible inside modal', (
    tester,
  ) async {
    final local = _LocalSubscriptions()..failWrite = true;
    final cloud = _CloudSync();
    addTearDown(cloud.finish);
    serviceLocator.registerSingleton(
      SaveSubscriptionEntry(
        LegacySubscriptionRepositoryAdapter(
          SubscriptionRepository(localDataSource: local, syncGateway: cloud),
        ),
      ),
    );
    await _open(tester, const AddSubscriptionSheet(), sheet: true);
    await tester.enterText(find.byType(TextFormField).first, '订阅');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.text('保存订阅'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AddSubscriptionSheet),
        matching: find.textContaining('保存失败'),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(cloud.calls, 0);
    expect(tester.takeException(), isNull);
  });

  test(
    'pending work save rejects edits, duplicates and delete overlap',
    () async {
      final repository = _WorkRepository()..saveGate = Completer<void>();
      final cubit = _editor(repository);
      addTearDown(cubit.close);
      cubit.changeNote('original draft');
      final save = cubit.submit();
      cubit.changeNote('changed while saving');
      await cubit.submit();
      await cubit.delete();
      expect(cubit.state.status, WorkLogEditorStatus.submitting);
      expect(cubit.state.note, 'original draft');
      expect(repository.saves, 1);
      expect(repository.deletes, 0);
      repository.saveGate!.complete();
      await save;
      await cubit.submit();
      expect(repository.saves, 1);
    },
  );

  test('removed work editor ignores delayed save completion', () async {
    final repository = _WorkRepository()..saveGate = Completer<void>();
    final cubit = _editor(repository);
    final save = cubit.submit();
    await cubit.close();
    repository.saveGate!.complete();
    await save;
    expect(cubit.isClosed, isTrue);
  });

  test(
    'pending work deletion rejects save and ignores completion after close',
    () async {
      final repository = _WorkRepository()..deleteGate = Completer<void>();
      final cubit = _editor(repository);
      final deletion = cubit.delete();
      cubit.changeNote('ignore edit');
      await cubit.submit();
      await cubit.delete();
      expect(repository.saves, 0);
      expect(repository.deletes, 1);
      expect(cubit.state.status, WorkLogEditorStatus.deleting);
      await cubit.close();
      repository.deleteGate!.complete();
      await deletion;
      expect(cubit.isClosed, isTrue);
    },
  );
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

WorkLogEditorCubit _editor(_WorkRepository repository) => WorkLogEditorCubit(
  saveEntry: SaveWorkLogEntry(repository),
  deleteEntry: DeleteWorkLogEntry(repository),
  selectedDate: DateTime(2026, 10, 6),
  existingEntry: WorkLogEntry(
    id: 1,
    date: DateTime(2026, 10, 6),
    type: WorkLogEntryType.work,
  ),
);

Future<void> _open(
  WidgetTester tester,
  Widget editor, {
  bool sheet = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  if (sheet) {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      builder: (_) => editor,
                    );
                  } else {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => editor));
                  }
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Subscription _subscription() => Subscription()
  ..id = 1
  ..name = '订阅'
  ..price = 10
  ..nextPaymentDate = DateTime(2026, 10, 6)
  ..remoteId = 7
  ..remoteVersion = 4
  ..syncId = 'stable-id'
  ..isDirty = true;

class _CloudSync implements SubscriptionSyncGateway {
  final pending = Completer<bool>();
  int calls = 0;
  final reasons = <String>[];
  @override
  bool get isAvailable => true;
  @override
  Future<bool> requestSync(
    Subscription subscription, {
    required String reason,
  }) {
    calls++;
    reasons.add(reason);
    return pending.future;
  }

  void finish() {
    if (!pending.isCompleted) pending.complete(true);
  }
}

class _LocalSubscriptions implements SubscriptionLocalDataSource {
  final rows = <Subscription>[];
  Completer<void>? writeGate;
  bool failWrite = false;
  @override
  Future<int> addSubscription(Subscription subscription) async {
    if (writeGate != null) await writeGate!.future;
    if (failWrite) throw StateError('disk failure');
    rows.removeWhere((item) => item.id == subscription.id);
    rows.add(subscription);
    return subscription.id;
  }

  @override
  Future<List<Subscription>> getAllSubscriptions() async => rows.toList();
  @override
  Stream<void> watchSubscriptions() => const Stream.empty();
  @override
  Future<Subscription?> markSubscriptionDeleted(int id) async => null;
  @override
  Future<void> purgeDeletedSubscription(int id) async {}
  @override
  Future<List<Subscription>> reorderSubscriptions(
    List<Subscription> subs,
  ) async => [];
}

class _WorkRepository implements WorkLogRepositoryPort {
  Completer<void>? saveGate;
  Completer<void>? deleteGate;
  int saves = 0;
  int deletes = 0;
  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {
    saves++;
    if (saveGate != null) await saveGate!.future;
  }

  @override
  Future<void> deleteEntry(int id) async {
    deletes++;
    if (deleteGate != null) await deleteGate!.future;
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() async => [];
  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async => [];
  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;
  @override
  Future<void> normalizeDuplicateDays() async {}
  @override
  Stream<void> watchEntries() => const Stream.empty();
}
