/// Input validation only; persisted records keep their existing double format.
int moneyDecimalPlaces(String currency) =>
    currency.trim().toUpperCase() == 'JPY' ? 0 : 2;

String? moneyInputError(String text, String currency, {bool optional = false}) {
  final value = text.trim();
  if (value.isEmpty && optional) return null;
  final places = moneyDecimalPlaces(currency);
  final pattern = places == 0 ? r'^\d+$' : r'^\d+(?:\.\d{1,2})?$';
  final amount = double.tryParse(value);
  if (!RegExp(pattern).hasMatch(value) ||
      amount == null ||
      !amount.isFinite ||
      amount < 0) {
    return places == 0 ? '请输入有效整数金额（日元不含小数）' : '请输入有效金额，最多两位小数';
  }
  return null;
}
