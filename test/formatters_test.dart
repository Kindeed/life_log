import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/formatters.dart';

void main() {
  test('formatMoney keeps cents', () {
    expect(formatMoney(9.99), '¥9.99');
    expect(formatMoney(10), '¥10.00');
    expect(formatMoney(0), '¥0.00');
    expect(formatMoney(-3.5), '¥-3.50');
  });
}
