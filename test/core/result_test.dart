import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';

void main() {
  group('AppResult', () {
    test('success exposes value and runs success branch', () {
      const result = AppResult.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(
        result.when(
          success: (value) => 'value:$value',
          failure: (failure) => failure.message,
        ),
        'value:42',
      );
    });

    test('failure exposes failure and uses fallback value', () {
      const failure = AppFailure(
        code: 'sync/offline',
        message: '网络不可用，已保留本地数据',
      );

      const result = AppResult<int>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(result.valueOr(7), 7);
      expect(
        result.when(
          success: (value) => 'value:$value',
          failure: (failure) => failure.code,
        ),
        'sync/offline',
      );
    });
  });
}
