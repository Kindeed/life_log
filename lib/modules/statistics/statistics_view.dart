import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'statistics_controller.dart';
import '../../common/theme/app_colors.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.find 获取已初始化常驻的 Controller
    final logic = Get.find<StatisticsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("数据面板"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => logic.refreshStats(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 工时卡片
              _buildWorkCard(
                logic,
                isDark,
                cardColor,
                textPrimary,
                textSecondary,
              ),

              SizedBox(height: 20.h),

              // 2. 财务卡片
              _buildFinanceCard(
                logic,
                isDark,
                cardColor,
                textPrimary,
                textSecondary,
              ),

              SizedBox(height: 20.h),
              Center(
                child: Obx(
                  () => Text(
                    "上次刷新: ${logic.lastUpdated.value}",
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkCard(
    StatisticsController logic,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: _cardDecoration(isDark, cardColor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  "${logic.currentMonth.value}月工时",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              _buildIconContainer(
                Icons.timelapse_rounded,
                AppColors.primaryBlue,
                isDark,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Center(
            child: Obx(
              () => Column(
                children: [
                  Text(
                    logic.workHours.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 52.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      fontFamily: "Roboto",
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "累计加班 (小时)",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Obx(
                () => _buildStatItem(
                  "工作",
                  "${logic.workDays.value}天",
                  AppColors.primaryBlue,
                  textPrimary,
                  textSecondary,
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: isDark ? Colors.grey[700] : Colors.grey[200],
              ),
              Obx(
                () => _buildStatItem(
                  "出差",
                  "${logic.tripDays.value}天",
                  AppColors.orange,
                  textPrimary,
                  textSecondary,
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: isDark ? Colors.grey[700] : Colors.grey[200],
              ),
              Obx(
                () => _buildStatItem(
                  "休息",
                  "${logic.restDays.value}天",
                  AppColors.green,
                  textPrimary,
                  textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
    StatisticsController logic,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: _cardDecoration(isDark, cardColor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "财务概览",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              _buildIconContainer(
                Icons.account_balance_wallet_rounded,
                AppColors.purple,
                isDark,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _buildExpenseItem(
                    "待报销总额",
                    "¥${logic.unreimbursedAmount.value.toStringAsFixed(0)}",
                    color: AppColors.orange,
                    isBold: true,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Obx(
                  () => _buildExpenseItem(
                    "累计已报销",
                    "¥${logic.reimbursedAmount.value.toStringAsFixed(0)}",
                    color: AppColors.green,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            height: 1,
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _buildExpenseItem(
                    "${logic.nextMonth.value}月订阅",
                    "¥${logic.nextMonthSubCost.value.toStringAsFixed(0)}",
                    color: AppColors.purple,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Obx(
                  () => _buildExpenseItem(
                    "固定年支",
                    "¥${logic.yearSubCost.value.toStringAsFixed(0)}",
                    color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 样式辅助方法 ---
  BoxDecoration _cardDecoration(bool isDark, Color cardColor) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildIconContainer(IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22.sp),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseItem(
    String label,
    String value, {
    required Color color,
    bool isBold = false,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: color,
              fontFamily: "Roboto",
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: textSecondary),
        ),
      ],
    );
  }
}
