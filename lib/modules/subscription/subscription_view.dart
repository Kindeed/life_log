import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'subscription_controller.dart';
import 'subscription_model.dart';
import 'add_subscription_sheet.dart';
import '../../common/theme/app_colors.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<SubscriptionController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 自定义标题栏
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "支出管理",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.sort_rounded, color: textPrimary),
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'price') logic.sortByPrice();
                        if (value == 'date') logic.sortByDate();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'price',
                          child: Text(
                            "按价格排序",
                            style: TextStyle(color: textPrimary),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'date',
                          child: Text(
                            "按日期排序",
                            style: TextStyle(color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. 列表区域
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  logic.onScroll(notification);
                  return true;
                },
                child: Obx(() {
                  if (logic.subs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subscriptions_outlined,
                            size: 60.sp,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "还没有订阅服务",
                            style: TextStyle(color: textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ReorderableListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 80.h),
                    itemCount: logic.subs.length,
                    onReorder: (oldIndex, newIndex) =>
                        logic.reorderSub(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final sub = logic.subs[index];
                      return _buildSubCard(
                        sub,
                        logic,
                        isDark,
                        cardColor,
                        textPrimary,
                        textSecondary,
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(
        () => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: logic.isFabVisible.value ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: logic.isFabVisible.value ? 1 : 0,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              elevation: 4,
              icon: const Icon(
                Icons.add_rounded,
                size: 24,
                color: Colors.white,
              ),
              label: Text(
                "记一笔",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Get.bottomSheet(
                  const AddSubscriptionSheet(),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCard(
    Subscription sub,
    SubscriptionController logic,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      key: ValueKey(sub.id),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Get.bottomSheet(
              AddSubscriptionSheet(sub: sub),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    sub.name.isNotEmpty ? sub.name.substring(0, 1) : "?",
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "下次: ${sub.nextPaymentDate.toString().split(' ')[0]}",
                        style: TextStyle(fontSize: 13.sp, color: textSecondary),
                      ),
                    ],
                  ),
                ),

                // 价格 & 删除
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "¥${sub.price ?? 0}",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Roboto",
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      sub.cycle == SubscriptionCycle.monthly ? '/月' : '/年',
                      style: TextStyle(fontSize: 12.sp, color: textSecondary),
                    ),
                  ],
                ),
                SizedBox(width: 10.w),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    size: 20.sp,
                  ),
                  onPressed: () => logic.deleteSub(sub.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
