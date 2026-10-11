import 'package:life_log/features/project/presentation/project_stage_field.dart';
import 'package:life_log/features/photo/application/assign_photo_stage.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/features/project/presentation/project_stage_summary.dart';
import 'package:life_log/features/project/presentation/project_stages_sheet.dart';
import 'package:life_log/features/project/presentation/project_channel_stage_bar.dart';
import 'package:life_log/features/project/presentation/project_channel_composer.dart';
import 'package:life_log/features/project/presentation/project_channel_record.dart';
import 'package:life_log/features/project/presentation/project_channel_group_header.dart';
import 'package:life_log/features/project/presentation/project_channel_outline_row.dart';
import 'package:life_log/features/project/presentation/project_note_editor.dart';
import 'package:life_log/features/project/presentation/project_note_cubit.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/application/load_project_note_entries.dart';
import 'package:life_log/features/project/application/watch_project_note_entries.dart';
import 'dart:async';

import 'package:life_log/common/widgets/app_local_thumbnail.dart';
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
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
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
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';

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
  final LoadProjectNoteEntries? loadProjectNotes;
  final WatchProjectNoteEntries? watchProjectNotes;
  final Stream<void> Function()? watchAccountScope;
  final DeleteProjectEntry? deleteProjectEntry;
  final DeletePhotoEntries? deletePhotoEntries;
  final ExportPhotoEntries? exportPhotoEntries;
  final AssignPhotoStage? assignPhotoStage;
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
    this.loadProjectNotes,
    this.watchProjectNotes,
    this.watchAccountScope,
    this.deleteProjectEntry,
    this.deletePhotoEntries,
    this.exportPhotoEntries,
    this.assignPhotoStage,
    this.imagePicker,
    this.coverFileStore,
  });

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

enum _ProjectDetailSection { channel, photos, ledger }

class _ProjectDetailViewState extends State<ProjectDetailView> {
  late final ProjectCubit _projectCubit;
  late final PhotoCubit _photoCubit;
  late final EvidenceCubit _evidenceCubit;
  late final ExpenseRecordCubit _expenseCubit;
  late final ProjectTripsCubit _tripsCubit;
  late final ProjectNoteCubit _notesCubit;
  StreamSubscription<ProjectNoteState>? _notesSubscription;
  StreamSubscription<void>? _accountSubscription;
  int _accountReloadGeneration = 0;
  bool _accountReloading = false;
  bool _accountReadFailed = false;
  StreamSubscription<ProjectState>? _projectSubscription;
  late final DeleteProjectEntry? _deleteProject;
  late final ImagePicker _imagePicker;
  late final ProjectCoverFileStore _coverFileStore;

  bool _ownsProjectCubit = false;
  bool _ownsPhotoCubit = false;
  bool _ownsEvidenceCubit = false;
  bool _ownsExpenseCubit = false;

  _ProjectDetailSection _section = _ProjectDetailSection.channel;
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
  List<ExpenseRecordEntry> get _directProjectExpenses => _allProjectExpenses
      .where((e) => _stageMatches(e.projectStageName))
      .toList();

  List<ExpenseRecordEntry> get _allProjectExpenses {
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

  List<WorkLogEntry> get _projectTrips => _tripsCubit.state.entries
      .where((e) => _stageMatches(e.projectStageName))
      .toList();
  List<ProjectNoteEntry> get _projectNotes => _notesCubit.state.entries
      .where((e) => _stageMatches(e.projectStageName))
      .toList();
  bool get _hasReadFailure =>
      _projectCubit.state.failure != null ||
      _photoCubit.state.failure != null ||
      _evidenceCubit.state.failure != null ||
      _expenseCubit.state.failure != null ||
      _tripsCubit.state.failure != null ||
      _notesCubit.state.failure != null;
  bool get _sourcesLoading =>
      _projectCubit.state.status == ProjectReadStatus.loading ||
      _photoCubit.state.status == PhotoStatus.loading ||
      _evidenceCubit.state.status == EvidenceStatus.loading ||
      _expenseCubit.state.status == ExpenseRecordStatus.loading ||
      _tripsCubit.state.loading ||
      _notesCubit.state.loading;
  String _selectedTimelineFilter = '全部';
  final Set<String> _expandedMonths = {};
  final Set<String> _expandedDays = {};
  bool _directoryInitialized = false;
  List<_ChannelMonth> _channelMonths = const [];
  PageStorageBucket _detailPageStorage = PageStorageBucket();
  final Map<(String?, String), PageStorageBucket> _channelPageStorage = {};
  String? _selectedStage;
  bool _stageMatches(String? name) =>
      _selectedStage == null || (name?.trim() ?? '') == _selectedStage;
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
      watchScope: widget.watchAccountScope ?? _watchAccountScope,
    )..start();
    _notesCubit = ProjectNoteCubit(
      scope: _scope,
      loadEntries:
          widget.loadProjectNotes ??
          (serviceLocator.isRegistered<LoadProjectNoteEntries>()
              ? serviceLocator<LoadProjectNoteEntries>()
              : null),
      watchEntries:
          widget.watchProjectNotes ??
          (serviceLocator.isRegistered<WatchProjectNoteEntries>()
              ? serviceLocator<WatchProjectNoteEntries>()
              : null),
    )..start();
    _notesSubscription = _notesCubit.stream.listen((_) {
      if (mounted) setState(() {});
    });
    _projectSubscription = _projectCubit.stream.listen((_) {
      _tripsCubit.setProject(_scope);
      _notesCubit.setProject(_scope);
    });
    _accountSubscription = (widget.watchAccountScope ?? _watchAccountScope)()
        .listen((_) => unawaited(_reloadAccountRecords()));
    _deleteProject =
        widget.deleteProjectEntry ??
        (serviceLocator.isRegistered<DeleteProjectEntry>()
            ? serviceLocator<DeleteProjectEntry>()
            : null);
  }

  void _openSection(_ProjectDetailSection section) {
    if (_photoBatchBusy) return;
    setState(() {
      _section = section;
      _selectedPhotoIds.clear();
      _isMultiSelectMode = false;
    });
  }

  void _returnToChannel() {
    if (_photoBatchBusy) return;
    if (_isMultiSelectMode) {
      _exitMultiSelectMode();
    } else {
      _openSection(_ProjectDetailSection.channel);
    }
  }

  Stream<void> _watchAccountScope() {
    if (!serviceLocator.isRegistered<ProfileAccountRepositoryPort>()) {
      return const Stream<void>.empty();
    }
    final account = serviceLocator<ProfileAccountRepositoryPort>();
    final initial = account.loadAccount();
    var first = true;
    return account
        .watchAccount()
        .where((snapshot) {
          if (first) {
            first = false;
            return snapshot != initial;
          }
          return true;
        })
        .map((_) {});
  }

  Future<void> _reloadAccountRecords() async {
    if (!mounted) return;
    final generation = ++_accountReloadGeneration;
    setState(() {
      _accountReloading = true;
      _accountReadFailed = false;
      _selectedStage = null;
      _selectedTimelineFilter = '全部';
      _expandedMonths.clear();
      _expandedDays.clear();
      _directoryInitialized = false;
      _channelMonths = const [];
      _detailPageStorage = PageStorageBucket();
      _channelPageStorage.clear();
      _section = _ProjectDetailSection.channel;
      _selectedPhotoIds.clear();
      _isMultiSelectMode = false;
    });
    await _refreshRecords();
    if (!mounted || generation != _accountReloadGeneration) return;
    setState(() {
      // A failed owner-scoped read must not reveal retained rows from the prior account.
      _accountReadFailed = _hasReadFailure;
      _accountReloading = _accountReadFailed;
    });
  }

  Future<void> _refreshRecords() => Future.wait([
    _projectCubit.loadEntries(background: true),
    _photoCubit.loadEntries(background: true),
    _evidenceCubit.loadEntries(background: true),
    _expenseCubit.loadEntries(background: true),
    _tripsCubit.loadEntries(),
    _notesCubit.loadEntries(background: true),
  ]);

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _notesSubscription?.cancel();
    _accountSubscription?.cancel();
    _tripsCubit.close();
    _notesCubit.close();
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
    if (_accountReloading) {
      return Scaffold(
        appBar: AppBar(title: const Text('项目记录')),
        body: _accountReadFailed
            ? AppLoadFailure(
                message: '账号切换后读取项目失败，请重试。',
                onRetry: () => unawaited(_reloadAccountRecords()),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }
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
                        final allPhotos =
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
                        final allEvidence =
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
                        final photos = allPhotos
                            .where((e) => _stageMatches(e.projectStageName))
                            .toList();
                        final evidence = allEvidence
                            .where((e) => _stageMatches(e.projectStageName))
                            .toList();
                        final stageSummaries = projectStageSummaries(
                          definitions: _project?.stageNames ?? const [],
                          photos: allPhotos,
                          expenses: _allProjectExpenses,
                          evidence: allEvidence,
                          trips: _tripsCubit.state.entries,
                          notes: _notesCubit.state.entries,
                        );
                        _selectedPhotoIds.retainAll(
                          photos.map((photo) => photo.id),
                        );
                        return PopScope<void>(
                          canPop:
                              _section == _ProjectDetailSection.channel &&
                              !_isMultiSelectMode &&
                              !_photoBatchBusy,
                          onPopInvokedWithResult: (didPop, _) {
                            if (!didPop) _returnToChannel();
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
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    0,
                                    12,
                                    4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ProjectChannelStageBar(
                                          selectedStage: _selectedStage,
                                          stageCount: stageSummaries
                                              .where((s) => s.name.isNotEmpty)
                                              .length,
                                          recordCount: _visibleRecordCount(
                                            photos.length,
                                            evidence.length,
                                          ),
                                          onSelect:
                                              _photoBatchBusy ||
                                                  _project == null
                                              ? null
                                              : () => _chooseStage(
                                                  stageSummaries,
                                                ),
                                        ),
                                      ),
                                      if (_section ==
                                          _ProjectDetailSection.channel) ...[
                                        _buildDateDirectoryMenu(),
                                        _buildRecordFilter(),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_project?.isLocalArchive == true)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      4,
                                      16,
                                      8,
                                    ),
                                    child: Text(
                                      '云端项目已删除，本机记录仍可查看和补记。',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: secondary),
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
                                  child: PageStorage(
                                    key: ValueKey(_accountReloadGeneration),
                                    bucket: _detailPageStorage,
                                    child: _buildSectionBody(switch (_section) {
                                      _ProjectDetailSection.channel =>
                                        PageStorage(
                                          key: ValueKey((
                                            _selectedStage,
                                            _selectedTimelineFilter,
                                          )),
                                          bucket: _channelPageStorage
                                              .putIfAbsent((
                                                _selectedStage,
                                                _selectedTimelineFilter,
                                              ), PageStorageBucket.new),
                                          child: _buildTimelineTab(
                                            theme,
                                            photos,
                                            evidence,
                                          ),
                                        ),
                                      _ProjectDetailSection.photos =>
                                        _buildPhotosTab(
                                          theme,
                                          secondary,
                                          photos,
                                        ),
                                      _ProjectDetailSection.ledger =>
                                        _buildExpensesTab(
                                          theme,
                                          theme.colorScheme.onSurface,
                                          secondary,
                                          evidence,
                                        ),
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            bottomNavigationBar: _isMultiSelectMode
                                ? _buildMultiSelectBottomBar(
                                    theme.colorScheme.onSurface,
                                    photos,
                                  )
                                : _section == _ProjectDetailSection.channel
                                ? ProjectChannelComposer(
                                    onWrite: _project == null
                                        ? null
                                        : () => _openNoteEditor(),
                                    onAdd: _showAddRecordActions,
                                  )
                                : null,
                            floatingActionButtonLocation:
                                FloatingActionButtonLocation.endFloat,
                            floatingActionButton:
                                _isMultiSelectMode ||
                                    _section == _ProjectDetailSection.channel
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

  Widget _buildSectionBody(Widget child) {
    final keyed = KeyedSubtree(key: ValueKey(_section), child: child);
    final duration = AppMotion.duration(context, AppMotion.normal);
    if (duration == Duration.zero) return keyed;
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: AppMotion.pageExit,
      switchInCurve: AppMotion.standardDecelerate,
      switchOutCurve: AppMotion.standard,
      child: keyed,
    );
  }

  int _visibleRecordCount(int photoCount, int evidenceCount) {
    final expenseCount = _directProjectExpenses.length;
    if (_section == _ProjectDetailSection.photos) return photoCount;
    if (_section == _ProjectDetailSection.ledger) {
      return expenseCount + evidenceCount;
    }
    final counts = {
      '文字': _projectNotes.length,
      '照片': photoCount,
      '费用': expenseCount,
      '凭证': evidenceCount,
      '出差': _projectTrips.length,
    };
    return counts[_selectedTimelineFilter] ??
        counts.values.fold(0, (total, count) => total + count);
  }

  Widget _buildRecordFilter() => PopupMenuButton<String>(
    tooltip: '筛选记录',
    initialValue: _selectedTimelineFilter,
    onSelected: (value) => setState(() => _selectedTimelineFilter = value),
    child: SizedBox(
      width: 48,
      height: 48,
      child: Icon(
        _selectedTimelineFilter == '全部'
            ? Icons.filter_list_rounded
            : Icons.filter_alt_rounded,
        color: _selectedTimelineFilter == '全部'
            ? null
            : Theme.of(context).colorScheme.primary,
      ),
    ),
    itemBuilder: (_) => [
      for (final type in ['全部', '文字', '照片', '费用', '凭证', '出差'])
        CheckedPopupMenuItem(
          value: type,
          checked: _selectedTimelineFilter == type,
          child: Text(type == '全部' ? '全部记录' : type),
        ),
    ],
  );

  Widget _buildDateDirectoryMenu() => PopupMenuButton<String>(
    tooltip: '日期目录',
    onSelected: (action) {
      setState(() {
        _directoryInitialized = true;
        for (final month in _channelMonths) {
          if (action == 'expand-all') {
            _expandedMonths.add(month.key);
            _expandedDays.addAll(month.days.map((day) => day.key));
          } else {
            _expandedMonths.remove(month.key);
            for (final day in month.days) {
              _expandedDays.remove(day.key);
            }
          }
        }
      });
    },
    child: const SizedBox(
      width: 48,
      height: 48,
      child: Icon(Icons.unfold_more_rounded),
    ),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'expand-all', child: Text('全部展开')),
      PopupMenuItem(value: 'collapse-all', child: Text('全部收起')),
    ],
  );

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
        if (_project != null)
          PhotoActionSheetItem(
            icon: Icons.edit_note_rounded,
            title: '写文字记录',
            subtitle: _selectedStage == null
                ? '设备状态、现场进展、沟通与跟进事项'
                : '记录到${_selectedStage!.isEmpty ? '未分阶段' : '「$_selectedStage」'}',
            onTap: _openNoteEditor,
          ),
        PhotoActionSheetItem(
          icon: Icons.photo_camera_outlined,
          title: QuickActionLabels.addPhoto,
          subtitle: '拍摄或导入现场照片',
          onTap: _showAddPhotoActions,
        ),
        if (_project?.isLocalArchive != true) ...[
          PhotoActionSheetItem(
            icon: Icons.luggage_outlined,
            title: '记录出差',
            subtitle: '关联当前项目与所查看的阶段',
            onTap: _openAddTrip,
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
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ProjectEntry? project,
    List<PhotoEntry> projectPhotos,
  ) {
    final title = switch (_section) {
      _ProjectDetailSection.channel => _projectName,
      _ProjectDetailSection.photos => '项目照片',
      _ProjectDetailSection.ledger => '项目账目',
    };
    final subtitle = _section == _ProjectDetailSection.channel
        ? project?.isLocalArchive == true
              ? '本地保留'
              : project?.status.label ?? '项目记录'
        : _projectName;
    final scaler = MediaQuery.textScalerOf(context);
    final titleHeight = scaler.scale(22) * 1.25 + scaler.scale(12) * 1.3 + 12;
    return AppBar(
      titleSpacing: 0,
      toolbarHeight: titleHeight > 68 ? titleHeight : 68,
      leading: _section == _ProjectDetailSection.channel
          ? null
          : IconButton(
              tooltip: '返回项目记录',
              onPressed: _photoBatchBusy ? null : _returnToChannel,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
          if (_section != _ProjectDetailSection.photos)
            IconButton(
              tooltip: '查看照片',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => _openSection(_ProjectDetailSection.photos),
            ),
          if (_section != _ProjectDetailSection.ledger)
            IconButton(
              tooltip: '查看账目',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => _openSection(_ProjectDetailSection.ledger),
            ),
          if (_section == _ProjectDetailSection.photos &&
              projectPhotos.isNotEmpty)
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
                    Text('阶段管理'),
                  ],
                ),
              ),
              if (project?.isLocalArchive != true)
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
    );
  }

  Future<void> _openNoteEditor({ProjectNoteEntry? existing}) async {
    final project = _project;
    if (project == null) return;
    final changed = await showProjectNoteEditor(
      context,
      project: project,
      existing: existing,
      initialStage: _selectedStage,
    );
    if (mounted && changed == true) {
      unawaited(_notesCubit.loadEntries(background: true));
    }
  }

  Future<void> _openAddTrip() => openWorkLogEditorSheet(
    context,
    selectedDate: DateTime.now(),
    initialType: WorkLogEntryType.businessTrip,
    initialProject: _project,
    initialProjectStageName: _selectedStage,
    onSavedOrDeleted: _tripsCubit.loadEntries,
  );

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

  // Unified project record channel.
  Widget _buildTimelineTab(
    ThemeData theme,
    List<PhotoEntry> projectPhotos,
    List<EvidenceEntry> projectEvidence,
  ) {
    final timelineItems =
        <_DetailTimelineItem>[
          ..._projectNotes.map(
            (note) => _DetailTimelineItem(
              date: note.date,
              type: '文字',
              title: '文字记录',
              subtitle: note.projectStageName?.trim().isNotEmpty == true
                  ? note.projectStageName!.trim()
                  : '未分阶段',
              content: note.content,
              icon: Icons.edit_note_rounded,
              iconColor: theme.colorScheme.primary,
              rawItem: note,
            ),
          ),
          ...projectPhotos.map(
            (photo) => _DetailTimelineItem(
              date: photo.capturedAt ?? photo.createdAt,
              type: '照片',
              title: photo.deviceName?.trim().isNotEmpty == true
                  ? photo.deviceName!.trim()
                  : photo.fileName,
              content: photo.description,
              subtitle: [
                photo.deviceName ?? '项目照片',
                if (photo.projectStageName?.isNotEmpty == true)
                  photo.projectStageName!,
              ].join(' · '),
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
              content: expense.note,
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
              content: evidence.note,
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
              content: trip.note,
              icon: Icons.luggage_rounded,
              iconColor: theme.semanticColors.warning,
              rawItem: trip,
            ),
          ),
        ]..sort((a, b) {
          final dateOrder = b.date.compareTo(a.date);
          if (dateOrder != 0) return dateOrder;
          final createdOrder = _recordCreatedAt(
            b.rawItem,
          ).compareTo(_recordCreatedAt(a.rawItem));
          if (createdOrder != 0) return createdOrder;
          final idOrder = _recordId(b.rawItem).compareTo(_recordId(a.rawItem));
          return idOrder != 0 ? idOrder : a.type.compareTo(b.type);
        });

    final filteredItems = timelineItems
        .where(
          (item) =>
              _selectedTimelineFilter == '全部' ||
              item.type == _selectedTimelineFilter,
        )
        .toList();
    final months = <String, Map<String, List<_DetailTimelineItem>>>{};
    for (final item in filteredItems) {
      final day = formatDateYmd(item.date);
      (months
              .putIfAbsent(day.substring(0, 7), () => {})
              .putIfAbsent(day, () => []))
          .add(item);
    }
    _channelMonths = [
      for (final month in months.entries)
        _ChannelMonth(month.key, [
          for (final day in month.value.entries)
            _ChannelDay(day.key, day.value),
        ]),
    ];
    if (!_directoryInitialized &&
        _channelMonths.isNotEmpty &&
        !_sourcesLoading &&
        !_hasReadFailure) {
      _directoryInitialized = true;
      _expandedMonths.add(_channelMonths.first.key);
      _expandedDays.add(_channelMonths.first.days.first.key);
    }
    final rows = <_ChannelOutlineEntry>[];
    for (final month in _channelMonths) {
      rows.add(_ChannelOutlineEntry(month));
      if (!_expandedMonths.contains(month.key)) continue;
      for (var dayIndex = 0; dayIndex < month.days.length; dayIndex++) {
        final day = month.days[dayIndex];
        final hasFollowingDay = dayIndex < month.days.length - 1;
        final expanded = _expandedDays.contains(day.key);
        rows.add(
          _ChannelOutlineEntry(
            day,
            hasFollowingDay: hasFollowingDay,
            continuesDay: expanded,
          ),
        );
        if (!expanded) continue;
        for (var itemIndex = 0; itemIndex < day.items.length; itemIndex++) {
          rows.add(
            _ChannelOutlineEntry(
              day.items[itemIndex],
              hasFollowingDay: hasFollowingDay,
              continuesDay: itemIndex < day.items.length - 1,
            ),
          );
        }
      }
    }
    final rowIndexes = {
      for (var i = 0; i < rows.length; i++) _channelRowKey(rows[i].row): i,
    };
    return filteredItems.isEmpty
        ? _emptyTab(
            title: _selectedTimelineFilter == '全部' ? '开始记录这个项目' : '暂无这类记录',
            message: _selectedTimelineFilter == '全部'
                ? '设备状态、生产安排、现场照片，都可以记在这里。'
                : '切换筛选查看其他项目记录。',
            icon: Icons.edit_note_rounded,
          )
        : RefreshIndicator(
            onRefresh: _refreshRecords,
            child: ListView.builder(
              key: const PageStorageKey('project-activity'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
              itemCount: rows.length,
              findChildIndexCallback: (key) => rowIndexes[key],
              itemBuilder: (_, index) {
                final entry = rows[index];
                final row = entry.row;
                final isLastInMonth =
                    index == rows.length - 1 ||
                    rows[index + 1].row is _ChannelMonth;
                if (row is _ChannelMonth || row is _ChannelDay) {
                  final isMonth = row is _ChannelMonth;
                  final dateKey = isMonth ? row.key : (row as _ChannelDay).key;
                  final expanded = (isMonth ? _expandedMonths : _expandedDays)
                      .contains(dateKey);
                  return ProjectChannelOutlineRow(
                    key: _channelRowKey(row),
                    level: isMonth
                        ? ProjectChannelOutlineLevel.month
                        : ProjectChannelOutlineLevel.day,
                    isLastInMonth: isLastInMonth,
                    hasFollowingDay: entry.hasFollowingDay,
                    continuesDay: entry.continuesDay,
                    child: ProjectChannelGroupHeader(
                      date: DateTime.parse(isMonth ? '$dateKey-01' : dateKey),
                      level: isMonth
                          ? ProjectChannelDateLevel.month
                          : ProjectChannelDateLevel.day,
                      recordCount: isMonth
                          ? row.recordCount
                          : (row as _ChannelDay).items.length,
                      dayCount: isMonth ? row.days.length : null,
                      expanded: expanded,
                      onToggle: () => setState(() {
                        _directoryInitialized = true;
                        final keys = isMonth ? _expandedMonths : _expandedDays;
                        if (!keys.remove(dateKey)) keys.add(dateKey);
                      }),
                    ),
                  );
                }
                final item = row as _DetailTimelineItem;
                return ProjectChannelOutlineRow(
                  key: _channelRowKey(row),
                  level: ProjectChannelOutlineLevel.record,
                  isLastInMonth: isLastInMonth,
                  hasFollowingDay: entry.hasFollowingDay,
                  continuesDay: entry.continuesDay,
                  child: ProjectChannelRecord(
                    icon: item.icon,
                    color: item.iconColor,
                    title: item.title,
                    subtitle: item.subtitle,
                    typeLabel: item.type,
                    eventTime: item.date,
                    content: item.content,
                    photo: item.rawItem is PhotoEntry
                        ? item.rawItem as PhotoEntry
                        : null,
                    onTap: () => _handleTimelineItemTap(item, projectPhotos),
                  ),
                );
              },
            ),
          );
  }

  ValueKey<String> _channelRowKey(Object row) => ValueKey(switch (row) {
    _ChannelMonth month => 'channel-month-${month.key}',
    _ChannelDay day => 'channel-day-${day.key}',
    _DetailTimelineItem item =>
      'activity-${item.type}-${_recordId(item.rawItem)}',
    _ => throw StateError('Unsupported channel row'),
  });

  int _recordId(Object record) => switch (record) {
    PhotoEntry e => e.id,
    ExpenseRecordEntry e => e.id,
    EvidenceEntry e => e.id,
    WorkLogEntry e => e.id,
    ProjectNoteEntry e => e.id,
    _ => 0,
  };

  DateTime _recordCreatedAt(Object record) => switch (record) {
    PhotoEntry e => e.createdAt,
    ExpenseRecordEntry e => e.createdAt ?? e.expenseDate,
    EvidenceEntry e => e.createdAt ?? e.evidenceDate,
    WorkLogEntry e => e.createdAt ?? e.date,
    ProjectNoteEntry e => e.createdAt,
    _ => DateTime(1900),
  };

  Widget _recordRow({
    Key? key,
    required ThemeData theme,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? amount,
    String? status,
    required VoidCallback onTap,
  }) {
    return _ledgerSurface(
      theme,
      key: key,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(height: 10),
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
      ),
    );
  }

  Widget _ledgerSurface(
    ThemeData theme, {
    Key? key,
    VoidCallback? onTap,
    required Widget child,
  }) {
    final radius = BorderRadius.circular(AppRadius.sm);
    final content = Padding(padding: const EdgeInsets.all(16), child: child);
    return Material(
      key: key,
      color: theme.colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }

  void _handleTimelineItemTap(
    _DetailTimelineItem item,
    List<PhotoEntry> projectPhotos,
  ) {
    if (_project?.isLocalArchive == true &&
        (item.rawItem is ExpenseRecordEntry ||
            item.rawItem is EvidenceEntry ||
            item.rawItem is WorkLogEntry)) {
      unawaited(_showArchivedRecord(item.title, item.subtitle, item.content));
      return;
    }
    if (item.rawItem is ProjectNoteEntry) {
      unawaited(_openNoteEditor(existing: item.rawItem as ProjectNoteEntry));
    } else if (item.type == '照片' && item.rawItem is PhotoEntry) {
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

  // Optional photo browser and batch operations.
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
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: AppLocalThumbnail(
                          filePath: photo.filePath,
                          errorBuilder: (ctx, err, stack) => Semantics(
                            label: '照片文件不可用',
                            child: ColoredBox(
                              color: theme.semanticColors.mutedSurface,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: textSecondary,
                                ),
                              ),
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
          TextButton.icon(
            onPressed: _photoBatchBusy || _selectedPhotoIds.isEmpty
                ? null
                : () => _runPhotoBatch(
                    () => _assignSelectedPhotoStage(projectPhotos),
                  ),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('设置阶段'),
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

  // Optional expense and evidence ledger.
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
      _ledgerSurface(
        theme,
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
    onTap: () => _project?.isLocalArchive == true
        ? unawaited(
            _showArchivedRecord(
              evidenceDisplayTitle(legacyEvidenceFromEntry(evidence)),
              '${formatDateYmd(evidence.evidenceDate)} · ${evidence.amount == null ? '金额未填写' : projectAmount(evidence.amount!, evidence.currency)} · ${evidence.status.label}',
              evidence.note,
            ),
          )
        : unawaited(
            showEvidenceDetailSheet(
              context,
              legacyEvidenceFromEntry(evidence),
            ).then((_) {
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
    if (_project?.isLocalArchive == true) {
      if (record != null) {
        unawaited(
          _showArchivedRecord(
            record.merchant ?? record.category.label,
            '${formatDateYmd(record.expenseDate)} · ${projectAmount(record.amount, record.currency)}',
            record.note,
          ),
        );
      }
      return;
    }
    unawaited(
      openExpenseRecordEditorPage(
        context,
        entry: record,
        initialProjectName: _projectName,
        initialProjectStageName: _selectedStage,
        onSavedOrDeleted: _expenseCubit.loadEntries,
      ),
    );
  }

  Future<void> _showArchivedRecord(
    String title,
    String subtitle,
    String? content,
  ) => showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppSheetScaffold(
      title: title,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('云端项目已删除，这条记录保留在本机供回看。新的出差和账目请关联到其他项目。'),
          const SizedBox(height: 16),
          SelectableText(subtitle),
          if (content?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            SelectableText(content!.trim()),
          ],
        ],
      ),
    ),
  );

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
                initialProjectId: _project?.id,
                initialProjectStageName: _selectedStage,
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
                initialProjectId: _project?.id,
                initialProjectStageName: _selectedStage,
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
      initialProjectStageName: _selectedStage,
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

  Future<void> _assignSelectedPhotoStage(List<PhotoEntry> photos) async {
    final selected = photos
        .where((p) => _selectedPhotoIds.contains(p.id))
        .toList();
    if (selected.isEmpty) return;
    var stage = _selectedStage ?? '';
    final projects = Future.value(
      _project == null ? <ProjectEntry>[] : [_project!],
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置照片阶段'),
        content: StatefulBuilder(
          builder: (context, update) => ProjectStageField(
            projectName: _projectName,
            projectId: _project?.id,
            selected: stage,
            projects: projects,
            onChanged: (value) => update(() => stage = value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final useCase =
        widget.assignPhotoStage ??
        (serviceLocator.isRegistered<AssignPhotoStage>()
            ? serviceLocator<AssignPhotoStage>()
            : null);
    if (useCase == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('照片阶段设置暂不可用')));
      return;
    }
    final result = await useCase(selected, stage);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.failureOrNull?.message ?? '已设置 ${result.valueOrNull} 张照片的阶段',
          ),
        ),
      );
    if (result.isSuccess) {
      _exitMultiSelectMode();
      unawaited(_photoCubit.loadEntries(background: true));
    }
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
    await _notesCubit.loadEntries(background: true);
    if (!mounted) return;
    if (_notesCubit.state.failure != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('读取项目文字记录失败，请重试后再删除。')),
      );
      return;
    }
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
    final expenseItems = _allProjectExpenses;
    final mediaCount = projectPhotos.length;
    final evidenceCount = evidenceItems.length;
    final expenseCount = expenseItems.length;
    final tripCount = _tripsCubit.state.entries.length;
    final noteCount = _notesCubit.state.entries.length;
    final hasChildren =
        evidenceCount + expenseCount + tripCount + noteCount > 0;
    final message = hasChildren
        ? "删除项目「$_projectName」后会删除 $noteCount 条文字记录、$evidenceCount 份凭证和 $expenseCount 条项目费用，解除 $tripCount 条已关联的出差记录；$mediaCount 张项目照片将保留并移除项目关联。同步项目会先标记为待删除，待同步完成后再清理。"
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

  Future<void> _showProjectStagesDialog(ProjectEntry project) =>
      showProjectStagesSheet(
        context,
        project: project,
        cubit: _projectCubit,
        historicalNames: [
          ..._photoCubit.state.entries
              .where(
                (e) => _scope.contains(name: e.projectName, id: e.projectId),
              )
              .map((e) => e.projectStageName ?? ''),
          ..._allProjectExpenses.map((e) => e.projectStageName ?? ''),
          ..._evidenceCubit.state.entries
              .where(
                (e) => _scope.contains(
                  name: e.projectName,
                  id: e.projectId,
                  syncId: e.projectSyncId,
                ),
              )
              .map((e) => e.projectStageName ?? ''),
          ..._tripsCubit.state.entries.map((e) => e.projectStageName ?? ''),
          ..._notesCubit.state.entries.map((e) => e.projectStageName ?? ''),
        ],
      );

  Future<void> _chooseStage(List<ProjectStageSummary> summaries) async {
    final ordered = [
      ...summaries.where((s) => s.name.isNotEmpty),
      ...summaries.where((s) => s.name.isEmpty),
    ];
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheetScaffold(
        title: '选择阶段',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择阶段，查看或补记这一环节的记录。'),
            ListTile(
              title: const Text('全部阶段'),
              trailing: _selectedStage == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () {
                setState(() {
                  _selectedStage = null;
                  _selectedPhotoIds.clear();
                  _isMultiSelectMode = false;
                });
                Navigator.of(sheetContext).pop();
              },
            ),
            for (var index = 0; index < ordered.length; index++)
              ListTile(
                title: Text(
                  ordered[index].name.isEmpty
                      ? '未分阶段'
                      : '${index + 1}. ${ordered[index].name}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final part in _stageRecordSummary(
                          ordered[index],
                        ).split(' · '))
                          Text(part),
                      ],
                    ),
                    for (final code
                        in (ordered[index].totals.keys.toList()..sort()))
                      Text(projectAmount(ordered[index].totals[code]!, code)),
                  ],
                ),
                trailing: _selectedStage == ordered[index].name
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStage = ordered[index].name;
                    _selectedPhotoIds.clear();
                    _isMultiSelectMode = false;
                  });
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('管理阶段顺序'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                if (_project != null) {
                  unawaited(_showProjectStagesDialog(_project!));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _stageRecordSummary(ProjectStageSummary stage) {
    final parts = [
      if (stage.notes > 0) '${stage.notes} 条文字',
      if (stage.photos > 0) '${stage.photos} 张照片',
      if (stage.trips > 0) '${stage.trips} 条出差',
      if (stage.expenses > 0) '${stage.expenses} 笔支出',
      if (stage.evidence > 0) '${stage.evidence} 份凭证',
    ];
    return parts.isEmpty ? '暂无记录' : parts.join(' · ');
  }
}

class _ChannelOutlineEntry {
  final Object row;
  final bool hasFollowingDay;
  final bool continuesDay;

  const _ChannelOutlineEntry(
    this.row, {
    this.hasFollowingDay = false,
    this.continuesDay = false,
  });
}

class _ChannelMonth {
  final String key;
  final List<_ChannelDay> days;

  _ChannelMonth(this.key, this.days);

  int get recordCount => days.fold(0, (total, day) => total + day.items.length);
}

class _ChannelDay {
  final String key;
  final List<_DetailTimelineItem> items;

  _ChannelDay(this.key, this.items);
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
  final String? content;

  const _DetailTimelineItem({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.icon,
    required this.iconColor,
    required this.rawItem,
    this.content,
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
