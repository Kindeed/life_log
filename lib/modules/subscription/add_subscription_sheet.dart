import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'subscription_model.dart';
import 'subscription_controller.dart';
import '../../common/theme/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_safe_bottom_bar.dart';
import '../../common/widgets/app_sheet_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final Subscription? sub;
  const AddSubscriptionSheet({super.key, this.sub});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  SubscriptionCycle _cycle = SubscriptionCycle.monthly;
  DateTime _nextPaymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.sub != null) {
      _nameController.text = widget.sub!.name;
      if (widget.sub!.price != null) {
        _priceController.text = widget.sub!.price.toString();
      }
      _cycle = widget.sub!.cycle;
      _nextPaymentDate = widget.sub!.nextPaymentDate;
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
      title: widget.sub == null ? "添加订阅" : "编辑订阅",
      height: sheetHeight,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      bottomBar: AppSafeBottomBar(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: SizedBox(
          width: double.infinity,
          child: AppButton.primary(
            label: "保存订阅",
            onPressed: _onSave,
            height: 50.h,
          ),
        ),
      ),
      child: SingleChildScrollView(
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
              suffix: "元",
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

  void _showCyclePicker() {
    Get.bottomSheet(
      AppSheetScaffold(
        title: "选择付款周期",
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCycleOption("每月支付", SubscriptionCycle.monthly),
            _buildCycleOption("每年支付", SubscriptionCycle.yearly),
            _buildCycleOption("一次性", SubscriptionCycle.oneTime),
            SizedBox(height: 16.h),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildCycleOption(String label, SubscriptionCycle value) {
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
        Get.back();
      },
    );
  }

  String _getCycleText(SubscriptionCycle cycle) {
    switch (cycle) {
      case SubscriptionCycle.monthly:
        return "每月支付";
      case SubscriptionCycle.yearly:
        return "每年支付";
      case SubscriptionCycle.oneTime:
        return "一次性";
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _nextPaymentDate = picked);
    }
  }

  void _onSave() {
    if (_nameController.text.isEmpty) {
      Get.snackbar(
        "错误",
        "请输入服务名称",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: EdgeInsets.all(20.w),
      );
      return;
    }
    double? price;
    if (_priceController.text.isNotEmpty) {
      price = double.tryParse(_priceController.text);
      if (price == null || price < 0) {
        Get.snackbar(
          "错误",
          "价格格式不正确",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: EdgeInsets.all(20.w),
        );
        return;
      }
    }

    final sub = Subscription()
      ..name = _nameController.text
      ..price = price
      ..cycle = _cycle
      ..nextPaymentDate = _nextPaymentDate;

    if (widget.sub != null) {
      sub.id = widget.sub!.id;
      sub.ownerUserId = widget.sub!.ownerUserId;
      sub.sortIndex = widget.sub!.sortIndex;
      sub.remoteId = widget.sub!.remoteId;
      sub.syncId = widget.sub!.syncId;
      sub.remoteVersion = widget.sub!.remoteVersion;
      sub.remoteUpdatedAt = widget.sub!.remoteUpdatedAt;
      sub.syncedAt = widget.sub!.syncedAt;
      sub.deletedAt = widget.sub!.deletedAt;
      sub.pendingDelete = widget.sub!.pendingDelete;
    }

    // 标记为需要同步
    sub.isDirty = true;

    try {
      Get.find<SubscriptionController>().addSub(sub);
      Get.back();

      Get.snackbar(
        "成功",
        "订阅已保存",
        backgroundColor: AppColors.primaryBlue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar("错误", "无法保存: $e", snackPosition: SnackPosition.BOTTOM);
    }
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
              border: Border.all(color: borderColor),
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
