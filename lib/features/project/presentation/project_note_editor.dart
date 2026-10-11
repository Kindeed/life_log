import 'package:flutter/material.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:life_log/common/widgets/app_date_picker.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_feedback.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/common/widgets/app_unsaved_changes_guard.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/application/delete_project_note_entry.dart';
import 'package:life_log/features/project/application/save_project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/presentation/project_stage_field.dart';

Future<bool?> showProjectNoteEditor(
  BuildContext context, {
  required ProjectEntry project,
  ProjectNoteEntry? existing,
  String? initialStage,
}) => showAppBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: Colors.transparent,
  builder: (_) => ProjectNoteEditor(
    project: project,
    existing: existing,
    initialStage: initialStage,
  ),
);

class ProjectNoteEditor extends StatefulWidget {
  final ProjectEntry project;
  final ProjectNoteEntry? existing;
  final String? initialStage;
  final SaveProjectNoteEntry? saveEntry;
  final DeleteProjectNoteEntry? deleteEntry;

  const ProjectNoteEditor({
    super.key,
    required this.project,
    this.existing,
    this.initialStage,
    this.saveEntry,
    this.deleteEntry,
  });

  @override
  State<ProjectNoteEditor> createState() => _ProjectNoteEditorState();
}

class _ProjectNoteEditorState extends State<ProjectNoteEditor> {
  late final TextEditingController _content;
  late final Future<List<ProjectEntry>> _projects;
  late final SaveProjectNoteEntry _saveEntry;
  late final Object? _editingContext;
  late final DateTime _initialDate;
  late final String _initialStage;
  late DateTime _date;
  late String _stage;
  bool _busy = false;
  bool _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.existing?.content ?? '');
    _date = widget.existing?.date ?? DateUtils.dateOnly(DateTime.now());
    _stage = widget.existing != null
        ? widget.existing!.projectStageName ?? ''
        : widget.initialStage?.trim() ?? '';
    _initialDate = _date;
    _initialStage = _stage;
    _projects = Future.value([widget.project]);
    _saveEntry = widget.saveEntry ?? serviceLocator<SaveProjectNoteEntry>();
    _editingContext = _saveEntry.captureContext();
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  bool get _changed =>
      _content.text != (widget.existing?.content ?? '') ||
      _date != _initialDate ||
      _stage != _initialStage;

  Future<void> _chooseDate() async {
    final picked = await showLifeLogDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null && mounted && !_busy) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final content = _content.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '请填写记录内容');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final now = DateTime.now();
    final old = widget.existing;
    final result = await _saveEntry(
      ProjectNoteEntry(
        id: old?.id ?? 0,
        projectId: old == null ? widget.project.id : old.projectId,
        projectSyncId: old == null ? widget.project.syncId : old.projectSyncId,
        projectName: widget.project.name,
        projectStageName: _stage.isEmpty ? null : _stage,
        content: content,
        date: _date,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ),
      expectedContext: _editingContext,
    );
    if (!mounted) return;
    if (result.failureOrNull != null) {
      setState(() {
        _busy = false;
        _error = result.failureOrNull!.message;
      });
      return;
    }
    await _complete('文字记录已保存');
  }

  Future<void> _delete() async {
    if (_busy || widget.existing == null) return;
    // Keep the editor locked while the confirmation is open.
    setState(() => _busy = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文字记录？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }
    final delete =
        widget.deleteEntry ?? serviceLocator<DeleteProjectNoteEntry>();
    final result = await delete(
      widget.existing!.id,
      expectedContext: _editingContext,
    );
    if (!mounted) return;
    if (result.failureOrNull != null) {
      setState(() {
        _busy = false;
        _error = result.failureOrNull!.message;
      });
      return;
    }
    await _complete('文字记录已删除');
  }

  Future<void> _complete(String message) async {
    final feedback = AppFeedback.capture(context);
    setState(() {
      _finished = true;
      _busy = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.of(context).pop(true);
    feedback.success(message);
  }

  @override
  Widget build(BuildContext context) => AppUnsavedChangesGuard(
    hasChanges: !_finished && _changed,
    busy: _busy,
    child: AppSheetScaffold(
      title: widget.existing == null ? '写文字记录' : '编辑文字记录',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.project.name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '记录设备状态、现场情况、沟通事项或待跟进的问题。文字记录保存在本机，可随本地备份导出。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _content,
            enabled: !_busy,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            labelText: '记录内容',
            hintText: '今天发生了什么，需要记下什么…',
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 16),
          ProjectStageField(
            projectName: widget.project.name,
            projectId: widget.project.id,
            selected: _stage,
            projects: _projects,
            enabled: !_busy,
            onChanged: (value) => setState(() => _stage = value),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('记录日期'),
            subtitle: Text(formatDateYmd(_date)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _busy ? null : _chooseDate,
          ),
          if (_error != null) AppFormFeedback(message: _error!),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('取消'),
              ),
              if (widget.existing != null)
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: Text(
                    '删除',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              AppButton.primary(
                label: '保存记录',
                isLoading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
