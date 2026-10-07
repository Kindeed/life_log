import 'package:flutter/material.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';

/// Additive editing: stage names are record relationship keys. Keep old names
/// rather than silently renaming/deleting their photos and financial history.
Future<void> showProjectStagesSheet(
  BuildContext context, {
  required ProjectEntry project,
  required ProjectCubit cubit,
  Iterable<String> historicalNames = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _StagesSheet(
      project: project,
      cubit: cubit,
      historicalNames: historicalNames,
    ),
  );
}

class _StagesSheet extends StatefulWidget {
  final ProjectEntry project;
  final ProjectCubit cubit;
  final Iterable<String> historicalNames;
  const _StagesSheet({
    required this.project,
    required this.cubit,
    required this.historicalNames,
  });
  @override
  State<_StagesSheet> createState() => _StagesSheetState();
}

class _StagesSheetState extends State<_StagesSheet> {
  final _name = TextEditingController();
  late final List<String> _names;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _names = <String>{
      ...widget.project.stageNames,
      ...widget.historicalNames.where((name) => name.isNotEmpty),
    }.toList();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _append() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入阶段名称');
      return;
    }
    if (_names.any((value) => value.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = '这个阶段已存在');
      return;
    }
    setState(() {
      _names.add(name);
      _name.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    // Do not silently discard a typed new name on Save.
    if (_name.text.trim().isNotEmpty) {
      _append();
      if (_error != null) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await widget.cubit.saveStageNames(widget.project, _names);
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = failure.message;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('项目阶段已保存，历史记录保留')));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AppSheetScaffold(
        title: '项目阶段',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('按工作顺序添加阶段；之前的阶段和记录会一直保留。'),
            const SizedBox(height: 12),
            for (var index = 0; index < _names.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text('${index + 1}'),
                title: Text(_names[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '前移 ${_names[index]}',
                      icon: const Icon(Icons.arrow_upward_rounded),
                      onPressed: _saving || index == 0
                          ? null
                          : () => setState(() {
                              final name = _names.removeAt(index);
                              _names.insert(index - 1, name);
                            }),
                    ),
                    IconButton(
                      tooltip: '后移 ${_names[index]}',
                      icon: const Icon(Icons.arrow_downward_rounded),
                      onPressed: _saving || index == _names.length - 1
                          ? null
                          : () => setState(() {
                              final name = _names.removeAt(index);
                              _names.insert(index + 1, name);
                            }),
                    ),
                  ],
                ),
              ),
            AppTextField(
              controller: _name,
              enabled: !_saving,
              labelText: '新增阶段',
              hintText: '例如：勘查、施工、验收',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving ? null : _append,
              icon: const Icon(Icons.add_rounded),
              label: const Text('追加阶段'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                AppButton.primary(
                  label: '保存阶段',
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
