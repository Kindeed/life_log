import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'subscription_model.dart';
import 'subscription_controller.dart';
import '../../common/theme/app_colors.dart';

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
    final cardColor = theme.cardColor;
    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,

        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          toolbarHeight: 80.h,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 15.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                widget.sub == null ? "添加订阅" : "编辑订阅",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),

        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
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
                      () => _showCyclePicker(isDark, cardColor, textPrimary),
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
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "保存订阅",
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCyclePicker(bool isDark, Color cardColor, Color textPrimary) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "选择付款周期",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 15.h),
            _buildCycleOption(
              "每月支付",
              SubscriptionCycle.monthly,
              isDark,
              textPrimary,
            ),
            Divider(
              height: 1,
              indent: 20.w,
              endIndent: 20.w,
              color: isDark ? Colors.grey[700] : null,
            ),
            _buildCycleOption(
              "每年支付",
              SubscriptionCycle.yearly,
              isDark,
              textPrimary,
            ),
            Divider(
              height: 1,
              indent: 20.w,
              endIndent: 20.w,
              color: isDark ? Colors.grey[700] : null,
            ),
            _buildCycleOption(
              "一次性",
              SubscriptionCycle.oneTime,
              isDark,
              textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleOption(
    String label,
    SubscriptionCycle value,
    bool isDark,
    Color textPrimary,
  ) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(fontSize: 16.sp, color: textPrimary),
      ),
      trailing: _cycle == value
          ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
          : Icon(
              Icons.circle_outlined,
              color: isDark ? Colors.grey[600] : Colors.grey,
            ),
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
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: TextStyle(fontSize: 16.sp, color: textPrimary),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(color: textSecondary),
            prefixIcon: icon != null
                ? Transform.translate(
                    offset: const Offset(0, 1.5),
                    child: Icon(
                      icon,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 20.sp,
                    ),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: bgColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            isDense: false,
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
