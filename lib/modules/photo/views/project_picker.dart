import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';

/// 项目选择器底部弹窗。
///
/// 显示已有项目列表并支持搜索和创建新项目。
void showProjectPicker({
  required TextEditingController controller,
  required List<String> existingProjects,
}) {
  final searchCtrl = TextEditingController();
  final filteredProjects = <String>[...existingProjects].obs;

  Get.bottomSheet(
    Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final textColor = theme.colorScheme.onSurface;
        final hintColor = theme.colorScheme.onSurfaceVariant;

        return AppSheetScaffold(
          title: "选择项目",
          height: Get.height * 0.7,
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
          child: Column(
            children: [
              // Search Bar
              AppTextField(
                controller: searchCtrl,
                autofocus: true,
                hintText: "搜索或创建新项目...",
                prefixIcon: Icon(Icons.search, color: hintColor),
                onChanged: (val) {
                  if (val.isEmpty) {
                    filteredProjects.assignAll(existingProjects);
                  } else {
                    filteredProjects.assignAll(
                      existingProjects
                          .where(
                            (p) => p.toLowerCase().contains(val.toLowerCase()),
                          )
                          .toList(),
                    );
                  }
                },
              ),
              SizedBox(height: 16.h),

              // List
              Expanded(
                child: Obx(() {
                  // Determine if we need to show "Create New"
                  final query = searchCtrl.text.trim();
                  final showCreate =
                      query.isNotEmpty && !filteredProjects.contains(query);

                  if (filteredProjects.isEmpty && !showCreate) {
                    return Center(
                      child: Text("暂无项目历史", style: TextStyle(color: hintColor)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredProjects.length + (showCreate ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showCreate && index == 0) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryBlue.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          title: Text(
                            "创建新项目: \"$query\"",
                            style: TextStyle(color: textColor),
                          ),
                          onTap: () {
                            controller.text = query;
                            Get.back(); // Close picker
                          },
                        );
                      }

                      final dataIndex = showCreate ? index - 1 : index;
                      final pName = filteredProjects[dataIndex];
                      return ListTile(
                        leading: Icon(Icons.folder, color: hintColor),
                        title: Text(pName, style: TextStyle(color: textColor)),
                        trailing: controller.text == pName
                            ? const Icon(
                                Icons.check,
                                color: AppColors.primaryBlue,
                              )
                            : null,
                        onTap: () {
                          controller.text = pName;
                          Get.back(); // Close picker
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    ),
    isScrollControlled: true,
  );
}
