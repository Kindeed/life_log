import 'package:life_log/common/utils/money_input.dart';
import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';

/// One amount/currency pattern for expenses and supporting receipts.
class AppAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool optional;
  final bool enabled;

  const AppAmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.onCurrencyChanged,
    this.onChanged,
    this.errorText,
    this.optional = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codes = <String>{'CNY', 'USD', 'EUR', 'JPY', 'HKD', currency};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                optional ? '凭证金额（可选）' : '支出金额',
                style: theme.textTheme.titleSmall,
              ),
            ),
            DropdownButton<String>(
              value: currency,
              underline: const SizedBox.shrink(),
              items: codes
                  .map(
                    (code) => DropdownMenuItem(value: code, child: Text(code)),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null) onCurrencyChanged(value);
                    }
                  : null,
            ),
          ],
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 96,
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: optional
                ? '未填写'
                : moneyDecimalPlaces(currency) == 0
                ? '0'
                : '0.00',
            errorText: errorText,
            errorMaxLines: 3,
            filled: true,
            fillColor: theme.semanticColors.mutedSurface,
            prefixText: currency == 'CNY' ? '¥ ' : '$currency ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}
