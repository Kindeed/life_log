import 'dart:async';

import 'package:life_log/common/widgets/app_local_thumbnail.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_load_failure.dart';
import 'package:life_log/common/widgets/app_floating_action_pill.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/presentation/project_trips_cubit.dart';
import 'package:life_log/features/project/presentation/project_accounting_summary.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/presentation/work_log_editor_launcher.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/features/project/data/project_cover_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/more/presentation/quick_action_contract.dart';

class ProjectDetailView extends StatefulWidget {
  final String projectName;
  final int? projectId;

  // 可选依赖，便于单测与解耦
  final ProjectCubit? projectCubit;
  final PhotoCubit? photoCubit;
  final EvidenceCubit? evidenceCubit;
  final ExpenseRecordCubit? expenseCubit;
  final LoadProjectWorkLogTrips? loadProjectWorkLogTrips;
  final WatchWorkLogEntries? watchWorkLogEntries;
  final DeleteProjectEntry? deleteProjectEntry;
  final DeletePhotoEntries? deletePhotoEntries;
  final ExportPhotoEntries? exportPhotoEntries;
  final ImagePicker? imagePicker;
  final ProjectCoverFileStore? coverFileStore;

  const ProjectDetailView({
    super.key,
    required this.projectName,
    this.projectId,
    this.projectCubit,
    this.photoCubit,
    this.evidenceCubit,
    this.expenseCubit,
    this.loadProjectWorkLogTrips,
    this.watchWorkLogEntries,
    this.deleteProjectEntry,
    this.deletePhotoEntries,
    this.exportPhotoEntries,
    this.imagePicker,
    this.coverFileStore,
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
  late final ProjectTripsCubit _tripsCubit;
  StreamSubscription<ProjectState>? _projectSubscription;
  late final DeleteProjectEntry? _deleteProject;
  late final ImagePicker _imagePicker;
  late final ProjectCoverFileStore _coverFileStore;

  bool _ownsProjectCubit = false;
  bool _ownsPhotoCubit = false;
  bool _ownsEvidenceCubit = false;
  bool _ownsExpenseCubit = false;

  late final TabController _tabController;
  ProjectEntry? get _project => widget.projectId == null
      ? _projectCubit.state.entryNamed(widget.projectName)
      : _projectCubit.state.entries
            .where((e) => e.id == widget.projectId)
            .firstOrNull;
  String get _projectName => _project?.name ?? widget.projectName;
  ProjectRecordScope get _scope => ProjectRecordScope(
    name: _projectName,
    id: _project?.id ?? widget.projectId,
    syncId: _project?.syncId,
  );
  List<ExpenseRecordEntry> get _directProjectExpenses {
    final scope = _scope;
    return _expenseCubit.state.entries
        .where(
          (e) => scope.contains(
            name: e.projectName,
            id: e.projectId,
            syncId: e.projectSyncId,
          ),
        )
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  List<WorkLogEntry> get _projectTrips => _tripsCubit.state.entries;
  bool get _hasReadFailure =>
      _projectCubit.state.failure != null ||
      _photoCubit.state.failure != null ||
      _evidenceCubit.state.failure != null ||
      _expenseCubit.state.failure != null ||
      _tripsCubit.state.failure != null;
  bool get _sourcesLoading =>
      _projectCubit.state.status == ProjectReadStatus.loading ||
      _photoCubit.state.status == PhotoStatus.loading ||
      _evidenceCubit.state.status == EvidenceStatus.loading ||
      _expenseCubit.state.status == ExpenseRecordStatus.loading ||
      _tripsCubit.state.loading;
  String _selectedTimelineFilter = '全部';
  bool _isMultiSelectMode = false;
  bool _photoBatchBusy = false;
  final Set<int> _selectedPhotoIds = <int>{};

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _coverFileStore = widget.coverFileStore ?? const ProjectCoverFileStore();
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

    _tripsCubit = ProjectTripsCubit(
      scope: _scope,
      loadTrips:
          widget.loadProjectWorkLogTrips ??
          (serviceLocator.isRegistered<LoadProjectWorkLogTrips>()
              ? serviceLocator<LoadProjectWorkLogTrips>()
              : null),
      watchEntries:
          widget.watchWorkLogEntries ??
          (serviceLocator.isRegistered<WatchWorkLogEntries>()
              ? serviceLocator<WatchWorkLogEntries>()
              : null),
    )..start();
    _projectSubscription = _projectCubit.stream.listen(
      (_) => _tripsCubit.setProject(_scope),
    );
    _deleteProject =
        widget.deleteProjectEntry ??
        (serviceLocator.isRegistered<DeleteProjectEntry>()
            ? serviceLocator<DeleteProjectEntry>()
            : null);

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!mounted) return;
    if (_tabController.index != 1 && _isMultiSelectMode) {
      _exitMultiSelectMode();
    }
    setState(() {});
  }

  Future<void> _refreshRecords() => Future.wait([
    _projectCubit.loadEntries(background: true),
    _photoCubit.loadEntries(background: true),
    _evidenceCubit.loadEntries(background: true),
    _expenseCubit.loadEntries(background: true),
    _tripsCubit.loadEntries(),
  ]);

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _projectSubscription?.cancel();
    _tripsCubit.close();
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
    final secondary = theme.colorScheme.onSurfaceVariant;
    return BlocBuilder<ProjectCubit, ProjectState>(
      bloc: _projectCubit,
      builder: (context, _) {
        return BlocBuilder<PhotoCubit, PhotoState>(
          bloc: _photoCubit,
          builder: (context, photoState) {
            return BlocBuilder<EvidenceCubit, EvidenceState>(
              bloc: _evidenceCubit,
              builder: (context, evidenceState) {
                return BlocBuilder<ExpenseRecordCubit, ExpenseRecordState>(
                  bloc: _expenseCubit,
                  builder: (context, _) {
                    return BlocBuilder<ProjectTripsCubit, ProjectTripsState>(
                      bloc: _tripsCubit,
                      builder: (context, _) {
                        final scope = _scope;
                        final photos =
                            photoState.entries
                                .where(
                                  (e) => scope.contains(
                                    name: e.projectName,
                                    id: e.projectId,
                                  ),
                                )
                                .toList()
                              ..sort(
                                (a, b) => (b.capturedAt ?? b.createdAt)
                                    .compareTo(a.capturedAt ?? a.createdAt),
                              );
                        final evidence =
                            evidenceState.entries
                                .where(
                                  (e) => scope.contains(
                                    name: e.projectName,
                                    id: e.projectId,
                                    syncId: e.projectSyncId,
                                  ),
                                )
                                .toList()
                              ..sort(
                                (a, b) =>
                                    b.evidenceDate.compareTo(a.evidenceDate),
                              );
                        _selectedPhotoIds.retainAll(
                          photos.map((photo) => photo.id),
                        );
                        return PopScope<void>(
                          canPop: !_isMultiSelectMode && !_photoBatchBusy,
                          onPopInvokedWithResult: (didPop, _) {
                            if (!didPop &&
                                _isMultiSelectMode &&
                                !_photoBatchBusy) {
                              _exitMultiSelectMode();
                            }
                          },
                          child: Scaffold(
                            appBar: _buildAppBar(
                              context,
                              theme,
                              _project,
                              photos,
                            ),
                            body: Column(
                              children: [
                                if (_project != null &&
                                    (_project!.stageNames.isNotEmpty ||
                                        _project!.status ==
                                            ProjectEntryStatus.archived))
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _project!.label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: secondary),
                                        ),
                                        for (final stage
                                            in _project!.stageNames) ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '·',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                          Text(
                                            stage,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(color: secondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                if (_hasReadFailure)
                                  Flexible(
                                    flex: 0,
                                    child: SingleChildScrollView(
                                      child: AppLoadFailure(
                                        compact: true,
                                        message: '部分项目记录加载失败，已保留当前内容。',
                                        onRetry: () =>
                                            unawaited(_refreshRecords()),
                                      ),
                                    ),
                                  ),
                                if (_sourcesLoading)
                                  const LinearProgressIndicator(minHeight: 2),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildTimelineTab(
                                        theme,
                                        secondary,
                                        photos,
                                        evidence,
                                      ),
                                      _buildPhotosTab(theme, secondary, photos),
                                      _buildExpensesTab(
                                        theme,
                                        theme.colorScheme.onSurface,
                                        secondary,
                                        evidence,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            bottomNavigationBar: _isMultiSelectMode
                                ? _buildMultiSelectBottomBar(
                                    theme.colorScheme.onSurface,
                                    photos,
                                  )
                                : null,
                            floatingActionButtonLocation:
                                FloatingActionButtonLocation.endFloat,
                            floatingActionButton: _isMultiSelectMode
                                ? null
                                : AppFloatingActionPill(
                                    label: '添加记录',
                                    icon: Icons.add_rounded,
                                    color: theme.colorScheme.primary,
                                    visible: true,
                                    heroTag: 'project-add',
                                    onPressed: _showAddRecordActions,
                                  ),
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
      },
    );
  }

  Widget _emptyTab({
    required String title,
    required String message,
    required IconData icon,
  }) {
    if (_sourcesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasReadFailure) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: AppEmptyState(icon: icon, title: title, message: message),
        ),
      ),
    );
  }

  void _showAddRecordActions() {
    showPhotoActionSheet(
      context,
      title: '添加到「$_projectName」',
      actions: [
        PhotoActionSheetItem(
          icon: Icons.photo_camera_outlined,
          title: QuickActionLabels.addPhoto,
          subtitle: '拍摄或导入现场照片',
          onTap: _showAddPhotoActions,
        ),
        PhotoActionSheetItem(
          icon: Icons.payments_outlined,
          title: QuickActionLabels.recordExpense,
          subtitle: '记录一笔实际支出',
          onTap: _openAddExpense,
        ),
        PhotoActionSheetItem(
          icon: Icons.receipt_long_outlined,
          title: QuickActionLabels.addEvidence,
          subtitle: '保存发票、付款截图或报销材料',
          onTap: _showEvidenceAddActions,
        ),
      ],
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
      title: Text(
        _projectName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (_isMultiSelectMode) ...[
          TextButton(
            onPressed: _photoBatchBusy
                ? null
                : () {
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
            onPressed: _photoBatchBusy ? null : _exitMultiSelectMode,
            child: const Text("取消"),
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
                case 'cover':
                  _pickProjectCover(project);
                  break;
                case 'clearCover':
                  _clearProjectCover(project);
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
                value: 'cover',
                child: Row(
                  children: [
                    Icon(Icons.image_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('选择封面'),
                  ],
                ),
              ),
              if (project?.localCoverPath != null ||
                  project?.coverImagePath != null)
                const PopupMenuItem(
                  value: 'clearCover',
                  child: Row(
                    children: [
                      Icon(Icons.hide_image_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('清除封面'),
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
        onTap: (index) => _tabController.animateTo(
          index,
          duration: AppMotion.duration(context, AppMotion.normal),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '动态'),
          Tab(text: '照片'),
          Tab(text: '账目'),
        ],
      ),
    );
  }

  Future<void> _pickProjectCover(ProjectEntry project) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    try {
      final path = await _coverFileStore.copyToPrivateStorage(
        projectId: project.id,
        sourcePath: image.path,
      );
      final failure = await _projectCubit.saveCoverPath(
        project,
        localCoverPath: path,
        coverImagePath: null,
      );
      if (mounted && failure != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存封面失败：$error')));
      }
    }
  }

  Future<void> _clearProjectCover(ProjectEntry project) async {
    final failure = await _projectCubit.saveCoverPath(
      project,
      localCoverPath: null,
      coverImagePath: null,
    );
    if (mounted && failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
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
          iconColor: theme.colorScheme.primary,
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
          projectAmount(expense.amount, expense.currency),
        ];
        return _DetailTimelineItem(
          date: expense.expenseDate,
          type: '费用',
          title: title,
          subtitle: subtitleParts.join(' · '),
          amount: expense.amount,
          icon: Icons.payments_rounded,
          iconColor: theme.semanticColors.success,
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
            if ((evidence.amount ?? 0) > 0)
              projectAmount(evidence.amount ?? 0, evidence.currency),
          ].join(' · '),
          amount: evidence.amount,
          icon: Icons.receipt_long_rounded,
          iconColor: theme.colorScheme.tertiary,
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
          iconColor: theme.semanticColors.warning,
          rawItem: trip,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final filteredItems = timelineItems
        .where(
          (item) =>
              _selectedTimelineFilter == '全部' ||
              item.type == _selectedTimelineFilter,
        )
        .toList();
    final rows = <Object>[];
    String? previousDay;
    for (final item in filteredItems) {
      final day = formatDateYmd(item.date);
      if (day != previousDay) {
        rows.add(day);
        previousDay = day;
      }
      rows.add(item);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${filteredItems.length} 条记录',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '筛选动态',
                initialValue: _selectedTimelineFilter,
                onSelected: (value) =>
                    setState(() => _selectedTimelineFilter = value),
                itemBuilder: (_) => [
                  for (final type in ['全部', '照片', '费用', '凭证', '出差'])
                    CheckedPopupMenuItem(
                      value: type,
                      checked: _selectedTimelineFilter == type,
                      child: Text(type == '全部' ? '全部动态' : type),
                    ),
                ],
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedTimelineFilter == '全部'
                            ? '全部动态'
                            : _selectedTimelineFilter,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? _emptyTab(
                  title: _selectedTimelineFilter == '全部' ? '项目还没有动态' : '暂无这类记录',
                  message: _selectedTimelineFilter == '全部'
                      ? '添加照片、支出或凭证，留下项目的进展。'
                      : '切换筛选查看其他项目动态。',
                  icon: Icons.timeline_rounded,
                )
              : RefreshIndicator(
                  onRefresh: _refreshRecords,
                  child: ListView.builder(
                    key: const PageStorageKey('project-activity'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: rows.length,
                    itemBuilder: (_, index) {
                      final row = rows[index];
                      if (row is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
                          child: Text(
                            row,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        );
                      }
                      final item = row as _DetailTimelineItem;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _recordRow(
                          key: ValueKey(
                            'activity-${item.type}-${_recordId(item.rawItem)}',
                          ),
                          theme: theme,
                          icon: item.icon,
                          color: item.iconColor,
                          title: item.title,
                          subtitle: '${item.type} · ${item.subtitle}',
                          photo: item.rawItem is PhotoEntry
                              ? item.rawItem as PhotoEntry
                              : null,
                          onTap: () =>
                              _handleTimelineItemTap(item, projectPhotos),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  int _recordId(Object record) => switch (record) {
    PhotoEntry e => e.id,
    ExpenseRecordEntry e => e.id,
    EvidenceEntry e => e.id,
    WorkLogEntry e => e.id,
    _ => 0,
  };

  Widget _recordRow({
    Key? key,
    required ThemeData theme,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    PhotoEntry? photo,
    String? amount,
    String? status,
    required VoidCallback onTap,
  }) {
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (amount != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (status != null)
                Text(
                  status,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
    final leading = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 52,
        height: 52,
        child: photo != null
            ? AppLocalThumbnail(
                filePath: photo.filePath,
                errorBuilder: (_, error, stack) => ColoredBox(
                  color: theme.semanticColors.mutedSurface,
                  child: Icon(Icons.image_not_supported_outlined, color: color),
                ),
              )
            : ColoredBox(
                color: color.withValues(alpha: .10),
                child: Icon(icon, size: 24, color: color),
              ),
      ),
    );
    return AppCard(
      key: key,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [leading, const SizedBox(height: 12), detail],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(child: detail),
              ],
            ),
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
    } else if (item.type == '费用' && item.rawItem is ExpenseRecordEntry) {
      final expense = item.rawItem as ExpenseRecordEntry;
      _openExpenseEditor(record: expense);
    } else if (item.type == '凭证' && item.rawItem is EvidenceEntry) {
      final evidence = item.rawItem as EvidenceEntry;
      unawaited(
        showEvidenceDetailSheet(
          context,
          legacyEvidenceFromEntry(evidence),
        ).then((_) {
          if (mounted) return _evidenceCubit.loadEntries(background: true);
        }),
      );
    } else if (item.rawItem is WorkLogEntry) {
      final trip = item.rawItem as WorkLogEntry;
      unawaited(
        openWorkLogEditorSheet(
          context,
          selectedDate: trip.date,
          existingEntry: trip,
          onSavedOrDeleted: _tripsCubit.loadEntries,
        ),
      );
    }
  }

  // --- Tab 2: 照片网格与批量操作 ---
  Widget _buildPhotosTab(
    ThemeData theme,
    Color textSecondary,
    List<PhotoEntry> projectPhotos,
  ) {
    if (projectPhotos.isEmpty) {
      return _emptyTab(
        title: '还没有项目照片',
        message: '拍摄或导入现场照片，按项目保存。',
        icon: Icons.photo_library_outlined,
      );
    }

    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    return RefreshIndicator(
      onRefresh: _refreshRecords,
      child: GridView.builder(
        key: const PageStorageKey('project-photos'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: large ? 2 : 3,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 10.h,
          mainAxisExtent: large ? 200 : 160,
        ),
        itemCount: projectPhotos.length,
        itemBuilder: (context, index) {
          final photo = projectPhotos[index];
          final isSelected = _selectedPhotoIds.contains(photo.id);

          return GestureDetector(
            onTap: () {
              if (_photoBatchBusy) return;
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
              if (_photoBatchBusy) return;
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
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AppLocalThumbnail(
                          filePath: photo.filePath,
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
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black26,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : null,
                              size: 16.sp,
                              color: Theme.of(context).colorScheme.onPrimary,
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
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
            _photoBatchBusy
                ? "正在处理照片…"
                : _selectedPhotoIds.isEmpty
                ? "已进入选择模式"
                : "选择了 ${_selectedPhotoIds.length} 张照片",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: _photoBatchBusy || _selectedPhotoIds.isEmpty
                      ? null
                      : () => _deleteSelectedPhotos(projectPhotos),
                  icon: Icons.delete_outline_rounded,
                  label: "删除",
                  height: 48,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: AppButton.primary(
                  onPressed: _photoBatchBusy || _selectedPhotoIds.isEmpty
                      ? null
                      : () => _exportSelectedPhotos(projectPhotos),
                  icon: Icons.ios_share_rounded,
                  label: "导出",
                  height: 48,
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
    final expenses = _directProjectExpenses;
    if (expenses.isEmpty && projectEvidence.isEmpty) {
      return _emptyTab(
        title: '还没有账目记录',
        message: '记录实际支出，或添加发票与报销凭证。',
        icon: Icons.payments_outlined,
      );
    }
    final totals = projectExpenseTotals(expenses);
    final pending = projectEvidence
        .where((e) => e.status != EvidenceEntryStatus.reimbursed)
        .length;
    final rows = <Object>[
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '已记录支出',
              style: theme.textTheme.labelLarge?.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 8),
            if (totals.isEmpty)
              Text(formatMoney(0), style: theme.textTheme.headlineSmall),
            for (final currency in (totals.keys.toList()..sort()))
              Text(
                projectAmount(totals[currency]!, currency),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${expenses.length} 笔支出 · ${projectEvidence.length} 份凭证 · $pending 份未报销',
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '仅统计支出明细，凭证金额单独展示。',
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
          ],
        ),
      ),
      if (expenses.isNotEmpty) '支出明细',
      ...expenses,
      if (projectEvidence.isNotEmpty) '凭证与报销',
      ...projectEvidence,
    ];
    return RefreshIndicator(
      onRefresh: _refreshRecords,
      child: ListView.separated(
        key: const PageStorageKey('project-ledger'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: rows.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (_, index) => switch (rows[index]) {
          Widget summary => summary,
          String title => _ledgerHeading(theme, title),
          ExpenseRecordEntry expense => _expenseRow(theme, expense),
          EvidenceEntry evidence => _evidenceRow(theme, evidence),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _expenseRow(ThemeData theme, ExpenseRecordEntry expense) => _recordRow(
    key: ValueKey('expense-${expense.id}'),
    theme: theme,
    icon: Icons.payments_outlined,
    color: theme.colorScheme.primary,
    title: expense.merchant?.trim().isNotEmpty == true
        ? expense.merchant!.trim()
        : expense.category.label,
    subtitle: [
      formatDateYmd(expense.expenseDate),
      expense.category.label,
      if (expense.projectStageName?.trim().isNotEmpty == true)
        expense.projectStageName!.trim(),
    ].join(' · '),
    amount: projectAmount(expense.amount, expense.currency),
    onTap: () => _openExpenseEditor(record: expense),
  );

  Widget _evidenceRow(ThemeData theme, EvidenceEntry evidence) => _recordRow(
    key: ValueKey('evidence-${evidence.id}'),
    theme: theme,
    icon: Icons.receipt_long_outlined,
    color: theme.colorScheme.tertiary,
    title: evidenceDisplayTitle(legacyEvidenceFromEntry(evidence)),
    subtitle: [
      formatDateYmd(evidence.evidenceDate),
      evidence.category.label,
      if (evidence.projectStageName?.trim().isNotEmpty == true)
        evidence.projectStageName!.trim(),
    ].join(' · '),
    amount: evidence.amount == null
        ? '金额未填写'
        : projectAmount(evidence.amount!, evidence.currency),
    status: evidence.status.label,
    onTap: () => unawaited(
      showEvidenceDetailSheet(context, legacyEvidenceFromEntry(evidence)).then((
        _,
      ) {
        if (mounted) return _evidenceCubit.loadEntries(background: true);
      }),
    ),
  );

  Widget _ledgerHeading(ThemeData theme, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
    child: Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  // --- 交互动作与弹窗 ---
  Future<void> _openPhotoPreview(List<PhotoEntry> photos, int initialIndex) {
    return Navigator.of(context).push<void>(
      appPageRoute<void>(
        context,
        PhotoPreviewView(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  void _openExpenseEditor({ExpenseRecordEntry? record}) {
    unawaited(
      openExpenseRecordEditorPage(
        context,
        entry: record,
        initialProjectName: _projectName,
        onSavedOrDeleted: _expenseCubit.loadEntries,
      ),
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
                initialProject: _projectName,
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
                initialProject: _projectName,
                onSaved: _photoCubit.loadEntries,
              ),
            );
          },
        ),
      ],
    );
  }

  void _openAddExpense() => _openExpenseEditor();

  void _showEvidenceAddActions() {
    showEvidenceAddActions(
      context,
      initialProject: _projectName,
      title: "添加凭证",
      manualSubtitle: "没有图片时再补充文字",
    );
  }

  Future<void> _runPhotoBatch(Future<void> Function() operation) async {
    if (_photoBatchBusy || !mounted) return;
    setState(() => _photoBatchBusy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('照片操作失败，请重试。')));
      }
    } finally {
      if (mounted) setState(() => _photoBatchBusy = false);
    }
  }

  Future<void> _deleteSelectedPhotos(List<PhotoEntry> projectPhotos) =>
      _runPhotoBatch(() => _deletePhotos(projectPhotos));
  Future<void> _exportSelectedPhotos(List<PhotoEntry> projectPhotos) =>
      _runPhotoBatch(() => _exportPhotos(projectPhotos));

  Future<void> _deletePhotos(List<PhotoEntry> projectPhotos) async {
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
    if (!confirmed || !mounted) return;

    final deleteUseCase =
        widget.deletePhotoEntries ??
        (serviceLocator.isRegistered<DeletePhotoEntries>()
            ? serviceLocator<DeletePhotoEntries>()
            : null);
    if (deleteUseCase == null) {
      messenger.showSnackBar(const SnackBar(content: Text('删除照片功能暂不可用')));
      return;
    }
    final result = await deleteUseCase(selectedPhotos);
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    await _photoCubit.loadEntries();
    if (!mounted) return;
    _exitMultiSelectMode();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('已删除 ${selectedPhotos.length} 张照片')),
    );
  }

  Future<void> _exportPhotos(List<PhotoEntry> projectPhotos) async {
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
    if (exportUseCase == null) {
      messenger.showSnackBar(const SnackBar(content: Text('导出照片功能暂不可用')));
      return;
    }
    final result = await exportUseCase(selectedPhotos, selectedDirectory);
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    final count = result.valueOrNull ?? selectedPhotos.length;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('已导出 $count 张照片至所选文件夹')));
    if (mounted) _exitMultiSelectMode();
  }

  Future<void> _toggleArchiveProject(ProjectEntry project) async {
    final status = project.status == ProjectEntryStatus.active
        ? ProjectEntryStatus.archived
        : ProjectEntryStatus.active;
    final failure = await _projectCubit.saveStatus(project, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure?.message ??
              (status == ProjectEntryStatus.archived ? '项目已归档' : '项目已取消归档'),
        ),
      ),
    );
  }

  Future<void> _showDeleteProjectDialog(ProjectEntry project) async {
    final messenger = ScaffoldMessenger.of(context);
    final projectPhotos = _photoCubit.state.entries
        .where((e) => _scope.contains(name: e.projectName, id: e.projectId))
        .toList();
    final evidenceItems = _evidenceCubit.state.entries
        .where(
          (e) => _scope.contains(
            name: e.projectName,
            id: e.projectId,
            syncId: e.projectSyncId,
          ),
        )
        .toList();
    final expenseItems = _directProjectExpenses;
    final mediaCount = projectPhotos.length;
    final evidenceCount = evidenceItems.length;
    final expenseCount = expenseItems.length;
    final tripCount = _projectTrips.length;
    final hasChildren = evidenceCount + expenseCount + tripCount > 0;
    final message = hasChildren
        ? "删除项目「$_projectName」后会删除 $evidenceCount 份凭证和 $expenseCount 条项目费用，解除 $tripCount 条已关联的出差记录；$mediaCount 张项目照片将保留并移除项目关联。同步项目会先标记为待删除，待同步完成后再清理。"
        : mediaCount > 0
        ? "删除项目「$_projectName」后，$mediaCount 张项目照片将保留并移除项目关联；同步项目会先标记为待删除。"
        : "删除项目「$_projectName」后，同步项目会先标记为待删除；本地项目删除后无法恢复。";

    final confirmed = await confirmPhotoAction(
      context,
      title: "删除项目",
      message: message,
      confirmLabel: "删除",
      destructive: true,
    );
    if (!confirmed) return;

    final deleter = _deleteProject;
    if (deleter == null) {
      messenger.showSnackBar(const SnackBar(content: Text('删除项目功能暂不可用')));
      return;
    }
    final result = await deleter(project);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    await Future.wait([
      _projectCubit.loadEntries(),
      _photoCubit.loadEntries(),
      _evidenceCubit.loadEntries(),
      _expenseCubit.loadEntries(),
    ]);
    if (!mounted) return;
    Navigator.of(context).pop();
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
