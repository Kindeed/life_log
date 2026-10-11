import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/common/theme/app_theme.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry_stats.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry_stats.dart';
import 'package:life_log/features/statistics/presentation/statistics_controller.dart';
import 'package:life_log/features/statistics/presentation/statistics_view.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';
import 'package:life_log/features/subscription/domain/services/subscription_exchange_rate_reader.dart';

final _month = DateTime(2026, 10);

List<ExpenseRecordEntry> _expenses() => [
  ExpenseRecordEntry(id: 1, expenseDate: _month, amount: 10),
  ExpenseRecordEntry(
    id: 2,
    expenseDate: _month,
    amount: 12.345,
    currency: ' usd ',
  ),
  ExpenseRecordEntry(
    id: 3,
    expenseDate: _month,
    amount: 700.5,
    currency: 'JPY',
  ),
  ExpenseRecordEntry(
    id: 4,
    expenseDate: DateTime(2026, 9),
    amount: 999,
    currency: 'EUR',
  ),
];

List<EvidenceEntry> _evidence() => [
  EvidenceEntry(id: 1, projectName: 'Alpha', evidenceDate: _month, amount: 900),
  EvidenceEntry(
    id: 2,
    projectName: 'Alpha',
    evidenceDate: _month,
    amount: 0.001,
    currency: 'USD',
  ),
  EvidenceEntry(
    id: 3,
    projectName: 'Alpha',
    evidenceDate: _month,
    amount: 2.5,
    currency: 'USD',
    status: EvidenceEntryStatus.reimbursed,
  ),
  EvidenceEntry(
    id: 4,
    projectName: 'Alpha',
    evidenceDate: _month,
    currency: 'EUR',
  ),
];

StatisticsController _controller({
  SubscriptionExchangeRateReader? rates,
  bool tiny = false,
}) => StatisticsController(
  getAllWorkLogEntries: () async => [],
  getAllExpenseRecords: () async => tiny ? [] : _expenses(),
  getAllEvidence: () async => tiny ? [] : _evidence(),
  getAllSubscriptions: () async => [
    SubscriptionEntry(
      id: 1,
      name: '本地订阅',
      price: tiny ? 0.004 : 5,
      cycle: SubscriptionBillingCycle.monthly,
      nextPaymentDate: _month,
    ),
    if (!tiny)
      SubscriptionEntry(
        id: 2,
        name: '美元订阅',
        price: 2,
        currency: SubscriptionCurrency.usd,
        cycle: SubscriptionBillingCycle.monthly,
        nextPaymentDate: _month,
      ),
  ],
  exchangeRateReader: rates,
)..selectedMonth = _month;

void main() {
  setUp(() async {
    await serviceLocator.reset();
    serviceLocator.registerSingleton<LogService>(LogService());
  });
  tearDown(() async => serviceLocator.reset());

  test(
    'account change clears cached statistics and isolates blocked old reads',
    () async {
      final scope = StreamController<void>.broadcast(sync: true);
      final changes = StreamController<void>.broadcast(sync: true);
      final stale = Completer<List<ExpenseRecordEntry>>();
      var current = 100.0;
      var reads = 0;
      final controller = StatisticsController(
        getAllWorkLogEntries: () async => [],
        watchWorkLogEntries: () => const Stream.empty(),
        getAllSubscriptions: () async => [],
        watchSubscriptionEntries: () => const Stream.empty(),
        getAllEvidence: () async => [],
        watchEvidenceEntries: () => const Stream.empty(),
        getAllExpenseRecords: () {
          reads++;
          return reads == 2
              ? stale.future
              : Future.value([
                  ExpenseRecordEntry(
                    id: 1,
                    expenseDate: _month,
                    amount: current,
                  ),
                ]);
        },
        watchExpenseRecordEntries: () => changes.stream,
        watchScope: () => scope.stream,
      )..selectedMonth = _month;
      addTearDown(() async {
        if (!stale.isCompleted) stale.complete([]);
        controller.dispose();
        await scope.close();
        await changes.close();
      });
      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.selectedMonthTotalCost, 100);
      final old = controller.refreshStats();
      await Future<void>.delayed(Duration.zero);
      current = 5;
      scope.add(null);
      expect(controller.selectedMonthTotalCost, 0);
      await controller.refreshStats();
      expect(controller.selectedMonthTotalCost, 5);
      current = 7;
      changes.add(null);
      await controller.refreshStats();
      expect(stale.isCompleted, isFalse);
      expect(controller.selectedMonthTotalCost, 7);
      stale.complete([
        ExpenseRecordEntry(id: 2, expenseDate: _month, amount: 999),
      ]);
      await old;
      expect(controller.selectedMonthTotalCost, 7);
    },
  );

  test('domain subtotals group original currencies and scalar is CNY only', () {
    final amounts = _expenses().inMonth(_month);
    expect(amounts.totalAmountsByCurrency, {
      'CNY': 10,
      'USD': 12.345,
      'JPY': 700.5,
    });
    expect(amounts.totalAmount, 10);
    expect(_evidence().pendingAmountsByCurrency, {'CNY': 900, 'USD': 0.001});
    expect(_evidence().reimbursedAmountsByCurrency, {'USD': 2.5});
    expect(_evidence().totalPendingAmount, 900);
    expect(_evidence().totalReimbursedAmount, 0);
    expect(
      () => amounts.totalAmountsByCurrency['USD'] = 999,
      throwsUnsupportedError,
    );
  });

  test('statistics retain tiny estimates until display formatting', () async {
    final controller = StatisticsController(
      getAllWorkLogEntries: () async => [],
      getAllExpenseRecords: () async => [],
      getAllEvidence: () async => [],
      getAllSubscriptions: () async => [
        SubscriptionEntry(
          id: 1,
          name: '极小金额',
          price: 0.004,
          cycle: SubscriptionBillingCycle.monthly,
          nextPaymentDate: _month,
        ),
      ],
    )..selectedMonth = _month;
    addTearDown(controller.dispose);
    await controller.refreshStats();
    expect(controller.selectedMonthSubCost, 0.004);
    expect(controller.selectedMonthTotalCost, 0.004);
    expect(controller.yearSubCost, closeTo(0.048, 1e-9));
  });

  test(
    'statistics combine CNY expense and converted subscription only',
    () async {
      final controller = _controller(rates: _Rates({'CNY': 1, 'USD': 7}));
      addTearDown(controller.dispose);
      await controller.refreshStats();
      expect(controller.selectedMonthSubCost, 19);
      expect(controller.selectedMonthTotalCost, 29);
      expect(controller.selectedMonthExpensesByCurrency['USD'], 12.345);
      expect(
        controller.evidenceReimbursementsByCurrency['USD']!.pending,
        0.001,
      );
      expect(
        controller.evidenceReimbursementsByCurrency['USD']!.reimbursed,
        2.5,
      );
      expect(controller.evidenceReimbursementsByCurrency['USD']!.total, 2.501);
    },
  );

  test(
    'missing and failed rates retain CNY subtotal with visible exclusions',
    () async {
      for (final reader in [
        _Rates({'CNY': 1}),
        _Rates(null),
      ]) {
        final controller = _controller(rates: reader);
        await controller.refreshStats();
        expect(controller.selectedMonthTotalCost, 15);
        expect(
          controller.subscriptionEstimateNote,
          contains('缺少 USD 汇率，未计入估算'),
        );
        if (reader.rates == null) {
          expect(controller.subscriptionEstimateNote, contains('汇率更新失败'));
        }
        controller.dispose();
      }
    },
  );

  for (final dark in [false, true]) {
    testWidgets('actual statistics discloses tiny estimates dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller(tiny: true);
      addTearDown(controller.dispose);
      await controller.refreshStats();
      serviceLocator.registerSingleton<StatisticsController>(controller);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const StatisticsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('<¥0.01'), findsNWidgets(2));
      await tester.scrollUntilVisible(find.text('人民币支出估算'), 400);
      expect(tester.takeException(), isNull);
    });
    for (final scenario in [(390.0, 1.0), (320.0, 2.0)]) {
      testWidgets(
        'actual statistics preserves currency disclosures dark=$dark width=${scenario.$1} scale=${scenario.$2}',
        (tester) async {
          tester.view.physicalSize = Size(scenario.$1, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = _controller(rates: _Rates({'CNY': 1}));
          addTearDown(controller.dispose);
          await controller.refreshStats();
          serviceLocator.registerSingleton<StatisticsController>(controller);
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(scenario.$1, 900),
                    textScaler: TextScaler.linear(scenario.$2),
                  ),
                  child: const StatisticsView(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('人民币支出估算'), findsOneWidget);
          expect(find.text('USD 12.345'), findsOneWidget);
          expect(find.text('JPY 700.5'), findsOneWidget);
          expect(find.textContaining('缺少 USD 汇率'), findsOneWidget);
          expect(find.text('凭证报销 · USD'), findsOneWidget);
          expect(find.text('USD 0.001'), findsOneWidget);
          expect(find.text('USD 2.50'), findsOneWidget);
          expect(find.text('¥727.85'), findsNothing);
          await tester.scrollUntilVisible(find.text('凭证报销 · USD'), 400);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _Rates implements SubscriptionExchangeRateReader {
  final Map<String, double>? rates;
  _Rates(this.rates);
  @override
  Future<SubscriptionExchangeRates> load(
    DateTime now, {
    bool forceRefresh = false,
  }) async {
    if (rates == null) throw StateError('offline');
    return SubscriptionExchangeRates(
      rateDate: _month,
      fetchedAt: _month,
      cnyPerUnit: rates!,
    );
  }
}
