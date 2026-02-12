import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_colors.dart';

void showProjectPicker({
  required TextEditingController controller,
  required List<String> existingProjects,
}) {
  final searchCtrl = TextEditingController();
  final filteredProjects = <String>[...existingProjects].obs;

  Get.bottomSheet(
    Container(
      height: Get.height * 0.7,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Search Bar
          TextField(
            controller: searchCtrl,
            autofocus: true,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "搜索或创建新项目...",
              hintStyle: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              filled: true,
              fillColor: Get.isDarkMode
                  ? const Color(0xFF2C2C2C)
                  : Colors.grey[100],
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
                      .where((p) => p.toLowerCase().contains(val.toLowerCase()))
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
                  child: Text(
                    "暂无项目历史",
                    style: TextStyle(
                      color: Get.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredProjects.length + (showCreate ? 1 : 0),
                itemBuilder: (context, index) {
                  if (showCreate && index == 0) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Get.isDarkMode
                            ? AppColors.primaryBlue.withValues(alpha: 0.2)
                            : Colors.blue[50],
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      title: Text(
                        "创建新项目: \"$query\"",
                        style: TextStyle(
                          color: Get.isDarkMode ? Colors.white : Colors.black87,
                        ),
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
                    leading: Icon(
                      Icons.folder,
                      color: Get.isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    title: Text(
                      pName,
                      style: TextStyle(
                        color: Get.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: controller.text == pName
                        ? const Icon(Icons.check, color: AppColors.primaryBlue)
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
    ),
    isScrollControlled: true,
  );
}
