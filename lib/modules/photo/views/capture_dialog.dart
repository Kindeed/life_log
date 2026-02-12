import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/views/project_picker.dart';

void showCaptureDialog({
  required String tempPath,
  String? initialProject,
  required Function(String projectName, String description) onConfirm,
}) {
  final projectCtrl = TextEditingController(
    text: initialProject ?? "DefaultProject",
  );
  final descCtrl = TextEditingController();

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(width: 16),
              Text(
                "归档照片",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Project Selector (Instagram Style)
          GestureDetector(
            onTap: () => showProjectPicker(
              controller: projectCtrl,
              existingProjects: PhotoController.to.groupedPhotos.keys.toList(),
            ),
            child: AbsorbPointer(
              child: TextField(
                controller: projectCtrl,
                style: TextStyle(
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: "选择归档项目",
                  labelStyle: TextStyle(
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.folder_special_rounded,
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Get.isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF7F9FC),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Input
          TextField(
            controller: descCtrl,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: "添加备注 (可选)",
              labelStyle: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Get.isDarkMode
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFF7F9FC),
            ),
          ),
          const SizedBox(height: 32),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final projectName = projectCtrl.text.trim();
                if (projectName.isEmpty) {
                  Get.snackbar("错误", "项目名称不能为空");
                  return;
                }
                Get.back(); // Close bottom sheet
                onConfirm(projectName, descCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),

                elevation: 0,
              ),
              child: const Text(
                "确认录入",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
