import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/common/theme/app_colors.dart';

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
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          Obx(() {
            if (isMultiSelectMode.value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      if (selectedPhotos.length ==
                          controller
                              .groupedPhotos[widget.projectName]!
                              .length) {
                        selectedPhotos.clear();
                      } else {
                        selectedPhotos.assignAll(
                          controller.groupedPhotos[widget.projectName]!,
                        );
                      }
                    },
                    child: Text(
                      selectedPhotos.length ==
                              controller
                                  .groupedPhotos[widget.projectName]!
                                  .length
                          ? "全不选"
                          : "全选",
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      isMultiSelectMode.value = false;
                      selectedPhotos.clear();
                    },
                    child: const Text(
                      "取消",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.checklist_rtl_rounded),
                onPressed: () => isMultiSelectMode.value = true,
                tooltip: "选择模式",
              );
            }
          }),
        ],
      ),
      body: Obx(() {
        final projectPhotos =
            controller.groupedPhotos[widget.projectName] ?? [];

        if (projectPhotos.isEmpty) {
          return Center(
            child: Text("此项目下暂无照片", style: TextStyle(color: textSecondary)),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(12.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.75,
          ),
          itemCount: projectPhotos.length,
          itemBuilder: (context, index) {
            final photo = projectPhotos[index];
            return Obx(() {
              final isSelected = selectedPhotos.contains(photo);
              return GestureDetector(
                onTap: () {
                  if (isMultiSelectMode.value) {
                    if (isSelected) {
                      selectedPhotos.remove(photo);
                    } else {
                      selectedPhotos.add(photo);
                    }
                  } else {
                    _showPhotoDetail(
                      photo,
                      isDark,
                      cardColor,
                      textPrimary,
                      textSecondary,
                    );
                  }
                },
                onLongPress: () {
                  if (!isMultiSelectMode.value) {
                    isMultiSelectMode.value = true;
                    selectedPhotos.add(photo);
                  }
                },
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
                                child: Icon(
                                  Icons.broken_image,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ),
                          if (isMultiSelectMode.value)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.black26,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  isSelected ? Icons.check : null,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      photo.description?.isNotEmpty == true
                          ? photo.description!
                          : "无标题",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.sp, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            });
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!isMultiSelectMode.value || selectedPhotos.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                "选择了 ${selectedPhotos.length} 张",
                style: TextStyle(color: textPrimary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Get.defaultDialog(
                    title: "批量删除",
                    middleText:
                        "确任删除这 ${selectedPhotos.length} 张照片吗？\n此操作不可撤销。",
                    textConfirm: "删除",
                    textCancel: "取消",
                    confirmTextColor: Colors.white,
                    onConfirm: () async {
                      Get.back();
                      final photosToDelete = selectedPhotos.toList();
                      isMultiSelectMode.value = false;
                      selectedPhotos.clear();
                      await controller.deletePhotos(photosToDelete);
                    },
                  );
                },
                icon: const Icon(Icons.delete, size: 18),
                label: const Text("删除"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    controller.exportPhotos(selectedPhotos.toList()),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text("导出"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (isMultiSelectMode.value) return const SizedBox.shrink();
        return FloatingActionButton(
          backgroundColor: AppColors.primaryBlue,
          onPressed: () => _showAddPhotoActions(),
          child: const Icon(Icons.add_photo_alternate, color: Colors.white),
        );
      }),
    );
  }

  void _showAddPhotoActions() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text("拍摄照片"),
                onTap: () {
                  Get.back();
                  controller.captureWithSystemCamera(
                    initialProject: widget.projectName,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text("从相册导入"),
                subtitle: const Text("导入后请求删除系统相册原图"),
                onTap: () {
                  Get.back();
                  controller.importFromGallery(
                    initialProject: widget.projectName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _showPhotoDetail(
    PhotoItem photo,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final TextEditingController descEditController = TextEditingController(
      text: photo.description,
    );
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
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
              _buildInfoRow("保存路径", photo.filePath, textPrimary, textSecondary),
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
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text("确认删除"),
                            content: const Text("删除后无法恢复，确定要删除这张照片吗？"),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text("取消"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Get.back();
                                  await controller.deletePhoto(photo);
                                },
                                child: Text(
                                  "删除",
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
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
