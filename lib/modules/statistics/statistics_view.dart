import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'statistics_controller.dart';
import '../../common/db/backup_service.dart';

const Color kPrimaryColor = Color(0xFF1A73E8);
const Color kOrangeColor = Color(0xFFFF6D00);
const Color kPurpleColor = Color(0xFF65558F);
const Color kGreenColor = Color(0xFF2E7D32);
const Color kBgColor = Color(0xFFF7F9FC);

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(StatisticsController());

    return Scaffold(
      backgroundColor: kBgColor,
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
              // 2. 工时卡片
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: _cardDecoration(),
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
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildIconContainer(
                          Icons.timelapse_rounded,
                          kPrimaryColor,
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
                                color: kPrimaryColor,
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
                                color: kPrimaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "累计加班 (小时)",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: kPrimaryColor,
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
                            kPrimaryColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey[200],
                        ),
                        Obx(
                          () => _buildStatItem(
                            "出差",
                            "${logic.tripDays.value}天",
                            kOrangeColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey[200],
                        ),
                        Obx(
                          () => _buildStatItem(
                            "休息",
                            "${logic.restDays.value}天",
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // 3. 财务卡片 (UI 优化：居中对齐)
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: _cardDecoration(),
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
                            color: Colors.black87,
                          ),
                        ),
                        _buildIconContainer(
                          Icons.account_balance_wallet_rounded,
                          kPurpleColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        // 左上：待报销 (总额)
                        Expanded(
                          child: Obx(
                            () => _buildExpenseItem(
                              "待报销总额", // 文案改为总额
                              "¥${logic.unreimbursedAmount.value.toStringAsFixed(0)}",
                              color: kOrangeColor,
                              isBold: true,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // 右上：已报销
                        Expanded(
                          child: Obx(
                            () => _buildExpenseItem(
                              "累计已报销",
                              "¥${logic.reimbursedAmount.value.toStringAsFixed(0)}",
                              color: kGreenColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),
                    Divider(color: Colors.grey[100], height: 1),
                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        // 左下：下月订阅
                        Expanded(
                          child: Obx(
                            () => _buildExpenseItem(
                              "${logic.nextMonth.value}月订阅",
                              "¥${logic.nextMonthSubCost.value.toStringAsFixed(0)}",
                              color: kPurpleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // 右下：固定年支
                        Expanded(
                          child: Obx(
                            () => _buildExpenseItem(
                              "固定年支",
                              "¥${logic.yearSubCost.value.toStringAsFixed(0)}",
                              color: Colors.grey[600]!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // 5. 数据管理面板 (备份与恢复)
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "数据管理",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        _buildIconContainer(Icons.storage_rounded, Colors.grey),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "定期备份数据，防止手机丢失或误删导致记录丢失。",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: "导出全部备份",
                            icon: Icons.cloud_upload_outlined,
                            color: kPrimaryColor,
                            onTap: () => BackupService.exportBackup(),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildActionButton(
                            label: "恢复本地数据",
                            icon: Icons.cloud_download_outlined,
                            color: kOrangeColor,
                            onTap: () => BackupService.importBackup(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // --- 样式辅助方法 ---
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22.sp),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  // 【核心修改】CrossAxisAlignment.center 居中对齐
  Widget _buildExpenseItem(
    String label,
    String value, {
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // 改为居中
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center, // 改为居中
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
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
