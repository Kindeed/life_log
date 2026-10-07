import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/money_input.dart';

void main() {
  for (final value in [
    'NaN',
    'Infinity',
    '-1',
    '1e3',
    '1.234',
    '1,234.00',
    '',
    '.',
    '1..2',
  ]) {
    test(
      'rejects ambiguous/non-finite amount "$value"',
      () => expect(moneyInputError(value, 'CNY'), isNotNull),
    );
  }
  test('accepts zero and exact decimal inputs without silently rounding', () {
    for (final value in ['0', '0.00', ' 12.34 ', '125']) {
      expect(moneyInputError(value, 'USD'), isNull);
    }
  });
  test('JPY accepts whole units only', () {
    expect(moneyInputError('123', 'JPY'), isNull);
    expect(moneyInputError('123.4', 'JPY'), isNotNull);
  });
  test('optional receipt amount remains absent', () {
    expect(moneyInputError('', 'CNY', optional: true), isNull);
    expect(moneyInputError('NaN', 'CNY', optional: true), isNotNull);
  });
}
