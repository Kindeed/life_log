import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_colors.dart';

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
        final isDark = theme.brightness == Brightness.dark;
        final textColor = theme.colorScheme.onSurface;
        final hintColor = theme.colorScheme.onSurfaceVariant;
        final fillColor = isDark ? theme.cardColor : Colors.grey[100]!;

        return Container(
          height: Get.height * 0.7,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                controller: searchCtrl,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "搜索或创建新项目...",
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: hintColor),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
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
              const SizedBox(height: 16),

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
