import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';
import 'package:life_log/features/subscription/presentation/subscription_view.dart';

void main() {
  SubscriptionEntry entry({
    int id = 1,
    SubscriptionBillingCycle cycle = SubscriptionBillingCycle.monthly,
    SubscriptionStatus status = SubscriptionStatus.active,
    DateTime? endDate,
  }) => SubscriptionEntry(
    id: id,
    name: '订阅 $id',
    price: 10,
    cycle: cycle,
    nextPaymentDate: DateTime(2026, 9, 1),
    endDate: endDate,
    status: status,
  );

  testWidgets('old monthly date shows the next charge in row and reminder', (
    tester,
  ) async {
    final original = entry();
    final repository = _Repository([original]);
    await _show(tester, repository, () => DateTime(2026, 9, 30));

    expect(find.text('明天扣费'), findsOneWidget);
    expect(find.text('已过期'), findsNothing);
    await tester.tap(find.text('1 项扣费提醒'));
    await tester.pumpAndSettle();
    expect(find.textContaining('10月1日 ·'), findsOneWidget);
    expect(find.textContaining('9月1日 ·'), findsNothing);
    expect(repository.writes, 0);
    expect(repository.entries.single, same(original));
    expect(original.nextPaymentDate, DateTime(2026, 9, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mounted page updates at month rollover and foreground resume', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 30, 23, 59);
    final repository = _Repository([entry()]);
    await _show(tester, repository, () => now);
    expect(find.text('9 月 · 本月预计'), findsOneWidget);
    expect(find.text('明天扣费'), findsOneWidget);

    now = DateTime(2026, 10, 1);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('10 月 · 本月预计'), findsOneWidget);
    expect(find.text('今天扣费'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 10, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('11月1日扣费'), findsOneWidget);
    expect(find.text('1 项扣费提醒'), findsNothing);
    expect(find.text('已过期'), findsNothing);
    expect(repository.reads, 1);
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'inactive and ended rows show status without recurring reminders',
    (tester) async {
      final repository = _Repository([
        entry(id: 1, status: SubscriptionStatus.paused),
        entry(id: 2, endDate: DateTime(2026, 9, 15)),
        entry(id: 3, cycle: SubscriptionBillingCycle.oneTime),
      ]);
      await _show(tester, repository, () => DateTime(2026, 9, 30));
      expect(find.text('已暂停'), findsOneWidget);
      expect(find.text('已结束'), findsOneWidget);
      expect(find.text('已到期'), findsOneWidget);
      expect(find.textContaining('项扣费提醒'), findsNothing);
      expect(repository.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _show(
  WidgetTester tester,
  _Repository repository,
  DateTime Function() now,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
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
      initialNow: now,
    ),
  );
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) =>
          MaterialApp(theme: AppTheme.light, home: const SubscriptionView()),
    ),
  );
  await tester.pumpAndSettle();
}

class _Repository implements SubscriptionRepositoryPort {
  final List<SubscriptionEntry> entries;
  int reads = 0;
  int writes = 0;
  _Repository(this.entries);

  @override
  Future<List<SubscriptionEntry>> getAllEntries() async {
    reads++;
    return entries;
  }

  @override
  Future<SubscriptionEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> saveEntry(
    SubscriptionEntry entry, {
    required bool markDirty,
  }) async {
    writes++;
  }

  @override
  Future<void> deleteEntry(int id) async => writes++;

  @override
  Future<void> reorderEntries(List<SubscriptionEntry> entries) async =>
      writes++;

  @override
  Stream<void> watchEntries() => const Stream.empty();
}
