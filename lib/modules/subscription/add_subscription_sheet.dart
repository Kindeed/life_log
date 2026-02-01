import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'subscription_model.dart';
import 'subscription_controller.dart';

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
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        
        // 1. 顶部标题
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80.h,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w, height: 4.h,
                margin: EdgeInsets.only(bottom: 15.h),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                widget.sub == null ? "添加订阅" : "编辑订阅",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),

        body: Column(
          children: [
            // 2. 滚动内容区
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    _buildTextField("服务名称", _nameController, icon: Icons.subscriptions_outlined, hint: "如: Netflix, 百度网盘"),
                    SizedBox(height: 16.h),
                    _buildTextField("价格", _priceController, isNumber: true, icon: Icons.attach_money, hint: "0.00", suffix: "元"),
                    SizedBox(height: 16.h),
                    _buildSelector("付款周期", Icons.update, _getCycleText(_cycle), _showCyclePicker),
                    SizedBox(height: 16.h),
                    _buildSelector("下次扣款日期", Icons.calendar_today_outlined, DateFormat('yyyy-MM-dd').format(_nextPaymentDate), _pickDate),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            // 3. 底部按钮
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]
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
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("保存订阅", style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 逻辑方法 ---

  void _showCyclePicker() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("选择付款周期", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 15.h),
            _buildCycleOption("每月支付", SubscriptionCycle.monthly),
            Divider(height: 1, indent: 20.w, endIndent: 20.w),
            _buildCycleOption("每年支付", SubscriptionCycle.yearly),
            Divider(height: 1, indent: 20.w, endIndent: 20.w),
            _buildCycleOption("一次性", SubscriptionCycle.oneTime),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleOption(String label, SubscriptionCycle value) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16.sp)),
      trailing: _cycle == value
          ? const Icon(Icons.check_circle, color: Color(0xFF1A73E8))
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() => _cycle = value);
        Get.back();
      },
    );
  }

  String _getCycleText(SubscriptionCycle cycle) {
    switch (cycle) {
      case SubscriptionCycle.monthly: return "每月支付";
      case SubscriptionCycle.yearly: return "每年支付";
      case SubscriptionCycle.oneTime: return "一次性";
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
    // 错误检查保持原样，也可以统一风格，这里先保留
    if (_nameController.text.isEmpty) {
      Get.snackbar("错误", "请输入服务名称", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white, margin: EdgeInsets.all(20.w));
      return;
    }
    double? price;
    if (_priceController.text.isNotEmpty) {
      price = double.tryParse(_priceController.text);
      if (price == null || price < 0) {
        Get.snackbar("错误", "价格格式不正确", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white, margin: EdgeInsets.all(20.w));
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
      sub.sortIndex = widget.sub!.sortIndex;
    }

    try {
      Get.find<SubscriptionController>().addSub(sub);
      Get.back();
      
      // --- 核心修改：与工时页面的参数完全一致 ---
      Get.snackbar(
        "成功", 
        "订阅已保存", 
        backgroundColor: const Color(0xFF1A73E8), // 相同的蓝色
        colorText: Colors.white,                  // 白色文字
        snackPosition: SnackPosition.BOTTOM,      // 底部弹出
        margin: EdgeInsets.all(20.w),             // 相同的边距
        duration: const Duration(seconds: 1)      // 相同的 1 秒时长 (默认是3秒)
      );
    } catch (e) {
      Get.snackbar("错误", "无法保存: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  // --- 样式组件 ---

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, IconData? icon, String? suffix, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        ),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: TextStyle(fontSize: 16.sp, color: Colors.black87),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixText: suffix,
            prefixIcon: icon != null
                ? Transform.translate(
                    offset: const Offset(0, 1.5),
                    child: Icon(icon, color: Colors.grey[400], size: 20.sp)
                  )
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            isDense: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSelector(String label, IconData icon, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                SizedBox(width: 12.w),
                Transform.translate(
                   offset: const Offset(0, 1.5),
                   child: Icon(icon, color: Colors.grey[400], size: 20.sp)
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(value, style: TextStyle(fontSize: 16.sp, color: Colors.black87)),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
                SizedBox(width: 12.w),
              ],
            ),
          ),
        ),
      ],
    );
  }
}