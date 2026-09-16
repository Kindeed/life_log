import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_date_picker.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/delete_subscription_entry.dart';
import 'package:life_log/features/subscription/application/save_subscription_entry.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

import 'subscription_dialogs.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final SubscriptionEntry? existingEntry;
  final bool existingAlreadyDirty;
  final bool asPage;

  const AddSubscriptionSheet({
    super.key,
    this.existingEntry,
    this.existingAlreadyDirty = false,
    this.asPage = false,
  });

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  SubscriptionBillingCycle _cycle = SubscriptionBillingCycle.monthly;
  SubscriptionCurrency _currency = SubscriptionCurrency.cny;
  int _reminderDays = 1;
  DateTime _nextPaymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existingEntry = widget.existingEntry;
    if (existingEntry != null) {
      _nameController.text = existingEntry.name;
      if (existingEntry.price != null) {
        _priceController.text = existingEntry.price.toString();
      }
      _cycle = existingEntry.cycle;
      _currency = existingEntry.currency;
      _reminderDays = existingEntry.reminderDays;
      _nextPaymentDate = dateOnlyLocal(existingEntry.nextPaymentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semantic = theme.semanticColors;
    final bgColor = semantic.mutedSurface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final borderColor = semantic.border;

    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return AppSheetScaffold(
      presentation: widget.asPage
          ? AppSheetPresentation.page
          : AppSheetPresentation.sheet,
      title: widget.existingEntry == null ? "添加订阅" : "编辑订阅",
      height: widget.asPage ? null : sheetHeight,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      bottomBar: AppSafeBottomBar(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: widget.existingEntry == null
            ? SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: "保存订阅",
                  onPressed: _onSave,
                  height: 50.h,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: AppButton.destructive(
                      label: "删除",
                      icon: Icons.delete_outline_rounded,
                      onPressed: _onDelete,
                      height: 50.h,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton.primary(
                      label: "保存修改",
                      onPressed: _onSave,
                      height: 50.h,
                    ),
                  ),
                ],
              ),
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildTextField(
              "服务名称",
              _nameController,
              icon: Icons.subscriptions_outlined,
              hint: "如: Netflix, 百度网盘",
              isDark: isDark,
              bgColor: bgColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              "价格",
              _priceController,
              isNumber: true,
              icon: Icons.attach_money,
              hint: "0.00",
              suffix: _currency.symbol,
              isDark: isDark,
              bgColor: bgColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            SizedBox(height: 16.h),
            _buildSelector(
              "币种",
              Icons.currency_exchange_rounded,
              _currency.displayLabel,
              _showCurrencyPicker,
              isDark: isDark,
              bgColor: bgColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            SizedBox(height: 16.h),
            _buildSelector(
              "付款周期",
              Icons.update,
              _getCycleText(_cycle),
              _showCyclePicker,
              isDark: isDark,
              bgColor: bgColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            SizedBox(height: 16.h),
            _buildSelector(
              "扣费提醒",
              Icons.notifications_active_outlined,
              _reminderLabel(_reminderDays),
              _showReminderPicker,
              isDark: isDark,
              bgColor: bgColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            SizedBox(height: 16.h),
            _buildSelector(
              "下次扣款日期",
              Icons.calendar_today_outlined,
              DateFormat('yyyy-MM-dd').format(_nextPaymentDate),
              _pickDate,
              isDark: isDark,
              bgColor: bgColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showCyclePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppSheetScaffold(
          title: "选择付款周期",
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCycleOption(
                sheetContext,
                "每月支付",
                SubscriptionBillingCycle.monthly,
              ),
              _buildCycleOption(
                sheetContext,
                "每年支付",
                SubscriptionBillingCycle.yearly,
              ),
              _buildCycleOption(
                sheetContext,
                "一次性",
                SubscriptionBillingCycle.oneTime,
              ),
              _buildCycleOption(
                sheetContext,
                "自定义",
                SubscriptionBillingCycle.custom,
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppSheetScaffold(
          title: "选择币种",
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final currency in SubscriptionCurrency.values)
                ListTile(
                  leading: Text(
                    currency.symbol,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  title: Text(currency.displayLabel),
                  trailing: _currency == currency
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    setState(() => _currency = currency);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showReminderPicker() {
    const options = <int>[0, 1, 3, 7, 14];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppSheetScaffold(
          title: "选择扣费提醒",
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final days in options)
                ListTile(
                  leading: Icon(
                    days == 0
                        ? Icons.today_rounded
                        : Icons.notifications_none_rounded,
                  ),
                  title: Text(_reminderLabel(days)),
                  trailing: _reminderDays == days
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    setState(() => _reminderDays = days);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCycleOption(
    BuildContext sheetContext,
    String label,
    SubscriptionBillingCycle value,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        label,
        style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
      ),
      trailing: _cycle == value
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.outline),
      onTap: () {
        setState(() => _cycle = value);
        Navigator.of(sheetContext).pop();
      },
    );
  }

  void _showMessage(String message, {required bool isError}) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? theme.colorScheme.error : semantic.success,
          duration: Duration(seconds: isError ? 3 : 1),
        ),
      );
  }

  String _getCycleText(SubscriptionBillingCycle cycle) {
    switch (cycle) {
      case SubscriptionBillingCycle.monthly:
        return "每月支付";
      case SubscriptionBillingCycle.yearly:
        return "每年支付";
      case SubscriptionBillingCycle.oneTime:
        return "一次性";
      case SubscriptionBillingCycle.custom:
        return "自定义";
    }
  }

  void _pickDate() async {
    final picked = await showLifeLogDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _nextPaymentDate = dateOnlyLocal(picked));
    }
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage("请输入服务名称", isError: true);
      return;
    }
    double? price;
    final priceText = _priceController.text.trim();
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText);
      if (price == null || price < 0) {
        _showMessage("价格格式不正确", isError: true);
        return;
      }
    }

    final existingEntry = widget.existingEntry;
    final entry = SubscriptionEntry(
      id: existingEntry?.id ?? 0,
      name: name,
      price: price,
      currency: _currency,
      cycle: _cycle,
      nextPaymentDate: dateOnlyLocal(_nextPaymentDate),
      anchorDate: existingEntry?.anchorDate ?? dateOnlyLocal(_nextPaymentDate),
      endDate: existingEntry?.endDate,
      status: existingEntry?.status ?? SubscriptionStatus.active,
      reminderDays: _reminderDays,
      note: existingEntry?.note,
      sortIndex: existingEntry?.sortIndex,
    );

    final markDirty =
        existingEntry == null ||
        widget.existingAlreadyDirty ||
        entry.hasBusinessChangesComparedTo(existingEntry);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = Theme.of(context).semanticColors.success;
    final result = await serviceLocator<SaveSubscriptionEntry>().call(
      entry,
      markDirty: markDirty,
    );
    if (!mounted) return;

    result.when(
      success: (_) {
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text("订阅已保存"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: successColor,
              duration: const Duration(seconds: 1),
            ),
          );
      },
      failure: (failure) {
        _showMessage("保存失败：${_errorText(failure.message)}", isError: true);
      },
    );
  }

  Future<void> _onDelete() async {
    final existingEntry = widget.existingEntry;
    if (existingEntry == null) return;

    final confirmed = await confirmSubscriptionDelete(
      context,
      name: existingEntry.name,
    );
    if (!confirmed || !mounted) return;

    final result = await serviceLocator<DeleteSubscriptionEntry>().call(
      existingEntry.id,
    );
    if (!mounted) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      _showMessage("删除失败：${_errorText(failure.message)}", isError: true);
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("订阅已删除"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _reminderLabel(int days) {
    if (days == 0) return "扣费当天提醒";
    return "提前 $days 天提醒";
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    IconData? icon,
    String? suffix,
    String? hint,
    required bool isDark,
    required Color bgColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        AppTextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          hintText: hint,
          prefixIcon: icon == null
              ? null
              : Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20.sp,
                ),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Center(
                    widthFactor: 1,
                    child: Text(suffix, style: TextStyle(color: textSecondary)),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSelector(
    String label,
    IconData icon,
    String value,
    VoidCallback onTap, {
    required bool isDark,
    required Color bgColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                SizedBox(width: 12.w),
                Transform.translate(
                  offset: const Offset(0, 1.5),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 16.sp, color: textPrimary),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
                SizedBox(width: 12.w),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
