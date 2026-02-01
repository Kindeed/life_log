import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'work_log_controller.dart';
import 'log_model.dart'; // 确保引入了你最新的 LogModel

const Color kPrimaryColor = Color(0xFF1A73E8);
const Color kBgColor = Color(0xFFF7F9FC);

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

      // --- 回显逻辑 ---
      if (log.type == LogType.work) {
        _overtime = log.overtimeHours ?? 0.0;
      } else if (log.type == LogType.businessTrip) {
        _tripCityController.text = log.location ?? "";
        _transport = log.transport ?? "高铁";
        _expenseController.text = log.expenses?.toString() ?? "";
        _isReimbursed = log.isReimbursed;
      } else if (log.type == LogType.leave) {
        // 判断旧数据是不是标准类型
        if (["年假", "事假", "病假", "调休"].contains(log.location)) {
          _selectedLeaveType = log.location!;
        } else {
          _selectedLeaveType = "其他";
          _customLeaveController.text = log.location ?? "";
        }
      }
      // LogType.rest 不需要特殊回显
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
    return Container(
      height: 650.h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            widget.existingLog != null ? "修改记录" : "记录一下",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20.h),

          _buildTypeSelector(),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedType == LogType.work) _buildWorkForm(),
                  if (_selectedType == LogType.businessTrip) _buildTripForm(),
                  if (_selectedType == LogType.leave) _buildLeaveForm(),
                  if (_selectedType == LogType.rest) _buildRestForm(),

                  SizedBox(height: 20.h),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: "备注 (可选)...",
                      filled: true,
                      fillColor: kBgColor,
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
            child: _buildBottomActions(),
          ),
        ],
      ),
    );
  }

  // --- 底部按钮 ---
  Widget _buildBottomActions() {
    // ... 保持原有代码不变，只是调用 _saveLog ...
    // 为节省篇幅，此处逻辑与上一版相同，直接调用下面的 _saveLog 即可
    if (widget.existingLog == null) {
      return SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _saveLog,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
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
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
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
                  backgroundColor: kPrimaryColor,
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

  // --- 核心修复：保存逻辑 ---
  void _saveLog() {
    final log = WorkLog()
      ..date = widget.existingLog?.date ?? widget.selectedDate
      ..type = _selectedType
      ..note = _noteController.text;

    if (widget.existingLog != null) {
      log.id = widget.existingLog!.id;
    }

    // 根据你的 LogModel 严格清洗数据
    // 必须将不属于当前类型的字段设为 null，防止 Isar 数据库中残留旧数据
    switch (_selectedType) {
      case LogType.work:
        log.overtimeHours = _overtime;
        // 清洗无关字段
        log.location = null;
        log.transport = null;
        log.expenses = null;
        log.isReimbursed = false;
        break;

      case LogType.rest:
        log.overtimeHours = null;
        // 休息必须清空 location，否则日历可能因为 location 有值而误判为出差/请假
        log.location = null;
        log.transport = null;
        log.expenses = null;
        log.isReimbursed = false;
        break;

      case LogType.leave:
        log.overtimeHours = null;
        // 复用 location 字段存储请假类型
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
        // 复用 location 字段存储城市
        log.location = _tripCityController.text;
        log.transport = _transport;
        log.expenses = double.tryParse(_expenseController.text);
        log.isReimbursed = _isReimbursed;
        break;
    }

    WorkLogController.to.addLog(log);
    Get.back();
  }

  // --- UI 构建方法 (保持原样，仅确保 LogType 匹配) ---

  Widget _buildTypeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTypeItem("工作", LogType.work),
          _buildTypeItem("出差", LogType.businessTrip),
          _buildTypeItem("请假", LogType.leave),
          _buildTypeItem("休息", LogType.rest),
        ],
      ),
    );
  }

  Widget _buildTypeItem(String label, LogType type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // ... (WorkForm, TripForm, LeaveForm 代码与上一版相同，此处省略以节省空间) ...
  // 请直接复用上方代码块中的 _buildWorkForm, _buildTripForm, _buildLeaveForm

  // 补上之前省略的表单代码，确保完整性
  Widget _buildWorkForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "加班时长",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOvertimeOption(0.0),
            _buildOvertimeOption(1.0),
            _buildOvertimeOption(2.0),
            _buildOvertimeOption(4.0),
          ],
        ),
        SizedBox(height: 12.h),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.access_time),
            hintText: "自定义时长 (小时)",
            filled: true,
            fillColor: kBgColor,
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

  Widget _buildOvertimeOption(double value) {
    final isSelected = _overtime == value;
    return GestureDetector(
      onTap: () => setState(() => _overtime = value),
      child: Container(
        width: 70.w,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withValues(alpha: 0.1) : kBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value == 0 ? "无" : "$value h",
          style: TextStyle(
            color: isSelected ? kPrimaryColor : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTripForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tripCityController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  hintText: "城市/地点",
                  filled: true,
                  fillColor: kBgColor,
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
                color: kBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _transport,
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
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.attach_money),
            hintText: "垫付金额 (¥)",
            filled: true,
            fillColor: kBgColor,
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
            color: kBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isReimbursed ? Icons.check_circle : Icons.pending_outlined,
                    color: _isReimbursed ? Colors.green : Colors.orange,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "是否已报销",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isReimbursed,
                activeThumbColor: Colors.green,
                onChanged: (val) => setState(() => _isReimbursed = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveForm() {
    final types = ["年假", "事假", "病假", "调休", "其他"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "请假类型",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
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
                      ? Colors.purple.withValues(alpha: 0.1)
                      : kBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.purple : Colors.transparent,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.purple : Colors.grey[700],
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
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.edit_note),
              hintText: "请输入请假原因...",
              filled: true,
              fillColor: kBgColor,
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

  Widget _buildRestForm() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.snooze, size: 40.sp, color: Colors.orange),
          SizedBox(height: 8.h),
          Text(
            "好好休息，补充能量",
            style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
