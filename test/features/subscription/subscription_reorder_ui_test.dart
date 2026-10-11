import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/reorder_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';
import 'package:life_log/features/subscription/presentation/subscription_view.dart';

void main() {
  for (final move in [
    (name: 'upward', from: 3, to: 1, order: [3, 1, 2, 4]),
    (name: 'downward one row', from: 1, to: 2, order: [2, 1, 3, 4]),
    (name: 'to the end', from: 1, to: 4, order: [2, 3, 4, 1]),
  ]) {
    testWidgets('manual subscription drag moves ${move.name}', (tester) async {
      final repository = _Repository();
      await _show(tester, repository);

      await _drag(tester, move.from, move.to);

      expect(repository.reorders, [move.order]);
      expect(repository.reads, 2);
      _expectOrder(tester, move.order);
      expect(find.textContaining('排序失败'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dropping back in the same slot leaves order unchanged', (
    tester,
  ) async {
    final repository = _Repository();
    await _show(tester, repository);

    await _drag(tester, 2, 2);

    expect(repository.reorders, isEmpty);
    expect(repository.reads, 1);
    _expectOrder(tester, [1, 2, 3, 4]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consecutive drags use the refreshed manual order', (
    tester,
  ) async {
    final repository = _Repository();
    await _show(tester, repository);

    await _drag(tester, 1, 4);
    _expectOrder(tester, [2, 3, 4, 1]);
    await _drag(tester, 1, 2);

    expect(repository.reorders, [
      [2, 3, 4, 1],
      [1, 2, 3, 4],
    ]);
    expect(repository.reads, 3);
    _expectOrder(tester, [1, 2, 3, 4]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed reorder keeps the displayed order and allows retry', (
    tester,
  ) async {
    final repository = _Repository()..reorderError = StateError('disk busy');
    await _show(tester, repository);

    await _drag(tester, 1, 4);

    expect(repository.reorders, [
      [2, 3, 4, 1],
    ]);
    expect(repository.reads, 1);
    expect(find.textContaining('排序失败：'), findsOneWidget);
    _expectOrder(tester, [1, 2, 3, 4]);

    repository.reorderError = null;
    await _drag(tester, 1, 4);

    expect(repository.reorders, [
      [2, 3, 4, 1],
      [2, 3, 4, 1],
    ]);
    expect(repository.reads, 2);
    _expectOrder(tester, [2, 3, 4, 1]);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _show(WidgetTester tester, _Repository repository) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1200);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await serviceLocator.reset();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  serviceLocator.registerFactory<SubscriptionCubit>(
    () => SubscriptionCubit(
      loadEntries: LoadSubscriptionEntries(repository),
      watchEntries: WatchSubscriptionEntries(repository),
      initialNow: () => DateTime(2026, 10, 11),
    ),
  );
  serviceLocator.registerSingleton(ReorderSubscriptionEntries(repository));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) =>
          MaterialApp(theme: AppTheme.light, home: const SubscriptionView()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _drag(WidgetTester tester, int fromId, int toId) async {
  final from = tester.getCenter(find.byKey(ValueKey(fromId)));
  final target = tester.getCenter(find.byKey(ValueKey(toId)));
  final targetHeight = tester.getSize(find.byKey(ValueKey(toId))).height;
  final delta = target.dy - from.dy;
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 600));
  final distance = delta == 0 ? 0.0 : delta + delta.sign * targetHeight * .1;
  final steps = (distance.abs() / 20).ceil().clamp(1, 100);
  for (var step = 0; step < steps; step++) {
    await gesture.moveBy(Offset(0, distance / steps));
    await tester.pump(const Duration(milliseconds: 30));
  }
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();
}

void _expectOrder(WidgetTester tester, List<int> ids) {
  final positions = [
    for (final id in ids) tester.getTopLeft(find.text('订阅 $id')).dy,
  ];
  expect(positions, orderedEquals([...positions]..sort()));
}

SubscriptionEntry _entry(int id, int sortIndex) => SubscriptionEntry(
  id: id,
  name: '订阅 $id',
  price: 10,
  cycle: SubscriptionBillingCycle.monthly,
  nextPaymentDate: DateTime(2026, 10, 20),
  sortIndex: sortIndex,
);

class _Repository implements SubscriptionRepositoryPort {
  List<SubscriptionEntry> entries = [
    for (var index = 0; index < 4; index++) _entry(index + 1, index),
  ];
  final reorders = <List<int>>[];
  Object? reorderError;
  int reads = 0;

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    reads++;
    return List.of(entries);
  }

  @override
  Future<void> reorderEntries(List<SubscriptionEntry> reordered) async {
    reorders.add(reordered.map((entry) => entry.id).toList());
    if (reorderError case final error?) throw error;
    entries = [
      for (var index = 0; index < reordered.length; index++)
        _entry(reordered[index].id, index),
    ];
  }

  @override
  Future<SubscriptionEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    SubscriptionEntry entry, {
    required bool markDirty,
  }) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
