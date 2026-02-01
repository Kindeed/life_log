import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
          return const Center(child: Text("此项目下暂无照片"));
        }

        return GridView.builder(
          padding: EdgeInsets.all(12.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 12.h, // Increased spacing for text
            childAspectRatio: 0.75, // Adjusted for text space
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
                    _showPhotoDetail(photo);
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
                              errorBuilder: (ctx, err, stack) =>
                                  const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                          if (isMultiSelectMode.value)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
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
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                      ),
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Text("选择了 ${selectedPhotos.length} 张"),
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
                      Get.back(); // close dialog
                      // Store list copy because selectedPhotos will be cleared
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
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
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
                  backgroundColor: Colors.blue,
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
          onPressed: () => controller.captureWithSystemCamera(
            initialProject: widget.projectName,
          ),
          child: const Icon(Icons.camera_alt),
        );
      }),
    );
  }

  void _showPhotoDetail(PhotoItem photo) {
    final TextEditingController descEditController = TextEditingController(
      text: photo.description,
    );

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "照片详情",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
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
              _buildInfoRow("项目名称", photo.projectName ?? "Default"),
              _buildInfoRow("设备名称", photo.deviceName ?? "Unknown"),
              _buildInfoRow(
                "拍摄时间",
                photo.createdAt.toString().substring(0, 19),
              ),
              _buildInfoRow("保存路径", photo.filePath),
              SizedBox(height: 16.h),
              const Text("补充说明", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              TextField(
                controller: descEditController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "添加补充说明...",
                  filled: true,
                  fillColor: Colors.grey[100],
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
                                  Get.back(); // Check dialog
                                  await controller.deletePhoto(photo);
                                },
                                child: const Text(
                                  "删除",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      label: const Text(
                        "删除",
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
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
                        backgroundColor: Colors.blue,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
