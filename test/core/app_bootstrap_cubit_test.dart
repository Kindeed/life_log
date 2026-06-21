import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/application/app_bootstrap_cubit.dart';
import 'package:life_log/core/errors/app_failure.dart';

void main() {
  group('AppBootstrapCubit', () {
    test('starts in bootstrapping state', () {
      final cubit = AppBootstrapCubit();
      addTearDown(cubit.close);

      expect(cubit.state.status, AppBootstrapStatus.bootstrapping);
      expect(cubit.state.warningMessage, isNull);
      expect(cubit.state.failure, isNull);
    });

    test('emits ready, local-mode warning, and failed states', () async {
      final cubit = AppBootstrapCubit();
      addTearDown(cubit.close);
      final states = <AppBootstrapState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      cubit.markReady();
      cubit.showLocalModeWarning('云同步未配置，已进入本地模式');
      cubit.markFailed(
        const AppFailure(code: 'startup/db', message: '本地数据库启动失败'),
      );
      await pumpEventQueue();

      expect(states.map((state) => state.status), [
        AppBootstrapStatus.ready,
        AppBootstrapStatus.localModeWarning,
        AppBootstrapStatus.failed,
      ]);
      expect(states[1].warningMessage, '云同步未配置，已进入本地模式');
      expect(states[2].failure?.code, 'startup/db');
    });
  });
}
