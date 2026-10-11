import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/utils/formatters.dart';

void main() {
  test('formatMoney keeps cents', () {
    expect(formatMoney(9.99), '¥9.99');
    expect(formatMoney(10), '¥10.00');
    expect(formatMoney(0), '¥0.00');
    expect(formatMoney(-3.5), '¥-3.50');
  });

  test('formats unambiguous original currencies with their minor units', () {
    expect(formatMoney(12.5, currency: ' usd '), 'USD 12.50');
    expect(formatMoney(12, currency: 'JPY'), 'JPY 12');
    expect(formatMoney(12.5, currency: 'KWD'), 'KWD 12.500');
    expect(formatMoney(12.5, currency: 'hkd'), 'HKD 12.50');
    expect(formatMoney(12.5, currency: ''), '¥12.50');
    expect(formatMoney(12.5, currency: 'XTS'), 'XTS 12.50');
  });

  test('does not round historical fractions or tiny nonzero amounts away', () {
    expect(formatMoney(12.5, currency: 'JPY'), 'JPY 12.5');
    expect(formatMoney(12.345), '¥12.345');
    expect(formatMoney(0.0000001), '¥0.0000001');
    expect(formatMoney(-0.0000001, currency: 'JPY'), 'JPY -0.0000001');
    expect(formatMoney(1e21, currency: 'USD'), 'USD 1000000000000000000000.00');
    expect(formatMoney(-0.0), '¥0.00');
    expect(formatMoney(double.nan), '¥—');
  });

  test('currency totals retain decimals without arithmetic display tails', () {
    expect(sumMoneyValues([0.1, 0.2]), 0.3);
    expect(sumMoneyValues([1.001, 0.0001, -1]), 0.0011);
    expect(sumMoneyValues([1e-7, -1e-7]), 0);
    expect(formatMoneyTotals({'USD': 2.5, 'CNY': 1}), '¥1.00 · USD 2.50');
  });

  test('CNY estimates round for display without hiding tiny nonzero costs', () {
    expect(formatCnyEstimate(1.234567), '¥1.23');
    expect(formatCnyEstimate(0.1 + 0.2), '¥0.30');
    expect(formatCnyEstimate(0.004), '<¥0.01');
    expect(formatCnyEstimate(-0.004), '>−¥0.01');
    expect(formatCnyEstimate(0), '¥0.00');
    expect(formatCnyEstimate(double.infinity), '¥—');
    expect(formatMoney(0.004), '¥0.004');
  });
}
