import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/theme/app_colors.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_safe_bottom_bar.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/presentation/evidence_add_action_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/evidence/presentation/evidence_detail_launcher.dart';
import 'package:life_log/features/evidence/presentation/evidence_legacy_view_adapter.dart';
import 'package:life_log/features/evidence/presentation/evidence_summary_utils.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';
import 'package:life_log/features/expense/data/legacy_expense_record_repository_adapter.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/expense/presentation/expense_record_editor_launcher.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/export_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/presentation/photo_add_action_launcher.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/photo/presentation/photo_local_ui.dart';
import 'package:life_log/features/photo/presentation/photo_preview_view.dart';
import 'package:life_log/features/project/application/delete_project_entry.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

class ProjectDetailView extends StatefulWidget {
  final String projectName;
  final int? projectId;

  // 可选依赖，便于单测与解耦
  final ProjectCubit? projectCubit;
  final PhotoCubit? photoCubit;
  final EvidenceCubit? evidenceCubit;
  final ExpenseRecordCubit? expenseCubit;
  final ExpenseRecordRepository? expenseRecordRepository;
  final LoadProjectWorkLogTrips? loadProjectWorkLogTrips;
  final DeleteProjectEntry? deleteProjectEntry;
  final DeletePhotoEntries? deletePhotoEntries;
  final ExportPhotoEntries? exportPhotoEntries;

  const ProjectDetailView({
    super.key,
    required this.projectName,
    this.projectId,
    this.projectCubit,
    this.photoCubit,
    this.evidenceCubit,
    this.expenseCubit,
    this.expenseRecordRepository,
    this.loadProjectWorkLogTrips,
    this.deleteProjectEntry,
    this.deletePhotoEntries,
    this.exportPhotoEntries,
  });

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView>
    with SingleTickerProviderStateMixin {
  late final ProjectCubit _projectCubit;
  late final PhotoCubit _photoCubit;
  late final EvidenceCubit _evidenceCubit;
  late final ExpenseRecordCubit _expenseCubit;
  late final ExpenseRecordRepository? _expenseRepository;
  late final LoadProjectWorkLogTrips? _loadTrips;
  late final DeleteProjectEntry? _deleteProject;

  bool _ownsProjectCubit = false;
  bool _ownsPhotoCubit = false;
  bool _ownsEvidenceCubit = false;
  bool _ownsExpenseCubit = false;

  late final TabController _tabController;
  List<ExpenseRecord> _directProjectExpenses = const <ExpenseRecord>[];
  List<WorkLogEntry> _projectTrips = const <WorkLogEntry>[];
  String _selectedTimelineFilter = '全部';
  bool _isMultiSelectMode = false;
  final Set<int> _selectedPhotoIds = <int>{};

  @override
  void initState() {
    super.initState();
    if (widget.projectCubit != null) {
      _projectCubit = widget.projectCubit!;
    } else {
      _projectCubit = serviceLocator<ProjectCubit>()..start();
      _ownsProjectCubit = true;
    }

    if (widget.photoCubit != null) {
      _photoCubit = widget.photoCubit!;
    } else {
      _photoCubit = serviceLocator<PhotoCubit>()..start();
      _ownsPhotoCubit = true;
    }

    if (widget.evidenceCubit != null) {
      _evidenceCubit = widget.evidenceCubit!;
    } else {
      _evidenceCubit = serviceLocator<EvidenceCubit>()..start();
      _ownsEvidenceCubit = true;
    }

    if (widget.expenseCubit != null) {
      _expenseCubit = widget.expenseCubit!;
    } else {
      _expenseCubit = serviceLocator<ExpenseRecordCubit>()..start();
      _ownsExpenseCubit = true;
    }

    _expenseRepository =
        widget.expenseRecordRepository ??
        (serviceLocator.isRegistered<ExpenseRecordRepository>()
            ? serviceLocator<ExpenseRecordRepository>()
            : null);
    _loadTrips =
        widget.loadProjectWorkLogTrips ??
        (serviceLocator.isRegistered<LoadProjectWorkLogTrips>()
            ? serviceLocator<LoadProjectWorkLogTrips>()
            : null);
    _deleteProject =
        widget.deleteProjectEntry ??
        (serviceLocator.isRegistered<DeleteProjectEntry>()
            ? serviceLocator<DeleteProjectEntry>()
            : null);

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);

    unawaited(_loadExpenses());
    unawaited(_loadTripsData());
  }

  void _handleTabChanged() {
    if (!mounted) return;
    if (_tabController.index != 1 && _isMultiSelectMode) {
      _exitMultiSelectMode();
    }
    setState(() {});
  }

  Future<void> _loadExpenses() async {
    final repo = _expenseRepository;
    if (repo == null) return;
    try {
      final records = widget.projectId != null
          ? await repo.getExpenseRecordsByProjectId(widget.projectId!)
          : await repo.getExpenseRecordsByProject(widget.projectName);
      if (mounted) {
        setState(() {
          _directProjectExpenses = records;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTripsData() async {
    final loader = _loadTrips;
    if (loader == null) return;
    final result = await loader(widget.projectName, includeUnlinked: true);
    result.when(
      success: (trips) {
        if (mounted) {
          setState(() {
            _projectTrips = entriesForProjectTrips(trips, widget.projectName);
          });
        }
      },
      failure: (_) {},
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    if (_ownsProjectCubit) _projectCubit.close();
    if (_ownsPhotoCubit) _photoCubit.close();
    if (_ownsEvidenceCubit) _evidenceCubit.close();
    if (_ownsExpenseCubit) _expenseCubit.close();
    super.dispose();
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedPhotoIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return BlocBuilder<ProjectCubit, ProjectState>(
      bloc: _projectCubit,
      builder: (context, projectState) {
        final project =
            projectState.entryNamed(widget.projectName) ??
            (widget.projectId != null
                ? projectState.entries
                      .where((e) => e.id == widget.projectId)
                      .firstOrNull
                : null);

        return BlocBuilder<PhotoCubit, PhotoState>(
          bloc: _photoCubit,
          builder: (context, photoState) {
            return BlocBuilder<EvidenceCubit, EvidenceState>(
              bloc: _evidenceCubit,
              builder: (context, evidenceState) {
                return BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
                  bloc: _expenseCubit,
                  builder: (context, expenseState) {
                    final projectPhotos = photoState.entriesForProject(
                      widget.projectName,
                    );
                    final projectEvidence = evidenceState.entriesForProject(
                      widget.projectName,
                    );

                    return PopScope<void>(
                      canPop: !_isMultiSelectMode,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop && _isMultiSelectMode) {
                          _exitMultiSelectMode();
                        }
                      },
                      child: Scaffold(
                        appBar: _buildAppBar(
                          context,
                          theme,
                          project,
                          projectPhotos,
                        ),
                        body: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTimelineTab(
                              theme,
                              textSecondary,
                              projectPhotos,
                              projectEvidence,
                            ),
                            _buildPhotosTab(
                              theme,
                              textSecondary,
                              projectPhotos,
                            ),
                            _buildExpensesTab(
                              theme,
                              textPrimary,
                              textSecondary,
                              projectEvidence,
                            ),
                          ],
                        ),
                        bottomNavigationBar: _isMultiSelectMode
                            ? _buildMultiSelectBottomBar(
                                textPrimary,
                                projectPhotos,
                              )
                            : null,
                        floatingActionButtonLocation:
                            FloatingActionButtonLocation.centerFloat,
                        floatingActionButton: _isMultiSelectMode
                            ? null
                            : _buildActionCapsule(theme),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ProjectEntry? project,
    List<PhotoEntry> projectPhotos,
  ) {
    return AppBar(
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.projectName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project?.status == ProjectEntryStatus.archived) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '已归档',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                  ),
                ),
              ],
            ],
          ),
          if (project != null && project.stageNames.isNotEmpty) ...[
            SizedBox(height: 2.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final stage in project.stageNames)
                    Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          stage,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_isMultiSelectMode) ...[
          TextButton(
            onPressed: () {
              final allSelected =
                  _selectedPhotoIds.length == projectPhotos.length;
              setState(() {
                if (allSelected) {
                  _selectedPhotoIds.clear();
                } else {
                  _selectedPhotoIds
                    ..clear()
                    ..addAll(projectPhotos.map((photo) => photo.id));
                }
              });
            },
            child: Text(
              _selectedPhotoIds.length == projectPhotos.length ? "全不选" : "全选",
            ),
          ),
          TextButton(
            onPressed: _exitMultiSelectMode,
            child: const Text("取消", style: TextStyle(color: Colors.red)),
          ),
        ] else ...[
          if (_tabController.index == 1 && projectPhotos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist_rtl_rounded),
              tooltip: "批量选择",
              onPressed: () => setState(() => _isMultiSelectMode = true),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: '项目选项',
            onSelected: (action) {
              if (project == null) return;
              switch (action) {
                case 'stages':
                  _showProjectStagesDialog(project);
                  break;
                case 'archive':
                  _toggleArchiveProject(project);
                  break;
                case 'delete':
                  _showDeleteProjectDialog(project);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stages',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('节点管理'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      project?.status == ProjectEntryStatus.archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      project?.status == ProjectEntryStatus.archived
                          ? '取消归档'
                          : '归档项目',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('删除项目', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.timeline_rounded), text: '动态'),
          Tab(icon: Icon(Icons.photo_library_rounded), text: '照片'),
          Tab(icon: Icon(Icons.payments_rounded), text: '费用'),
        ],
      ),
    );
  }

  Widget _buildActionCapsule(ThemeData theme) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(24.r),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CapsuleButton(
              icon: Icons.camera_alt_rounded,
              label: '拍照片',
              onTap: _showAddPhotoActions,
            ),
            Container(
              height: 14.h,
              width: 1,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              color: Colors.white24,
            ),
            _CapsuleButton(
              icon: Icons.payments_rounded,
              label: '记费用',
              onTap: _openAddExpense,
            ),
            Container(
              height: 14.h,
              width: 1,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              color: Colors.white24,
            ),
            _CapsuleButton(
              icon: Icons.receipt_long_rounded,
              label: '加凭证',
              onTap: _showEvidenceAddActions,
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: 动态/时间线 ---
  Widget _buildTimelineTab(
    ThemeData theme,
    Color textSecondary,
    List<PhotoEntry> projectPhotos,
    List<EvidenceEntry> projectEvidence,
  ) {
    final timelineItems = <_DetailTimelineItem>[
      ...projectPhotos.map(
        (photo) => _DetailTimelineItem(
          date: photo.capturedAt ?? photo.createdAt,
          type: '照片',
          title: photo.description?.trim().isNotEmpty == true
              ? photo.description!.trim()
              : photo.fileName,
          subtitle: photo.deviceName ?? '项目照片',
          icon: Icons.photo_library_rounded,
          iconColor: Colors.blue,
          rawItem: photo,
        ),
      ),
      ..._directProjectExpenses.map((expense) {
        final title = expense.merchant?.trim().isNotEmpty == true
            ? expense.merchant!.trim()
            : expense.category.label;
        final subtitleParts = [
          expense.category.label,
          if (expense.projectStageName?.trim().isNotEmpty == true)
            expense.projectStageName!.trim(),
          formatMoney(expense.amount),
        ];
        return _DetailTimelineItem(
          date: expense.expenseDate,
          type: '费用',
          title: title,
          subtitle: subtitleParts.join(' · '),
          amount: expense.amount,
          icon: Icons.payments_rounded,
          iconColor: Colors.green,
          rawItem: expense,
        );
      }),
      ...projectEvidence.map((evidence) {
        final legacy = legacyEvidenceFromEntry(evidence);
        return _DetailTimelineItem(
          date: evidence.evidenceDate,
          type: '凭证',
          title: evidenceDisplayTitle(legacy),
          subtitle: [
            evidenceDisplaySubtitle(legacy),
            if (evidence.projectStageName?.trim().isNotEmpty == true)
              evidence.projectStageName!.trim(),
            evidence.status.label,
            if ((evidence.amount ?? 0) > 0) formatMoney(evidence.amount ?? 0),
          ].join(' · '),
          amount: evidence.amount,
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.teal,
          rawItem: evidence,
        );
      }),
      ..._projectTrips.map(
        (trip) => _DetailTimelineItem(
          date: trip.date,
          type: '出差',
          title: trip.location?.trim().isNotEmpty == true
              ? trip.location!.trim()
              : '出差记录',
          subtitle: [
            if (trip.transport?.trim().isNotEmpty == true)
              trip.transport!.trim(),
            if (trip.projectStageName?.trim().isNotEmpty == true)
              trip.projectStageName!.trim(),
            if ((trip.expenses ?? 0) > 0) formatMoney(trip.expenses ?? 0),
            trip.isReimbursed ? '已报销' : '未报销',
          ].join(' · '),
          amount: trip.expenses,
          icon: Icons.luggage_rounded,
          iconColor: const Color(0xFFFF8F00),
          rawItem: trip,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final filteredItems = timelineItems.where((item) {
      if (_selectedTimelineFilter == '全部') return true;
      if (_selectedTimelineFilter == '费用') {
        return item.type == '费用' || item.type == '凭证';
      }
      return item.type == _selectedTimelineFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in ['全部', '照片', '费用', '出差']) ...[
                  FilterChip(
                    label: Text(filter),
                    selected: _selectedTimelineFilter == filter,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTimelineFilter = filter);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  SizedBox(width: 8.w),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    '此分类下暂无活动记录',
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 80.h),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.r),
                        onTap: () =>
                            _handleTimelineItemTap(item, projectPhotos),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: item.iconColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 20.sp,
                                  color: item.iconColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                            vertical: 1.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item.iconColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              3.r,
                                            ),
                                          ),
                                          child: Text(
                                            item.type,
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              color: item.iconColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          formatDateYmd(item.date),
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      item.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _handleTimelineItemTap(
    _DetailTimelineItem item,
    List<PhotoEntry> projectPhotos,
  ) {
    if (item.type == '照片' && item.rawItem is PhotoEntry) {
      final photo = item.rawItem as PhotoEntry;
      final idx = projectPhotos.indexWhere((p) => p.id == photo.id);
      _openPhotoPreview(projectPhotos, idx >= 0 ? idx : 0);
    } else if (item.type == '费用' && item.rawItem is ExpenseRecord) {
      final expense = item.rawItem as ExpenseRecord;
      _openExpenseEditor(record: expense);
    } else if (item.type == '凭证' && item.rawItem is EvidenceEntry) {
      final evidence = item.rawItem as EvidenceEntry;
      showEvidenceDetailSheet(context, legacyEvidenceFromEntry(evidence));
    }
  }

  // --- Tab 2: 照片网格与批量操作 ---
  Widget _buildPhotosTab(
    ThemeData theme,
    Color textSecondary,
    List<PhotoEntry> projectPhotos,
  ) {
    if (projectPhotos.isEmpty) {
      return Center(
        child: Text("此项目下暂无照片", style: TextStyle(color: textSecondary)),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 80.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 0.8,
      ),
      itemCount: projectPhotos.length,
      itemBuilder: (context, index) {
        final photo = projectPhotos[index];
        final isSelected = _selectedPhotoIds.contains(photo.id);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        File(photo.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (_isMultiSelectMode)
                      Positioned(
                        top: 4.h,
                        right: 4.w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.black26,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Icon(
                            isSelected ? Icons.check : null,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                photo.description?.trim().isNotEmpty == true
                    ? photo.description!.trim()
                    : "无标题",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.sp, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectBottomBar(
    Color textPrimary,
    List<PhotoEntry> projectPhotos,
  ) {
    return AppSafeBottomBar(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPhotoIds.isEmpty
                ? "已进入选择模式"
                : "选择了 ${_selectedPhotoIds.length} 张照片",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: _selectedPhotoIds.isEmpty
                      ? null
                      : () => _deleteSelectedPhotos(projectPhotos),
                  icon: Icons.delete_outline_rounded,
                  label: "删除",
                  height: 40.h,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: AppButton.primary(
                  onPressed: _selectedPhotoIds.isEmpty
                      ? null
                      : () => _exportSelectedPhotos(projectPhotos),
                  icon: Icons.ios_share_rounded,
                  label: "导出",
                  height: 40.h,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 3: 费用与凭证展示 ---
  Widget _buildExpensesTab(
    ThemeData theme,
    Color textPrimary,
    Color textSecondary,
    List<EvidenceEntry> projectEvidence,
  ) {
    final totalExpense = _directProjectExpenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final reimbursedTripIds = _projectTrips
        .where((t) => t.isReimbursed)
        .map((t) => t.id)
        .toSet();

    double reimbursedTotal = 0.0;
    for (final exp in _directProjectExpenses) {
      if (exp.tripWorkLogId != null &&
          reimbursedTripIds.contains(exp.tripWorkLogId)) {
        reimbursedTotal += exp.amount;
      }
    }
    for (final ev in projectEvidence) {
      if (ev.status == EvidenceEntryStatus.reimbursed) {
        reimbursedTotal += (ev.amount ?? 0);
      }
    }

    final pendingTotal = (totalExpense - reimbursedTotal).clamp(
      0.0,
      double.infinity,
    );

    return Column(
      children: [
        // 紧凑统计卡片
        Container(
          margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ExpenseStatColumn(
                label: '项目支出',
                amount: totalExpense,
                color: textPrimary,
              ),
              Container(
                height: 24.h,
                width: 1,
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              _ExpenseStatColumn(
                label: '待报销',
                amount: pendingTotal,
                color: Colors.orange,
              ),
              Container(
                height: 24.h,
                width: 1,
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              _ExpenseStatColumn(
                label: '已报销',
                amount: reimbursedTotal,
                color: Colors.green,
              ),
            ],
          ),
        ),
        Expanded(
          child: _directProjectExpenses.isEmpty && projectEvidence.isEmpty
              ? Center(
                  child: Text(
                    '此项目下暂无费用或凭证记录',
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 80.h),
                  children: [
                    if (_directProjectExpenses.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 4.h,
                        ),
                        child: Text(
                          '项目费用明细 (${_directProjectExpenses.length})',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      for (final expense in _directProjectExpenses) ...[
                        Builder(
                          builder: (context) {
                            final isReimbursed =
                                expense.tripWorkLogId != null &&
                                reimbursedTripIds.contains(
                                  expense.tripWorkLogId,
                                );
                            final title =
                                expense.merchant?.trim().isNotEmpty == true
                                ? expense.merchant!.trim()
                                : expense.category.label;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 3.h),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                side: BorderSide(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 0,
                                ),
                                leading: const Icon(
                                  Icons.payments_rounded,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        [
                                          '${formatDateYmd(expense.expenseDate)} · ${expense.category.label}',
                                          if (expense.projectStageName
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true)
                                            expense.projectStageName!.trim(),
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 13,
                                      color: Colors.blueGrey,
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatMoney(expense.amount),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isReimbursed
                                            ? Colors.green.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.orange.withValues(
                                                alpha: 0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          3.r,
                                        ),
                                      ),
                                      child: Text(
                                        isReimbursed ? '已报销' : '待报销',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isReimbursed
                                              ? Colors.green[800]
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _openExpenseEditor(record: expense),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                    if (projectEvidence.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 4.h,
                        ),
                        child: Text(
                          '凭证附件与报销 (${projectEvidence.length})',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      for (final evidence in projectEvidence) ...[
                        Builder(
                          builder: (context) {
                            final legacy = legacyEvidenceFromEntry(evidence);
                            final isReimbursed =
                                evidence.status ==
                                EvidenceEntryStatus.reimbursed;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 3.h),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                side: BorderSide(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 0,
                                ),
                                leading: const Icon(
                                  Icons.receipt_rounded,
                                  color: Colors.teal,
                                ),
                                title: Text(
                                  evidenceDisplayTitle(legacy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    evidenceDisplaySubtitle(legacy),
                                    if (evidence.projectStageName
                                            ?.trim()
                                            .isNotEmpty ==
                                        true)
                                      evidence.projectStageName!.trim(),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: textSecondary,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatMoney(evidence.amount ?? 0),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isReimbursed
                                            ? Colors.green.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.orange.withValues(
                                                alpha: 0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          3.r,
                                        ),
                                      ),
                                      child: Text(
                                        evidence.status.label,
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isReimbursed
                                              ? Colors.green[800]
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    showEvidenceDetailSheet(context, legacy),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  // --- 交互动作与弹窗 ---
  Future<void> _openPhotoPreview(List<PhotoEntry> photos, int initialIndex) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PhotoPreviewView(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  void _openExpenseEditor({ExpenseRecord? record}) {
    ExpenseRecordEntry? entry;
    if (record != null) {
      entry =
          _expenseCubit.state.entries
              .where((e) => e.id == record.id)
              .firstOrNull ??
          record.toExpenseRecordEntry();
    }
    openExpenseRecordEditorPage(
      context,
      entry: entry,
      initialProjectName: widget.projectName,
      onSavedOrDeleted: () async {
        await _loadExpenses();
        await _expenseCubit.loadEntries();
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
                onSaved: _photoCubit.loadEntries,
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
                onSaved: _photoCubit.loadEntries,
              ),
            );
          },
        ),
      ],
    );
  }

  void _openAddExpense() {
    openExpenseRecordEditorPage(
      context,
      initialProjectName: widget.projectName,
      onSavedOrDeleted: () async {
        await _loadExpenses();
        await _expenseCubit.loadEntries();
      },
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

  Future<void> _deleteSelectedPhotos(List<PhotoEntry> projectPhotos) async {
    final selectedPhotos = projectPhotos
        .where((photo) => _selectedPhotoIds.contains(photo.id))
        .toList();
    if (selectedPhotos.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmPhotoAction(
      context,
      title: "批量删除",
      message: "确定删除这 ${selectedPhotos.length} 张照片吗？删除后无法恢复。",
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;

    _exitMultiSelectMode();
    final deleteUseCase =
        widget.deletePhotoEntries ??
        (serviceLocator.isRegistered<DeletePhotoEntries>()
            ? serviceLocator<DeletePhotoEntries>()
            : null);
    if (deleteUseCase != null) {
      final result = await deleteUseCase(selectedPhotos);
      final failure = result.failureOrNull;
      if (failure != null) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        return;
      }
    }
    await _photoCubit.loadEntries();
  }

  Future<void> _exportSelectedPhotos(List<PhotoEntry> projectPhotos) async {
    final selectedPhotos = projectPhotos
        .where((photo) => _selectedPhotoIds.contains(photo.id))
        .toList();

    if (selectedPhotos.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;
    if (!mounted) return;

    final exportUseCase =
        widget.exportPhotoEntries ??
        (serviceLocator.isRegistered<ExportPhotoEntries>()
            ? serviceLocator<ExportPhotoEntries>()
            : null);
    if (exportUseCase != null) {
      final result = await exportUseCase(selectedPhotos, selectedDirectory);
      final failure = result.failureOrNull;
      if (failure != null) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        return;
      }
      final count = result.valueOrNull ?? selectedPhotos.length;
      messenger.showSnackBar(SnackBar(content: Text('已成功导出 $count 张照片至相册')));
    }
    _exitMultiSelectMode();
  }

  Future<void> _toggleArchiveProject(ProjectEntry project) async {
    final newStatus = project.status == ProjectEntryStatus.active
        ? ProjectEntryStatus.archived
        : ProjectEntryStatus.active;
    final updated = ProjectEntry(
      id: project.id,
      syncId: project.syncId,
      name: project.name,
      status: newStatus,
      stageNames: project.stageNames,
    );
    final saveEntry = serviceLocator.isRegistered<SaveProjectEntry>()
        ? serviceLocator<SaveProjectEntry>()
        : null;
    if (saveEntry != null) {
      final result = await saveEntry(updated);
      result.when(
        success: (_) async {
          await _projectCubit.loadEntries();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  newStatus == ProjectEntryStatus.archived
                      ? '项目已归档'
                      : '项目已取消归档',
                ),
              ),
            );
          }
        },
        failure: (f) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(f.message)));
          }
        },
      );
    }
  }

  Future<void> _showDeleteProjectDialog(ProjectEntry project) async {
    final messenger = ScaffoldMessenger.of(context);
    final projectPhotos = _photoCubit.state.entriesForProject(
      widget.projectName,
    );
    final evidenceItems = _evidenceCubit.state.entriesForProject(
      widget.projectName,
    );
    final expenseItems = _expenseCubit.state.entriesForProject(
      widget.projectName,
    );
    final mediaCount = projectPhotos.length;
    final evidenceCount = evidenceItems.length;
    final expenseCount = expenseItems.length;
    final tripCount = _projectTrips.length;
    final hasChildren =
        mediaCount + evidenceCount + expenseCount + tripCount > 0;
    final message = hasChildren
        ? "删除项目「${widget.projectName}」后，会一并删除 $mediaCount 张照片、$evidenceCount 份凭证和 $expenseCount 条项目费用，并解除 $tripCount 条出差记录的项目关联；出差记录本身不会删除。"
        : "删除项目「${widget.projectName}」后无法恢复。";

    final confirmed = await confirmPhotoAction(
      context,
      title: "删除项目",
      message: message,
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;

    final deleter = _deleteProject;
    if (deleter != null) {
      final result = await deleter(project);
      final failure = result.failureOrNull;
      if (failure != null) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        return;
      }
    }

    await _projectCubit.loadEntries();
    await _photoCubit.loadEntries();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showProjectStagesDialog(ProjectEntry project) async {
    final controller = TextEditingController(
      text: project.stageNames.join('\n'),
    );
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('项目节点'),
          content: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(hintText: '每行一个节点，例如：合同签订'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  controller.text
                      .split(RegExp(r'[\r\n]+'))
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .toList(),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) return;
    final failure = await _projectCubit.saveStageNames(project, result);
    if (!mounted) return;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('项目节点已保存')));
  }
}

class _CapsuleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CapsuleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseStatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _ExpenseStatColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          formatMoney(amount),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DetailTimelineItem {
  final DateTime date;
  final String type;
  final String title;
  final String subtitle;
  final double? amount;
  final IconData icon;
  final Color iconColor;
  final Object rawItem;

  const _DetailTimelineItem({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.icon,
    required this.iconColor,
    required this.rawItem,
  });
}

List<WorkLogEntry> entriesForProjectTrips(
  List<WorkLogEntry> entries,
  String projectName,
) {
  final normalizedProjectName = projectName.trim();
  return entries
      .where(
        (entry) =>
            entry.type == WorkLogEntryType.businessTrip &&
            entry.projectName?.trim() == normalizedProjectName,
      )
      .toList(growable: false);
}
