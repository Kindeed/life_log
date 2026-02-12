import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'work_log_controller.dart';
import 'log_model.dart';
import '../../common/theme/app_colors.dart';

class AddLogSheet extends StatefulWidget {
  final DateTime selectedDate;
  final WorkLog? existingLog;

  const AddLogSheet({super.key, required this.selectedDate, this.existingLog});

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  late LogType _selectedType;
  final TextEditingController _noteController = TextEditingController();

  // --- 1. 工作相关 ---
  double _overtime = 0.0;

  // --- 2. 出差相关 ---
  final TextEditingController _tripCityController = TextEditingController();
  String _transport = "高铁";
  final TextEditingController _expenseController = TextEditingController();
  bool _isReimbursed = false;

  // --- 3. 请假相关 ---
  String _selectedLeaveType = "年假";
  final TextEditingController _customLeaveController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _selectedType = log.type;
      _noteController.text = log.note ?? "";

      if (log.type == LogType.work) {
        _overtime = log.overtimeHours ?? 0.0;
      } else if (log.type == LogType.businessTrip) {
        _tripCityController.text = log.location ?? "";
        _transport = log.transport ?? "高铁";
        _expenseController.text = log.expenses?.toString() ?? "";
        _isReimbursed = log.isReimbursed;
      } else if (log.type == LogType.leave) {
        if (["年假", "事假", "病假", "调休"].contains(log.location)) {
          _selectedLeaveType = log.location!;
        } else {
          _selectedLeaveType = "其他";
          _customLeaveController.text = log.location ?? "";
        }
      }
    } else {
      _selectedType = LogType.work;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tripCityController.dispose();
    _customLeaveController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final bgColor = isDark ? Colors.grey[850]! : AppColors.lightBackground;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      height: 650.h,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            widget.existingLog != null ? "修改记录" : "记录一下",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),

          SizedBox(height: 20.h),

          _buildTypeSelector(isDark, bgColor, textPrimary, textSecondary),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedType == LogType.work)
                    _buildWorkForm(isDark, bgColor, textPrimary),
                  if (_selectedType == LogType.businessTrip)
                    _buildTripForm(isDark, bgColor, textPrimary),
                  if (_selectedType == LogType.leave)
                    _buildLeaveForm(
                      isDark,
                      bgColor,
                      textPrimary,
                      textSecondary,
                    ),
                  if (_selectedType == LogType.rest)
                    _buildRestForm(isDark, textSecondary),

                  SizedBox(height: 20.h),
                  TextField(
                    controller: _noteController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: "备注 (可选)...",
                      hintStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 30.h),
            child: _buildBottomActions(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(
    bool isDark,
    Color bgColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTypeItem("工作", LogType.work, isDark, textPrimary),
          _buildTypeItem("出差", LogType.businessTrip, isDark, textPrimary),
          _buildTypeItem("请假", LogType.leave, isDark, textPrimary),
          _buildTypeItem("休息", LogType.rest, isDark, textPrimary),
        ],
      ),
    );
  }

  Widget _buildTypeItem(
    String label,
    LogType type,
    bool isDark,
    Color textPrimary,
  ) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.grey[700] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? textPrimary
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    if (widget.existingLog == null) {
      return SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _saveLog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            "保存",
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: TextButton(
                onPressed: _deleteLog,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "删除",
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "保存修改",
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _deleteLog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要删除这条记录吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await WorkLogController.to.deleteLog(widget.existingLog!.id);
              Get.back();
            },
            child: const Text(
              "删除",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _saveLog() {
    final log = WorkLog()
      ..date = widget.existingLog?.date ?? widget.selectedDate
      ..type = _selectedType
      ..note = _noteController.text;

    if (widget.existingLog != null) {
      log.id = widget.existingLog!.id;
    }

    switch (_selectedType) {
      case LogType.work:
        log.overtimeHours = _overtime;
        log.location = null;
        log.transport = null;
        log.expenses = null;
        log.isReimbursed = false;
        break;

      case LogType.rest:
        log.overtimeHours = null;
        log.location = null;
        log.transport = null;
        log.expenses = null;
        log.isReimbursed = false;
        break;

      case LogType.leave:
        log.overtimeHours = null;
        if (_selectedLeaveType == "其他") {
          log.location = _customLeaveController.text.isEmpty
              ? "请假"
              : _customLeaveController.text;
        } else {
          log.location = _selectedLeaveType;
        }
        log.transport = null;
        log.expenses = null;
        log.isReimbursed = false;
        break;

      case LogType.businessTrip:
        log.overtimeHours = null;
        log.location = _tripCityController.text;
        log.transport = _transport;
        log.expenses = double.tryParse(_expenseController.text);
        log.isReimbursed = _isReimbursed;
        break;
    }

    // 标记为需要同步
    log.isDirty = true;

    WorkLogController.to.addLog(log);
    Get.back();
  }

  Widget _buildWorkForm(bool isDark, Color bgColor, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "加班时长",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOvertimeOption(0.0, isDark, bgColor),
            _buildOvertimeOption(1.0, isDark, bgColor),
            _buildOvertimeOption(2.0, isDark, bgColor),
            _buildOvertimeOption(4.0, isDark, bgColor),
          ],
        ),
        SizedBox(height: 12.h),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.access_time,
              color: isDark ? Colors.grey[400] : null,
            ),
            hintText: "自定义时长 (小时)",
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : null),
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            setState(() {
              _overtime = double.tryParse(val) ?? 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOvertimeOption(double value, bool isDark, Color bgColor) {
    final isSelected = _overtime == value;
    return GestureDetector(
      onTap: () => setState(() => _overtime = value),
      child: Container(
        width: 70.w,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1)
              : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value == 0 ? "无" : "$value h",
          style: TextStyle(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTripForm(bool isDark, Color bgColor, Color textPrimary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tripCityController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: isDark ? Colors.grey[400] : null,
                  ),
                  hintText: "城市/地点",
                  hintStyle: TextStyle(color: isDark ? Colors.grey[500] : null),
                  filled: true,
                  fillColor: bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _transport,
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  style: TextStyle(color: textPrimary),
                  items: ["飞机", "高铁", "火车", "打车", "自驾"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _transport = val!),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _expenseController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.attach_money,
              color: isDark ? Colors.grey[400] : null,
            ),
            hintText: "垫付金额 (¥)",
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : null),
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isReimbursed ? Icons.check_circle : Icons.pending_outlined,
                    color: _isReimbursed ? AppColors.green : AppColors.orange,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "是否已报销",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isReimbursed,
                activeThumbColor: AppColors.green,
                onChanged: (val) => setState(() => _isReimbursed = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveForm(
    bool isDark,
    Color bgColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final types = ["年假", "事假", "病假", "调休", "其他"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "请假类型",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: types.map((type) {
            final isSelected = _selectedLeaveType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedLeaveType = type),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.purple.withValues(alpha: isDark ? 0.2 : 0.1)
                      : bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.purple : Colors.transparent,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.purple
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedLeaveType == "其他") ...[
          SizedBox(height: 16.h),
          TextField(
            controller: _customLeaveController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.edit_note,
                color: isDark ? Colors.grey[400] : null,
              ),
              hintText: "请输入请假原因...",
              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : null),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestForm(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.snooze, size: 40.sp, color: AppColors.orange),
          SizedBox(height: 8.h),
          Text(
            "好好休息，补充能量",
            style: TextStyle(color: textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
