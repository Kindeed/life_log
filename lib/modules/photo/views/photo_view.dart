import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/views/project_gallery_view.dart';
import 'package:life_log/common/theme/app_colors.dart';

class PhotoView extends StatelessWidget {
  const PhotoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PhotoController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[400]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("项目记录"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadPhotos(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = controller.groupedPhotos;

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 64.sp,
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
                SizedBox(height: 16.h),
                Text(
                  "暂无记录，去拍一张吧！",
                  style: TextStyle(color: textSecondary, fontSize: 14.sp),
                ),
              ],
            ),
          );
        }

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            controller.onScroll(notification);
            return true;
          },
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.82,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final projectName = groups.keys.elementAt(index);
              final projectPhotos = groups[projectName]!;
              final latestPhoto = projectPhotos.first;

              return GestureDetector(
                onTap: () {
                  Get.to(() => ProjectGalleryView(projectName: projectName));
                },
                child: Container(
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
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(latestPhoto.filePath),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: isDark
                                    ? Colors.grey[850]
                                    : Colors.grey[100],
                                child: Icon(
                                  Icons.broken_image,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            // Photo Count Tag
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${projectPhotos.length} 张",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              projectName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "最近: ${latestPhoto.createdAt.toString().substring(5, 16)}",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(
        () => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: controller.isFabVisible.value
              ? Offset.zero
              : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: controller.isFabVisible.value ? 1 : 0,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              label: Text(
                "拍项目",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () => controller.captureWithSystemCamera(),
            ),
          ),
        ),
      ),
    );
  }
}
