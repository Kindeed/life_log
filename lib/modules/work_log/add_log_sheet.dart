import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'work_log_controller.dart';
import 'work_log_model.dart';
import '../../common/theme/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_confirm_dialog.dart';
import '../../common/widgets/app_pill.dart';
import '../../common/widgets/app_safe_bottom_bar.dart';
import '../../common/widgets/app_sheet_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class AddLogSheet extends StatefulWidget {
  final DateTime selectedDate;
  final WorkLog? existingLog;
  final bool asPage;

  const AddLogSheet({
    super.key,
    required this.selectedDate,
    this.existingLog,
    this.asPage = false,
  });

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  late LogType _selectedType;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final FocusNode _overtimeFocusNode = FocusNode();

  // --- 1. 工作相关 ---
  double _overtime = 0.0;

  // --- 2. 出差相关 ---
  final TextEditingController _tripCityController = TextEditingController();
  final FocusNode _tripCityFocusNode = FocusNode();
  String _transport = "高铁";
  final TextEditingController _expenseController = TextEditingController();
  final FocusNode _expenseFocusNode = FocusNode();
  bool _isReimbursed = false;

  // --- 3. 请假相关 ---
  String _selectedLeaveType = "年假";
  final TextEditingController _customLeaveController = TextEditingController();
  final FocusNode _customLeaveFocusNode = FocusNode();
  bool _isTextFieldFocused = false;

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
    for (final node in _textFocusNodes) {
      node.addListener(_syncTextFieldFocus);
    }
  }

  @override
  void dispose() {
    for (final node in _textFocusNodes) {
      node.removeListener(_syncTextFieldFocus);
      node.dispose();
    }
    _noteController.dispose();
    _tripCityController.dispose();
    _customLeaveController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  List<FocusNode> get _textFocusNodes => [
    _noteFocusNode,
    _overtimeFocusNode,
    _tripCityFocusNode,
    _expenseFocusNode,
    _customLeaveFocusNode,
  ];

  void _syncTextFieldFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _textFocusNodes.any((node) => node.hasFocus);
      if (next != _isTextFieldFocused) {
        setState(() => _isTextFieldFocused = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semantic = theme.semanticColors;
    final bgColor = semantic.mutedSurface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return AppSheetScaffold(
      presentation: widget.asPage
          ? AppSheetPresentation.page
          : AppSheetPresentation.sheet,
      height: widget.asPage ? null : sheetHeight,
      title: widget.existingLog != null ? "修改记录" : "记录一下",
      padding: EdgeInsets.zero,
      bottomBar: _isTextFieldFocused
          ? null
          : AppSafeBottomBar(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
              child: _buildBottomActions(isDark),
            ),
      child: Column(
        children: [
          _buildTypeSelector(isDark, bgColor, textPrimary, textSecondary),

          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  AppTextField(
                    controller: _noteController,
                    focusNode: _noteFocusNode,
                    hintText: "备注 (可选)...",
                    maxLines: 3,
                  ),
                ],
              ),
            ),
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
        borderRadius: BorderRadius.circular(22),
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
                ? (isDark ? AppColors.darkDivider : Theme.of(context).cardColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? textPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
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
        child: AppButton.primary(
          label: "保存",
          onPressed: _saveLog,
          height: 50.h,
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: AppButton.destructive(
              label: "删除",
              onPressed: _deleteLog,
              height: 50.h,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: AppButton.primary(
              label: "保存修改",
              onPressed: _saveLog,
              height: 50.h,
            ),
          ),
        ],
      );
    }
  }

  Future<void> _deleteLog() async {
    final confirmed = await AppConfirmDialog.show(
      title: "确认删除",
      message: "确定要删除这条记录吗？",
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;
    await WorkLogController.to.deleteLog(widget.existingLog!.id);
    Get.back();
  }

  Future<void> _saveLog() async {
    double? tripExpense;
    if (_selectedType == LogType.businessTrip) {
      final expenseText = _expenseController.text.trim();
      if (expenseText.isNotEmpty) {
        tripExpense = double.tryParse(expenseText);
        if (tripExpense == null || tripExpense < 0) {
          Get.snackbar(
            "错误",
            "垫付金额格式不正确",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            margin: EdgeInsets.all(20.w),
          );
          return;
        }
      }
    }

    final log = WorkLog()
      ..date = widget.existingLog?.date ?? widget.selectedDate
      ..type = _selectedType
      ..note = _noteController.text;

    if (widget.existingLog != null) {
      log.id = widget.existingLog!.id;
      log.ownerUserId = widget.existingLog!.ownerUserId;
      log.remoteId = widget.existingLog!.remoteId;
      log.syncId = widget.existingLog!.syncId;
      log.remoteVersion = widget.existingLog!.remoteVersion;
      log.remoteUpdatedAt = widget.existingLog!.remoteUpdatedAt;
      log.syncedAt = widget.existingLog!.syncedAt;
      log.deletedAt = widget.existingLog!.deletedAt;
      log.pendingDelete = widget.existingLog!.pendingDelete;
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
        log.expenses = tripExpense;
        log.isReimbursed = _isReimbursed;
        break;
    }

    final existing = widget.existingLog;
    log.isDirty =
        existing == null ||
        existing.isDirty ||
        log.hasBusinessChangesComparedTo(existing);

    try {
      await WorkLogController.to.addLog(log);
      Get.back();
    } catch (_) {
      // Controller already logs and shows the snackbar; stop the success flow.
      return;
    }
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
        AppTextField(
          focusNode: _overtimeFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icon(
            Icons.access_time,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintText: "自定义时长 (小时)",
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
                : Theme.of(context).colorScheme.onSurface,
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
              child: AppTextField(
                controller: _tripCityController,
                focusNode: _tripCityFocusNode,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                hintText: "城市/地点",
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
                  dropdownColor: isDark
                      ? AppColors.darkCard
                      : Theme.of(context).cardColor,
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
        AppTextField(
          controller: _expenseController,
          focusNode: _expenseFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icon(
            Icons.attach_money,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintText: "垫付金额 (¥)",
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
                activeThumbColor: Theme.of(context).colorScheme.primary,
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
              child: AppPill(
                label: type,
                color: AppColors.purple,
                selected: isSelected,
              ),
            );
          }).toList(),
        ),
        if (_selectedLeaveType == "其他") ...[
          SizedBox(height: 16.h),
          AppTextField(
            controller: _customLeaveController,
            focusNode: _customLeaveFocusNode,
            prefixIcon: Icon(
              Icons.edit_note,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            hintText: "请输入请假原因...",
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
