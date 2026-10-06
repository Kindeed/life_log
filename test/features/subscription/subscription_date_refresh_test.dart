import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/subscription/presentation/subscription_date_refresh.dart';

void main() {
  testWidgets('checks every minute and stops after disposal', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var refreshCount = 0;
    await tester.pumpWidget(
      SubscriptionDateRefresh(
        onRefresh: () => refreshCount++,
        child: const SizedBox(),
      ),
    );
    await tester.pump(const Duration(seconds: 59));
    expect(refreshCount, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCount, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(refreshCount, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(refreshCount, 2);
  });

  testWidgets('checks immediately on resume and pauses background checks', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var refreshCount = 0;
    await tester.pumpWidget(
      SubscriptionDateRefresh(
        onRefresh: () => refreshCount++,
        child: const SizedBox(),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 2));
    expect(refreshCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(refreshCount, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(refreshCount, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('uses the latest callback after the widget updates', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var originalCount = 0;
    var replacementCount = 0;
    await tester.pumpWidget(
      SubscriptionDateRefresh(
        onRefresh: () => originalCount++,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(
      SubscriptionDateRefresh(
        onRefresh: () => replacementCount++,
        child: const SizedBox(),
      ),
    );
    await tester.pump(const Duration(minutes: 1));
    expect(originalCount, 0);
    expect(replacementCount, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
