import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'subscription_controller.dart';
import 'subscription_model.dart';
import 'add_subscription_sheet.dart';

// 统一的设计常量
const Color kPrimaryColor = Color(0xFF1A73E8);
const Color kBgColor = Color(0xFFF7F9FC);

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 自定义标题栏 (Modern Header)
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
                      color: Colors.black87,
                    ),
                  ),
                  // 排序按钮变成圆形图标
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.sort_rounded,
                        color: Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'price') logic.sortByPrice();
                        if (value == 'date') logic.sortByDate();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'price',
                          child: Text("按价格排序"),
                        ),
                        const PopupMenuItem(
                          value: 'date',
                          child: Text("按日期排序"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. 列表区域
            Expanded(
              child: Obx(() {
                if (logic.subs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 60.sp,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          "还没有订阅服务",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  itemCount: logic.subs.length,
                  onReorder: (oldIndex, newIndex) =>
                      logic.reorderSub(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final sub = logic.subs[index];
                    return _buildSubCard(sub, logic);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          Get.bottomSheet(
            const AddSubscriptionSheet(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
    );
  }

  Widget _buildSubCard(Subscription sub, SubscriptionController logic) {
    return Container(
      key: ValueKey(sub.id),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    color: kPrimaryColor.withValues(alpha: 0.1), // 统一用蓝色底
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    sub.name.isNotEmpty ? sub.name.substring(0, 1) : "?",
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: kPrimaryColor,
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
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "下次: ${sub.nextPaymentDate.toString().split(' ')[0]}",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[500],
                        ),
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
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      sub.cycle == SubscriptionCycle.monthly ? '/月' : '/年',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10.w),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey[300],
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
