import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_add_action_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_legacy_view_adapter.dart';
import 'package:life_log/features/evidence/presentation/evidence_summary_utils.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/expense/presentation/expense_record_editor_launcher.dart';
import 'package:life_log/features/project/application/delete_project_entry.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/export_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/presentation/photo_add_action_launcher.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/photo/presentation/photo_preview_view.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_floating_action_pill.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/features/photo/presentation/photo_local_ui.dart';

class ProjectGalleryView extends StatefulWidget {
  final String projectName;
  const ProjectGalleryView({super.key, required this.projectName});

  @override
  State<ProjectGalleryView> createState() => _ProjectGalleryViewState();
}

class _ProjectGalleryViewState extends State<ProjectGalleryView>
    with SingleTickerProviderStateMixin {
  late final ProjectCubit projectCubit;
  late final PhotoCubit photoCubit;
  late final EvidenceCubit evidenceCubit;
  late final ExpenseRecordCubit expenseCubit;
  final Set<int> _selectedPhotoIds = <int>{};
  bool _isMultiSelectMode = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    projectCubit = serviceLocator<ProjectCubit>()..start();
    photoCubit = serviceLocator<PhotoCubit>()..start();
    evidenceCubit = serviceLocator<EvidenceCubit>()..start();
    expenseCubit = serviceLocator<ExpenseRecordCubit>()..start();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    projectCubit.close();
    photoCubit.close();
    evidenceCubit.close();
    expenseCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return BlocBuilder<ProjectCubit, ProjectState>(
      bloc: projectCubit,
      builder: (context, projectState) {
        return BlocBuilder<PhotoCubit, PhotoState>(
          bloc: photoCubit,
          builder: (context, photoState) {
            return BlocBuilder<EvidenceCubit, EvidenceState>(
              bloc: evidenceCubit,
              builder: (context, evidenceState) {
                return PopScope<void>(
                  canPop: !_isMultiSelectMode,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && _isMultiSelectMode) {
                      _exitMultiSelectMode();
                    }
                  },
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(widget.projectName),
                      bottom: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(icon: Icon(Icons.dashboard_outlined), text: '概览'),
                          Tab(icon: Icon(Icons.timeline_rounded), text: '时间线'),
                          Tab(
                            icon: Icon(Icons.photo_library_rounded),
                            text: '照片',
                          ),
                          Tab(
                            icon: Icon(Icons.receipt_long_rounded),
                            text: '凭证',
                          ),
                          Tab(icon: Icon(Icons.payments_rounded), text: '支出'),
                        ],
                      ),
                      actions: [
                        if (_isMultiSelectMode)
                          Builder(
                            builder: (_) {
                              final projectPhotos = photoState
                                  .entriesForProject(widget.projectName);
                              if (projectPhotos.isEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _exitMultiSelectMode();
                                });
                                return const SizedBox.shrink();
                              }

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      final allSelected =
                                          _selectedPhotoIds.length ==
                                          projectPhotos.length;
                                      setState(() {
                                        if (allSelected) {
                                          _selectedPhotoIds.clear();
                                        } else {
                                          _selectedPhotoIds
                                            ..clear()
                                            ..addAll(
                                              projectPhotos.map(
                                                (photo) => photo.id,
                                              ),
                                            );
                                        }
                                      });
                                    },
                                    child: Text(
                                      _selectedPhotoIds.length ==
                                              projectPhotos.length
                                          ? "全不选"
                                          : "全选",
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _exitMultiSelectMode,
                                    child: const Text(
                                      "取消",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          Builder(
                            builder: (_) {
                              final currentProject = projectState.entryNamed(
                                widget.projectName,
                              );
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (currentProject != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      onPressed: _showDeleteProjectDialog,
                                      tooltip: "删除项目",
                                    ),
                                  if (_tabController.index == 2)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.checklist_rtl_rounded,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _isMultiSelectMode = true,
                                        );
                                      },
                                      tooltip: "选择模式",
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
                          bloc: expenseCubit,
                          builder: (context, expenseState) {
                            return _buildProjectOverview(
                              projectState,
                              photoState,
                              evidenceState,
                              expenseState,
                              textSecondary,
                              theme,
                            );
                          },
                        ),
                        BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
                          bloc: expenseCubit,
                          builder: (context, expenseState) {
                            return _buildProjectTimeline(
                              photoState,
                              evidenceState,
                              expenseState,
                              textSecondary,
                              theme,
                            );
                          },
                        ),
                        Builder(
                          builder: (_) {
                            final projectPhotos = photoState.entriesForProject(
                              widget.projectName,
                            );

                            if (projectPhotos.isEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _exitMultiSelectMode();
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
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8.w,
                                    mainAxisSpacing: 12.h,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: projectPhotos.length,
                              itemBuilder: (context, index) {
                                final photo = projectPhotos[index];
                                final isSelected = _selectedPhotoIds.contains(
                                  photo.id,
                                );
                                return GestureDetector(
                                  onTap: () {
                                    if (_isMultiSelectMode) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedPhotoIds.remove(photo.id);
                                        } else {
                                          _selectedPhotoIds.add(photo.id);
                                        }
                                      });
                                    } else {
                                      _openPhotoPreview(projectPhotos, index);
                                    }
                                  },
                                  onLongPress: () {
                                    if (!_isMultiSelectMode) {
                                      setState(() {
                                        _isMultiSelectMode = true;
                                        _selectedPhotoIds.add(photo.id);
                                      });
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(photo.filePath),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (ctx, err, stack) => Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            if (_isMultiSelectMode)
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
                                                    isSelected
                                                        ? Icons.check
                                                        : null,
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
                              },
                            );
                          },
                        ),
                        _buildEvidenceList(
                          evidenceState.entriesForProject(widget.projectName),
                          textSecondary,
                          theme,
                        ),
                        BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
                          bloc: expenseCubit,
                          builder: (context, expenseState) {
                            return _buildExpenseList(
                              expenseState.entriesForProject(
                                widget.projectName,
                              ),
                              textSecondary,
                              theme,
                            );
                          },
                        ),
                      ],
                    ),
                    bottomNavigationBar: !_isMultiSelectMode
                        ? const SizedBox.shrink()
                        : AppSafeBottomBar(
                            padding: EdgeInsets.fromLTRB(
                              20.w,
                              10.h,
                              20.w,
                              16.h,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPhotoIds.isEmpty
                                      ? "已进入选择模式"
                                      : "选择了 ${_selectedPhotoIds.length} 张",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textPrimary),
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton.secondary(
                                        onPressed: _selectedPhotoIds.isEmpty
                                            ? null
                                            : _deleteSelectedPhotos,
                                        icon: Icons.delete_outline,
                                        label: "删除",
                                        height: 42.h,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: AppButton.primary(
                                        onPressed: _selectedPhotoIds.isEmpty
                                            ? null
                                            : _exportSelectedPhotos,
                                        icon: Icons.ios_share,
                                        label: "导出",
                                        height: 42.h,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                    floatingActionButton: _isMultiSelectMode
                        ? const SizedBox.shrink()
                        : AppFloatingActionPill(
                            label: _addActionLabel,
                            icon: _addActionIcon,
                            color: Theme.of(context).colorScheme.primary,
                            visible: _tabController.index >= 2,
                            onPressed: _runCurrentAddAction,
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {
        if (_tabController.index != 2) {
          _isMultiSelectMode = false;
          _selectedPhotoIds.clear();
        }
      });
    }
  }

  String get _addActionLabel {
    switch (_tabController.index) {
      case 3:
        return "添加凭证";
      case 4:
        return "添加支出";
      case 2:
      default:
        return "添加照片";
    }
  }

  IconData get _addActionIcon {
    switch (_tabController.index) {
      case 3:
        return Icons.receipt_long_rounded;
      case 4:
        return Icons.payments_rounded;
      case 2:
      default:
        return Icons.add_photo_alternate_rounded;
    }
  }

  void _runCurrentAddAction() {
    switch (_tabController.index) {
      case 3:
        _showEvidenceAddActions();
        break;
      case 4:
        openExpenseRecordEditorPage(
          context,
          initialProjectName: widget.projectName,
          onSavedOrDeleted: expenseCubit.loadEntries,
        );
        break;
      case 2:
      default:
        _showAddPhotoActions();
        break;
    }
  }

  Future<void> _openPhotoPreview(List<PhotoEntry> photos, int initialIndex) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PhotoPreviewView(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  List<PhotoEntry> _selectedProjectPhotos() {
    final selectedIds = Set<int>.of(_selectedPhotoIds);
    return photoCubit.state
        .entriesForProject(widget.projectName)
        .where((photo) => selectedIds.contains(photo.id))
        .toList();
  }

  void _exitMultiSelectMode() {
    if (!_isMultiSelectMode && _selectedPhotoIds.isEmpty) return;
    setState(() {
      _isMultiSelectMode = false;
      _selectedPhotoIds.clear();
    });
  }

  Future<void> _deleteSelectedPhotos() async {
    final messenger = ScaffoldMessenger.of(context);
    final selectedPhotos = _selectedProjectPhotos();
    final confirmed = await confirmPhotoAction(
      context,
      title: "批量删除",
      message: "确定删除这 ${selectedPhotos.length} 张照片吗？删除后无法恢复。",
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;
    final photosToDelete = selectedPhotos;
    _exitMultiSelectMode();
    final result = await serviceLocator<DeletePhotoEntries>().call(
      photosToDelete,
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    await photoCubit.loadEntries();
  }

  Future<void> _exportSelectedPhotos() async {
    final photosToExport = _selectedProjectPhotos();
    if (photosToExport.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;
    if (!mounted) return;

    final result = await serviceLocator<ExportPhotoEntries>().call(
      photosToExport,
      selectedDirectory,
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    final successCount = result.valueOrNull ?? 0;
    messenger.showSnackBar(
      SnackBar(content: Text('成功导出 $successCount 张照片至 $selectedDirectory')),
    );
  }

  Future<void> _showDeleteProjectDialog() async {
    final ProjectEntry? project = projectCubit.state.entryNamed(
      widget.projectName,
    );
    if (project == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('项目不存在或已被删除')));
      return;
    }

    final projectPhotos = photoCubit.state.entriesForProject(
      widget.projectName,
    );
    final evidenceItems = evidenceCubit.state.entriesForProject(
      widget.projectName,
    );
    final expenseItems = expenseCubit.state.entriesForProject(
      widget.projectName,
    );
    final mediaCount = projectPhotos.length;
    final evidenceCount = evidenceItems.length;
    final expenseCount = expenseItems.length;
    final hasChildren = mediaCount + evidenceCount + expenseCount > 0;
    final message = hasChildren
        ? "删除项目「${widget.projectName}」后，会一并删除 $mediaCount 张照片、$evidenceCount 份凭证和 $expenseCount 条支出，且无法恢复。"
        : "删除项目「${widget.projectName}」后无法恢复。";

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmPhotoAction(
      context,
      title: "删除项目",
      message: message,
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;

    final result = await serviceLocator<DeleteProjectEntry>().call(project);
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    await projectCubit.loadEntries();
    await photoCubit.loadEntries();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildProjectOverview(
    ProjectState projectState,
    PhotoState photoState,
    EvidenceState evidenceState,
    ExpenseRecordState expenseState,
    Color textSecondary,
    ThemeData theme,
  ) {
    final project = projectState.entryNamed(widget.projectName);
    final projectPhotos = photoState.entriesForProject(widget.projectName);
    final evidenceItems = evidenceState.entriesForProject(widget.projectName);
    final expenseItems = expenseState.entriesForProject(widget.projectName);
    final pendingEvidenceAmount = evidenceItems
        .where((item) => item.status != EvidenceEntryStatus.reimbursed)
        .fold<double>(0, (sum, item) => sum + (item.amount ?? 0));
    final expenseTotal = expenseItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  project?.label ?? '未归档',
                  style: TextStyle(color: textSecondary),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.3,
          children: [
            _ProjectMetricTile(
              icon: Icons.photo_library_rounded,
              label: '照片',
              value: projectPhotos.length.toString(),
            ),
            _ProjectMetricTile(
              icon: Icons.receipt_long_rounded,
              label: '凭证',
              value: evidenceItems.length.toString(),
            ),
            _ProjectMetricTile(
              icon: Icons.payments_rounded,
              label: '支出',
              value: formatMoney(expenseTotal),
            ),
            _ProjectMetricTile(
              icon: Icons.assignment_late_outlined,
              label: '待报销',
              value: formatMoney(pendingEvidenceAmount),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: const Text('最近活动'),
            subtitle: Text(
              _latestProjectActivity(
                projectPhotos,
                evidenceItems,
                expenseItems,
              ),
              style: TextStyle(color: textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectTimeline(
    PhotoState photoState,
    EvidenceState evidenceState,
    ExpenseRecordState expenseState,
    Color textSecondary,
    ThemeData theme,
  ) {
    final items = <_ProjectTimelineItem>[
      ...photoState
          .entriesForProject(widget.projectName)
          .map(
            (entry) => _ProjectTimelineItem(
              date: entry.createdAt,
              type: '照片',
              title: entry.description?.trim().isNotEmpty == true
                  ? entry.description!.trim()
                  : entry.fileName,
              subtitle: entry.deviceName ?? '项目照片',
              icon: Icons.photo_library_rounded,
            ),
          ),
      ...evidenceState
          .entriesForProject(widget.projectName)
          .map(
            (entry) => _ProjectTimelineItem(
              date: entry.evidenceDate,
              type: '凭证',
              title: entry.merchant?.trim().isNotEmpty == true
                  ? entry.merchant!.trim()
                  : entry.category.label,
              subtitle:
                  '${entry.status.label} · ${formatMoney(entry.amount ?? 0)}',
              icon: Icons.receipt_long_rounded,
            ),
          ),
      ...expenseState
          .entriesForProject(widget.projectName)
          .map(
            (entry) => _ProjectTimelineItem(
              date: entry.expenseDate,
              type: '支出',
              title: entry.merchant?.trim().isNotEmpty == true
                  ? entry.merchant!.trim()
                  : entry.category.label,
              subtitle:
                  '${entry.category.label} · ${formatMoney(entry.amount)}',
              icon: Icons.payments_rounded,
            ),
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return Center(
        child: Text('此项目暂无活动', style: TextStyle(color: textSecondary)),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(12.w),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: theme.cardColor,
          leading: Icon(item.icon),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${formatDateYmd(item.date)} · ${item.type} · ${item.subtitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Widget _buildEvidenceList(
    List<EvidenceEntry> items,
    Color textSecondary,
    ThemeData theme,
  ) {
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
        final legacyItem = legacyEvidenceFromEntry(item);
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: theme.cardColor,
          leading: const Icon(Icons.receipt_long_rounded),
          title: Text(
            evidenceDisplayTitle(legacyItem),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            evidenceDisplaySubtitle(legacyItem),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text('¥${(item.amount ?? 0).toStringAsFixed(2)}'),
          onTap: () => showEvidenceDetailSheet(context, legacyItem),
        );
      },
    );
  }

  Widget _buildExpenseList(
    List<ExpenseRecordEntry> records,
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
          onTap: () => openExpenseRecordEditorPage(
            context,
            entry: record,
            onSavedOrDeleted: expenseCubit.loadEntries,
          ),
        );
      },
    );
  }

  void _showAddPhotoActions() {
    showPhotoActionSheet(
      context,
      title: "添加照片",
      actions: [
        PhotoActionSheetItem(
          icon: Icons.camera_alt_rounded,
          title: "拍摄照片",
          onTap: () {
            unawaited(
              capturePhotoWithSystemCamera(
                context,
                initialProject: widget.projectName,
                onSaved: photoCubit.loadEntries,
              ),
            );
          },
        ),
        PhotoActionSheetItem(
          icon: Icons.photo_library_rounded,
          title: "从相册导入",
          subtitle: "导入后请求删除系统相册原图",
          onTap: () {
            unawaited(
              importPhotoFromGallery(
                context,
                initialProject: widget.projectName,
                onSaved: photoCubit.loadEntries,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showEvidenceAddActions() {
    showEvidenceAddActions(
      context,
      initialProject: widget.projectName,
      title: "添加凭证",
      manualSubtitle: "没有图片时再补充文字",
    );
  }
}

class _ProjectMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProjectMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTimelineItem {
  final DateTime date;
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ProjectTimelineItem({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

String _latestProjectActivity(
  List<PhotoEntry> photos,
  List<EvidenceEntry> evidences,
  List<ExpenseRecordEntry> expenses,
) {
  final dates = <DateTime>[
    ...photos.map((entry) => entry.createdAt),
    ...evidences.map((entry) => entry.evidenceDate),
    ...expenses.map((entry) => entry.expenseDate),
  ]..sort((a, b) => b.compareTo(a));
  if (dates.isEmpty) return '暂无照片、凭证或支出';
  return formatDateYmd(dates.first);
}
