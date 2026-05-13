import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/modules/evidence/evidence_controller.dart';
import 'package:life_log/modules/evidence/evidence_model.dart';
import 'package:life_log/modules/expense/expense_record_controller.dart';
import 'package:life_log/modules/expense/expense_record_model.dart';
import 'package:life_log/modules/expense/views/expense_record_edit_view.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';
import 'package:life_log/modules/photo/views/photo_preview_view.dart';
import 'package:life_log/modules/photo/views/create_project_sheet.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/widgets/app_action_sheet.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_confirm_dialog.dart';
import 'package:life_log/common/widgets/app_floating_action_pill.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/modules/project/project_controller.dart';
import 'package:life_log/modules/project/project_model.dart';

class ProjectGalleryView extends StatefulWidget {
  final String projectName;
  const ProjectGalleryView({super.key, required this.projectName});

  @override
  State<ProjectGalleryView> createState() => _ProjectGalleryViewState();
}

class _ProjectGalleryViewState extends State<ProjectGalleryView> {
  final PhotoController controller = Get.find<PhotoController>();
  final EvidenceController evidenceController = Get.find<EvidenceController>();
  final ExpenseRecordController expenseController =
      Get.find<ExpenseRecordController>();
  final ProjectController projectController = Get.find<ProjectController>();
  final RxList<PhotoItem> selectedPhotos = <PhotoItem>[].obs;
  final RxBool isMultiSelectMode = false.obs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.projectName),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.photo_library_rounded), text: '照片'),
              Tab(icon: Icon(Icons.receipt_long_rounded), text: '凭证'),
              Tab(icon: Icon(Icons.payments_rounded), text: '支出'),
            ],
          ),
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
                final currentProject = _currentProject();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentProject != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: _showDeleteProjectDialog,
                        tooltip: "删除项目",
                      ),
                    IconButton(
                      icon: const Icon(Icons.checklist_rtl_rounded),
                      onPressed: () => isMultiSelectMode.value = true,
                      tooltip: "选择模式",
                    ),
                  ],
                );
              }
            }),
          ],
        ),
        body: TabBarView(
          children: [
            Obx(() {
              final projectPhotos =
                  controller.groupedPhotos[widget.projectName] ?? [];

              if (projectPhotos.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  selectedPhotos.clear();
                  isMultiSelectMode.value = false;
                });
                return Center(
                  child: Text(
                    "此项目下暂无照片",
                    style: TextStyle(color: textSecondary),
                  ),
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
                          Get.to(
                            () => PhotoPreviewView(
                              photos: projectPhotos,
                              initialIndex: index,
                            ),
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
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
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
            Obx(() => _buildEvidenceList(textSecondary, theme)),
            Obx(() {
              final records =
                  expenseController.records
                      .where(
                        (record) => record.projectName == widget.projectName,
                      )
                      .toList()
                    ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
              return _buildExpenseList(records, textSecondary, theme);
            }),
          ],
        ),
        bottomNavigationBar: Obx(() {
          if (!isMultiSelectMode.value) {
            return const SizedBox.shrink();
          }
          return AppSafeBottomBar(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedPhotos.isEmpty
                        ? "已进入选择模式"
                        : "选择了 ${selectedPhotos.length} 张",
                    style: TextStyle(color: textPrimary),
                  ),
                ),
                AppButton.secondary(
                  onPressed: selectedPhotos.isEmpty
                      ? null
                      : _deleteSelectedPhotos,
                  icon: Icons.delete_outline,
                  label: "删除",
                  height: 42.h,
                ),
                const SizedBox(width: 8),
                AppButton.primary(
                  onPressed: selectedPhotos.isEmpty
                      ? null
                      : () => controller.exportPhotos(selectedPhotos.toList()),
                  icon: Icons.ios_share,
                  label: "导出",
                  height: 42.h,
                ),
                const SizedBox(width: 8),
                AppButton.text(
                  onPressed: () {
                    isMultiSelectMode.value = false;
                    selectedPhotos.clear();
                  },
                  icon: Icons.close_rounded,
                  label: "完成",
                  height: 42.h,
                ),
              ],
            ),
          );
        }),
        floatingActionButton: Obx(() {
          if (isMultiSelectMode.value) return const SizedBox.shrink();
          return AppFloatingActionPill(
            label: "添加",
            icon: Icons.add_rounded,
            color: Theme.of(context).colorScheme.primary,
            visible: true,
            onPressed: () => _showProjectAddActions(),
          );
        }),
      ),
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

  Future<void> _showDeleteProjectDialog() async {
    final project = _currentProject();
    if (project == null) {
      Get.snackbar('删除失败', '项目不存在或已被删除');
      return;
    }

    final projectPhotos = controller.groupedPhotos[widget.projectName] ?? [];
    final evidenceItems =
        evidenceController.groupedEvidence[widget.projectName] ?? [];
    final expenseItems = expenseController.records
        .where((record) => record.projectName == widget.projectName)
        .toList();
    final mediaCount = projectPhotos.length;
    final evidenceCount = evidenceItems.length;
    final expenseCount = expenseItems.length;
    final hasChildren = mediaCount + evidenceCount + expenseCount > 0;
    final message = hasChildren
        ? "删除项目「${widget.projectName}」后，会一并删除 $mediaCount 张照片、$evidenceCount 份凭证和 $expenseCount 条支出，且无法恢复。"
        : "删除项目「${widget.projectName}」后无法恢复。";

    final confirmed = await AppConfirmDialog.show(
      title: "删除项目",
      message: message,
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;

    await projectController.deleteProject(project);
    if (mounted) {
      Get.back();
    }
  }

  Project? _currentProject() {
    for (final item in projectController.projects) {
      if (item.name == widget.projectName) {
        return item;
      }
    }
    return null;
  }

  Widget _buildEvidenceList(Color textSecondary, ThemeData theme) {
    final items =
        evidenceController.groupedEvidence[widget.projectName] ??
        <ExpenseEvidence>[];
    if (items.isEmpty) {
      return Center(
        child: Text('此项目下暂无凭证', style: TextStyle(color: textSecondary)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(12.w),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item.merchant?.trim().isNotEmpty == true
            ? item.merchant!
            : item.category.label;
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: theme.cardColor,
          leading: const Icon(Icons.receipt_long_rounded),
          title: Text(title),
          subtitle: Text(formatDateYmd(item.evidenceDate)),
          trailing: Text('¥${(item.amount ?? 0).toStringAsFixed(2)}'),
          onTap: () => evidenceController.editEvidence(item),
        );
      },
    );
  }

  Widget _buildExpenseList(
    List<ExpenseRecord> records,
    Color textSecondary,
    ThemeData theme,
  ) {
    if (records.isEmpty) {
      return Center(
        child: Text('此项目下暂无支出', style: TextStyle(color: textSecondary)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(12.w),
      itemCount: records.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final record = records[index];
        final title = record.merchant?.trim().isNotEmpty == true
            ? record.merchant!.trim()
            : record.category.label;
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: theme.cardColor,
          leading: const Icon(Icons.payments_rounded),
          title: Text(title),
          subtitle: Text(
            '${formatDateYmd(record.expenseDate)} · ${record.category.label}',
          ),
          trailing: Text(formatMoney(record.amount)),
          onTap: () => Get.to(() => ExpenseRecordEditView(record: record)),
        );
      },
    );
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

  void _showProjectAddActions() {
    AppActionSheet.show(
      title: "添加到 ${widget.projectName}",
      actions: [
        AppActionSheetItem(
          icon: Icons.add_photo_alternate_rounded,
          title: "照片",
          onTap: _showAddPhotoActions,
        ),
        AppActionSheetItem(
          icon: Icons.receipt_long_rounded,
          title: "凭证",
          onTap: _showEvidenceAddActions,
        ),
        AppActionSheetItem(
          icon: Icons.payments_rounded,
          title: "项目支出",
          onTap: () => Get.to(
            () => ExpenseRecordEditView(initialProjectName: widget.projectName),
          ),
        ),
        AppActionSheetItem(
          icon: Icons.create_new_folder_rounded,
          title: "新项目",
          subtitle: "先建立项目，再添加资料",
          onTap: () => showCreateProjectSheet(
            onCreated: (project) async {
              await Get.to(() => ProjectGalleryView(projectName: project.name));
            },
          ),
        ),
      ],
    );
  }

  void _showEvidenceAddActions() {
    AppActionSheet.show(
      title: "添加凭证",
      actions: [
        AppActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: "拍摄凭证",
          onTap: () => evidenceController.captureEvidence(
            initialProject: widget.projectName,
          ),
        ),
        AppActionSheetItem(
          icon: Icons.photo_library_rounded,
          title: "从相册导入",
          onTap: () => evidenceController.importEvidence(
            initialProject: widget.projectName,
          ),
        ),
        AppActionSheetItem(
          icon: Icons.upload_file_rounded,
          title: "导入文件",
          subtitle: "发票、PDF 或截图文件",
          onTap: () => evidenceController.importEvidenceFile(
            initialProject: widget.projectName,
          ),
        ),
        AppActionSheetItem(
          icon: Icons.edit_note_rounded,
          title: "手动记录",
          subtitle: "没有图片时再补充文字",
          onTap: () => evidenceController.createManualEvidence(
            initialProject: widget.projectName,
          ),
        ),
      ],
    );
  }
}
