import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_confirm_dialog.dart';
import 'package:life_log/common/widgets/app_floating_action_pill.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';

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
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          Obx(() {
            if (isMultiSelectMode.value) {
              final projectPhotos =
                  controller.groupedPhotos[widget.projectName] ?? [];
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            selectedPhotos.clear();
            isMultiSelectMode.value = false;
          });
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
                    _showPhotoDetail(photo, textPrimary, textSecondary);
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
        return AppSafeBottomBar(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
          child: Row(
            children: [
              Text(
                "选择了 ${selectedPhotos.length} 张",
                style: TextStyle(color: textPrimary),
              ),
              const Spacer(),
              AppButton.destructive(
                onPressed: _deleteSelectedPhotos,
                icon: Icons.delete_outline,
                label: "删除",
                height: 42.h,
              ),
              const SizedBox(width: 8),
              AppButton.primary(
                onPressed: () =>
                    controller.exportPhotos(selectedPhotos.toList()),
                icon: Icons.ios_share,
                label: "导出",
                height: 42.h,
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (isMultiSelectMode.value) return const SizedBox.shrink();
        return AppFloatingActionPill(
          label: "添加照片",
          icon: Icons.add_photo_alternate,
          color: Theme.of(context).colorScheme.primary,
          visible: true,
          onPressed: () => _showAddPhotoActions(),
        );
      }),
    );
  }

  Future<void> _deleteSelectedPhotos() async {
    final confirmed = await AppConfirmDialog.show(
      title: "批量删除",
      message: "确定删除这 ${selectedPhotos.length} 张照片吗？删除后无法恢复。",
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;
    final photosToDelete = selectedPhotos.toList();
    isMultiSelectMode.value = false;
    selectedPhotos.clear();
    await controller.deletePhotos(photosToDelete);
  }

  void _showAddPhotoActions() {
    AppActionSheet.show(
      title: "添加照片",
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
    Color textPrimary,
    Color textSecondary,
  ) {
    final TextEditingController descEditController = TextEditingController(
      text: photo.description,
    );
    Get.bottomSheet(
      AppSheetScaffold(
        title: "照片详情",
        scrollable: true,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            SizedBox(height: 8.h),
            AppTextField(
              controller: descEditController,
              maxLines: 3,
              hintText: "添加补充说明...",
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: AppButton.destructive(
                    label: "删除",
                    icon: Icons.delete_outline,
                    onPressed: () => _deletePhoto(photo),
                    height: 48.h,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppButton.primary(
                    label: "保存修改",
                    icon: Icons.save,
                    onPressed: () => controller.updatePhotoDescription(
                      photo,
                      descEditController.text,
                    ),
                    height: 48.h,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> _deletePhoto(PhotoItem photo) async {
    final confirmed = await AppConfirmDialog.show(
      title: "确认删除",
      message: "删除后无法恢复，确定要删除这张照片吗？",
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;
    await controller.deletePhoto(photo);
    Get.back();
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
