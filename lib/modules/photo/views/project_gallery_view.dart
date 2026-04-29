import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';

class ProjectGalleryView extends StatefulWidget {
  final String projectName;

  const ProjectGalleryView({super.key, required this.projectName});

  @override
  State<ProjectGalleryView> createState() => _ProjectGalleryViewState();
}

class _ProjectGalleryViewState extends State<ProjectGalleryView> {
  final PhotoController controller = Get.find<PhotoController>();
  final RxList<PhotoItem> selectedPhotos = <PhotoItem>[].obs;
  final RxBool isMultiSelectMode = false.obs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final semantic = theme.extension<AppSemanticColors>()!;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            isMultiSelectMode.value
                ? "已选 ${selectedPhotos.length} 张"
                : widget.projectName,
          ),
        ),
        actions: [
          Obx(() {
            final projectPhotos =
                controller.groupedPhotos[widget.projectName] ?? [];

            if (isMultiSelectMode.value) {
              if (projectPhotos.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  selectedPhotos.clear();
                  isMultiSelectMode.value = false;
                });
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      if (selectedPhotos.length == projectPhotos.length) {
                        selectedPhotos.clear();
                      } else {
                        selectedPhotos.assignAll(projectPhotos);
                      }
                    },
                    child: Text(
                      selectedPhotos.length == projectPhotos.length
                          ? "全不选"
                          : "全选",
                    ),
                  ),
                  TextButton(
                    onPressed: _exitSelectionMode,
                    child: Text(
                      "取消",
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  onPressed: _showAddPhotoActions,
                  tooltip: "添加照片",
                ),
                if (projectPhotos.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist_rtl_rounded),
                    onPressed: () => isMultiSelectMode.value = true,
                    tooltip: "选择模式",
                  ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        final projectPhotos =
            controller.groupedPhotos[widget.projectName] ?? [];

        if (projectPhotos.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            selectedPhotos.clear();
            isMultiSelectMode.value = false;
          });
          return AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: "此项目下暂无照片",
            message: "继续拍摄或从相册导入后会归档到当前项目",
            actionLabel: "添加照片",
            onAction: _showAddPhotoActions,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final rawCount = (constraints.maxWidth / 120.w).floor();
            final crossAxisCount = rawCount < 3
                ? 3
                : rawCount > 6
                ? 6
                : rawCount;

            return GridView.builder(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 96.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.75,
              ),
              itemCount: projectPhotos.length,
              itemBuilder: (context, index) {
                final photo = projectPhotos[index];
                return Obx(() {
                  final isSelected = selectedPhotos.contains(photo);
                  return _PhotoTile(
                    photo: photo,
                    isSelectionMode: isMultiSelectMode.value,
                    isSelected: isSelected,
                    selectedColor: semantic.project,
                    textSecondary: textSecondary,
                    onTap: () {
                      if (isMultiSelectMode.value) {
                        _togglePhoto(photo);
                        return;
                      }
                      _showPhotoDetail(
                        photo,
                        isDark,
                        cardColor,
                        textPrimary,
                        textSecondary,
                      );
                    },
                    onLongPress: () {
                      if (!isMultiSelectMode.value) {
                        isMultiSelectMode.value = true;
                        selectedPhotos.add(photo);
                      }
                    },
                  );
                });
              },
            );
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!isMultiSelectMode.value || selectedPhotos.isEmpty) {
          return const SizedBox.shrink();
        }

        return AppSafeBottomBar(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "已选择 ${selectedPhotos.length} 张",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _confirmDeleteSelected,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text("删除"),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
              SizedBox(width: 8.w),
              FilledButton.icon(
                onPressed: () =>
                    controller.exportPhotos(selectedPhotos.toList()),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text("导出"),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final projectPhotos =
            controller.groupedPhotos[widget.projectName] ?? [];
        if (isMultiSelectMode.value || projectPhotos.isEmpty) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          backgroundColor: semantic.project,
          foregroundColor: Colors.white,
          onPressed: _showAddPhotoActions,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text("添加"),
        );
      }),
    );
  }

  void _togglePhoto(PhotoItem photo) {
    if (selectedPhotos.contains(photo)) {
      selectedPhotos.remove(photo);
    } else {
      selectedPhotos.add(photo);
    }
  }

  void _exitSelectionMode() {
    isMultiSelectMode.value = false;
    selectedPhotos.clear();
  }

  void _confirmDeleteSelected() {
    Get.defaultDialog(
      title: "批量删除",
      middleText: "确认删除这 ${selectedPhotos.length} 张照片吗？\n此操作不可撤销。",
      textConfirm: "删除",
      textCancel: "取消",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        final photosToDelete = selectedPhotos.toList();
        _exitSelectionMode();
        await controller.deletePhotos(photosToDelete);
      },
    );
  }

  void _showAddPhotoActions() {
    AppActionSheet.show(
      title: "添加到 ${widget.projectName}",
      actions: [
        AppActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: "拍摄照片",
          onTap: () => controller.captureWithSystemCamera(
            initialProject: widget.projectName,
          ),
        ),
        AppActionSheetItem(
          icon: Icons.photo_library_rounded,
          title: "从相册导入",
          subtitle: "导入后请求删除系统相册原图",
          onTap: () =>
              controller.importFromGallery(initialProject: widget.projectName),
        ),
      ],
    );
  }

  void _showPhotoDetail(
    PhotoItem photo,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final descEditController = TextEditingController(text: photo.description);
    final theme = Theme.of(context);

    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "照片详情",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textSecondary),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photo.filePath),
                      height: 200.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                _buildInfoRow(
                  "项目名称",
                  photo.projectName ?? "Default",
                  textPrimary,
                  textSecondary,
                ),
                _buildInfoRow(
                  "设备名称",
                  photo.deviceName ?? "Unknown",
                  textPrimary,
                  textSecondary,
                ),
                _buildInfoRow(
                  "拍摄时间",
                  photo.createdAt.toString().substring(0, 19),
                  textPrimary,
                  textSecondary,
                ),
                _buildInfoRow(
                  "保存路径",
                  photo.filePath,
                  textPrimary,
                  textSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  "补充说明",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: descEditController,
                  maxLines: 3,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "添加补充说明...",
                    hintStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeletePhoto(photo),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        label: Text(
                          "删除",
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.updatePhotoDescription(
                          photo,
                          descEditController.text,
                        ),
                        icon: const Icon(Icons.save, size: 20),
                        label: const Text("保存修改"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmDeletePhoto(PhotoItem photo) {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        title: const Text("确认删除"),
        content: const Text("删除后无法恢复，确定要删除这张照片吗？"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.deletePhoto(photo);
            },
            child: Text("删除", style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PhotoItem photo;
  final bool isSelectionMode;
  final bool isSelected;
  final Color selectedColor;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoTile({
    required this.photo,
    required this.isSelectionMode,
    required this.isSelected,
    required this.selectedColor,
    required this.textSecondary,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(photo.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Center(
                      child: Icon(Icons.broken_image, color: textSecondary),
                    ),
                  ),
                ),
                if (isSelectionMode)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? selectedColor : Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        isSelected ? Icons.check : null,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isSelected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selectedColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            photo.description?.isNotEmpty == true ? photo.description! : "无标题",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.sp, color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
