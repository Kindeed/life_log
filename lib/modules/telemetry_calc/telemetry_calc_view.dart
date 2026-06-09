import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/layout/app_breakpoints.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/theme/app_motion.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_semantic_colors.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_filter_chip_bar.dart';
import 'package:life_log/common/widgets/app_pill.dart';
import 'package:life_log/common/widgets/app_section_header.dart';
import 'package:life_log/common/widgets/app_text_field.dart';

import 'telemetry_calculators.dart';
import 'formula_library.dart';
import 'telemetry_template_store.dart';
import 'telemetry_units.dart';

enum _TelemetryCalcHomeMode { workbench, library }

class TelemetryCalcView extends StatefulWidget {
  final TelemetryTemplateStore? templateStore;

  const TelemetryCalcView({super.key, this.templateStore});

  @override
  State<TelemetryCalcView> createState() => _TelemetryCalcViewState();
}

class _TelemetryCalcViewState extends State<TelemetryCalcView> {
  late final TelemetryTemplateStore _store;
  final _formulaLibrary = FormulaLibraryRepository();
  final _searchController = TextEditingController();
  var _mode = _TelemetryCalcHomeMode.workbench;
  var _category = TelemetryCalculatorCategory.link;
  var _formulaDomain = FormulaDomain.rfAntennaReceiver;
  var _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _store = widget.templateStore ?? TelemetryTemplateStore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final sourceDefinitions = normalizedQuery.isEmpty
        ? TelemetryCalculatorRegistry.definitions.where(
            (definition) => definition.category == _category,
          )
        : TelemetryCalculatorRegistry.definitions;
    final definitions = sourceDefinitions
        .where(
          (definition) =>
              normalizedQuery.isEmpty ||
              _matchesSearchQuery(definition, normalizedQuery),
        )
        .toList(growable: false);
    final formulaEntries = normalizedQuery.isEmpty
        ? _formulaLibrary.byDomain(_formulaDomain)
        : _formulaLibrary.search(normalizedQuery);
    final recent = _store.loadRecent();

    return Scaffold(
      appBar: AppBar(title: const Text('遥测遥控计算')),
      body: SafeArea(
        child: ConstrainedPage(
          child: CustomScrollView(
            cacheExtent: 900,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg.w,
                    AppSpacing.md.h,
                    AppSpacing.lg.w,
                    AppSpacing.sm.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(semantic: semantic),
                      if (recent.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.xl.h),
                        _RecentTemplates(
                          templates: recent,
                          onTap: _openTemplate,
                          onLongPress: _showRecentTemplateActions,
                        ),
                      ],
                      SizedBox(height: AppSpacing.xl.h),
                      AppTextField(
                        key: const ValueKey('telemetryCalcSearchField'),
                        controller: _searchController,
                        hintText: _mode == _TelemetryCalcHomeMode.workbench
                            ? '搜索计算器'
                            : '搜索公式、参数、来源',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                key: const ValueKey('telemetryCalcSearchClear'),
                                tooltip: '清除搜索',
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        textInputAction: TextInputAction.search,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      SizedBox(height: AppSpacing.xl.h),
                      Center(
                        key: const ValueKey('telemetryModeSwitcherCenter'),
                        child: SegmentedButton<_TelemetryCalcHomeMode>(
                          segments: const [
                            ButtonSegment(
                              value: _TelemetryCalcHomeMode.workbench,
                              icon: Icon(Icons.calculate_rounded),
                              label: Text('工作台'),
                            ),
                            ButtonSegment(
                              value: _TelemetryCalcHomeMode.library,
                              icon: Icon(Icons.library_books_rounded),
                              label: Text('公式库'),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (values) =>
                              setState(() => _mode = values.single),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl.h),
                      AppSectionHeader(
                        title: _mode == _TelemetryCalcHomeMode.workbench
                            ? '计算分类'
                            : '公式分类',
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      Center(
                        key: const ValueKey('telemetryCategoryFilterCenter'),
                        child: _mode == _TelemetryCalcHomeMode.workbench
                            ? AppFilterChipBar<TelemetryCalculatorCategory>(
                                value: _category,
                                onChanged: (value) =>
                                    setState(() => _category = value),
                                items: [
                                  for (final category
                                      in TelemetryCalculatorCategory.values)
                                    AppFilterChipItem(
                                      value: category,
                                      label: _categoryFilterLabel(category),
                                      icon: _categoryIcon(category),
                                    ),
                                ],
                              )
                            : _FormulaDomainChips(
                                summaries: _formulaLibrary.domainSummaries,
                                value: _formulaDomain,
                                onChanged: (value) =>
                                    setState(() => _formulaDomain = value),
                              ),
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                    ],
                  ),
                ),
              ),
              if (_mode == _TelemetryCalcHomeMode.workbench)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg.w,
                    0,
                    AppSpacing.lg.w,
                    AppSpacing.xxl.h,
                  ),
                  sliver: SliverGrid.builder(
                    itemCount: definitions.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width >= 720
                          ? 2
                          : 1,
                      mainAxisSpacing: AppSpacing.md.h,
                      crossAxisSpacing: AppSpacing.md.w,
                      mainAxisExtent: 132.h,
                    ),
                    itemBuilder: (context, index) {
                      final definition = definitions[index];
                      return _CalculatorCard(
                        definition: definition,
                        color: _categoryColor(definition.category, semantic),
                        onTap: () => Get.to(
                          () => TelemetryCalcDetailView(definition: definition),
                        )?.then((_) => setState(() {})),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg.w,
                    0,
                    AppSpacing.lg.w,
                    AppSpacing.xxl.h,
                  ),
                  sliver: SliverList.separated(
                    itemCount: formulaEntries.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppSpacing.md.h),
                    itemBuilder: (context, index) {
                      final entry = formulaEntries[index];
                      return _FormulaLibraryCard(
                        entry: entry,
                        onTap: () => Get.to(
                          () => FormulaLibraryDetailView(entry: entry),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTemplate(TelemetryTemplate template) {
    final definition = TelemetryCalculatorRegistry.byId(template.calculatorId);
    Get.to(
      () => TelemetryCalcDetailView(
        definition: definition,
        initialValues: template.values,
      ),
    )?.then((_) => setState(() {}));
  }

  void _showRecentTemplateActions(TelemetryTemplate template) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('重命名模板'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _renameRecentTemplate(template);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('删除模板'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _store.deleteTemplate(template.id);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameRecentTemplate(TelemetryTemplate template) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _TemplateNameDialog(title: '重命名模板', initialName: template.name),
    );
    if (name == null) return;
    await _store.renameTemplate(template.id, name);
    if (mounted) setState(() {});
  }

  bool _matchesSearchQuery(
    TelemetryCalculatorDefinition definition,
    String query,
  ) {
    final fields = [
      definition.title,
      _detailTitle(definition),
      definition.subtitle,
      definition.standards,
      _categoryLabel(definition.category),
    ];
    return fields.any((field) => field.toLowerCase().contains(query));
  }
}

class TelemetryCalcDetailView extends StatefulWidget {
  final TelemetryCalculatorDefinition definition;
  final Map<String, TelemetryInputValue>? initialValues;
  final TelemetryTemplateStore? templateStore;

  const TelemetryCalcDetailView({
    super.key,
    required this.definition,
    this.initialValues,
    this.templateStore,
  });

  @override
  State<TelemetryCalcDetailView> createState() =>
      _TelemetryCalcDetailViewState();
}

class _TelemetryCalcDetailViewState extends State<TelemetryCalcDetailView> {
  late final TelemetryTemplateStore _store;
  final _controllers = <String, TextEditingController>{};
  late Map<String, TelemetryInputValue> _values;
  late TelemetryCalculationResult _result;
  var _showAdvanced = false;
  String? _templateSaveNotice;

  @override
  void initState() {
    super.initState();
    _store = widget.templateStore ?? TelemetryTemplateStore();
    _values = {
      ...TelemetryCalculatorRegistry.defaultValues(widget.definition),
      ...?widget.initialValues,
    };
    for (final input in widget.definition.inputs) {
      final value = _values[input.id];
      final text = input.kind == TelemetryInputKind.expression
          ? value?.text ?? input.defaultText ?? ''
          : _formatInputNumber(value?.value ?? input.defaultValue);
      _controllers[input.id] = TextEditingController(text: text);
    }
    _result = TelemetryCalculatorEngine.calculate(widget.definition, _values);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final color = _categoryColor(widget.definition.category, semantic);
    final primaryInputs = widget.definition.inputs
        .where((input) => !input.advanced)
        .toList(growable: false);
    final advancedInputs = widget.definition.inputs
        .where((input) => input.advanced)
        .toList(growable: false);
    final shortPrimaryInputs = primaryInputs
        .where(_isShortInput)
        .toList(growable: false);
    final longPrimaryInputs = primaryInputs
        .where((input) => !_isShortInput(input))
        .toList(growable: false);
    final orderedPrimaryInputs = [...shortPrimaryInputs, ...longPrimaryInputs];
    final shortAdvancedInputs = advancedInputs
        .where(_isShortInput)
        .toList(growable: false);
    final longAdvancedInputs = advancedInputs
        .where((input) => !_isShortInput(input))
        .toList(growable: false);
    final orderedAdvancedInputs = [
      ...shortAdvancedInputs,
      ...longAdvancedInputs,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_detailTitle(widget.definition)),
        actions: [
          IconButton(
            tooltip: '公式与依据',
            onPressed: _showFormulaSheet,
            icon: const Icon(Icons.menu_book_rounded),
          ),
          IconButton(
            tooltip: '载入模板',
            onPressed: _showTemplates,
            icon: const Icon(Icons.folder_open_rounded),
          ),
          IconButton(
            tooltip: '恢复默认',
            onPressed: _resetDefaults,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '保存模板',
            onPressed: _saveTemplate,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ConstrainedPage(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.w,
              AppSpacing.md.h,
              AppSpacing.lg.w,
              AppSpacing.xxl.h,
            ),
            children: [
              _DetailHeader(definition: widget.definition, color: color),
              if (_templateSaveNotice != null) ...[
                SizedBox(height: AppSpacing.md.h),
                _InlineNotice(message: _templateSaveNotice!, color: color),
              ],
              SizedBox(height: AppSpacing.md.h),
              AppCard(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CalculationWorkbench(
                      result: _result,
                      color: color,
                      primaryInputs: [
                        for (final input in orderedPrimaryInputs)
                          _CompactInputItem(
                            child: _buildCompactInput(input),
                            isShort: _isShortInput(input),
                          ),
                      ],
                      advancedInputs: [
                        for (final input in orderedAdvancedInputs)
                          _CompactInputItem(
                            child: _buildCompactInput(input),
                            isShort: _isShortInput(input),
                          ),
                      ],
                      showAdvanced: _showAdvanced,
                      onToggleAdvanced: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput(TelemetryInputDefinition input) {
    return switch (input.kind) {
      TelemetryInputKind.number => _CompactNumberInput(
        input: input,
        value: _values[input.id]!,
        controller: _controllers[input.id]!,
        onChanged: _updateNumber,
        onUnitChanged: _updateUnit,
      ),
      TelemetryInputKind.select => _CompactSelectInput(
        input: input,
        selectedId: _values[input.id]!.optionId ?? input.defaultOptionId ?? '',
        onChanged: _updateOption,
      ),
      TelemetryInputKind.expression => _CompactExpressionInput(
        input: input,
        controller: _controllers[input.id]!,
        onChanged: _updateExpression,
      ),
    };
  }

  void _updateNumber(String id, String text) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: double.tryParse(text.trim()),
        unitId: old.unitId,
        optionId: old.optionId,
        text: old.text,
      ),
    };
    _recalculate();
  }

  void _updateUnit(String id, String unitId) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: old.value,
        unitId: unitId,
        optionId: old.optionId,
        text: old.text,
      ),
    };
    _recalculate();
  }

  void _updateOption(String id, String optionId) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: old.value,
        unitId: old.unitId,
        optionId: optionId,
        text: old.text,
      ),
    };
    _recalculate();
  }

  void _updateExpression(String id, String text) {
    final old = _values[id]!;
    _values = {
      ..._values,
      id: TelemetryInputValue(
        value: old.value,
        unitId: old.unitId,
        optionId: old.optionId,
        text: text,
      ),
    };
    _recalculate();
  }

  void _recalculate() {
    setState(() {
      _result = TelemetryCalculatorEngine.calculate(widget.definition, _values);
    });
  }

  void _showFormulaSheet() {
    final theme = Theme.of(context);
    final color = _categoryColor(
      widget.definition.category,
      theme.semanticColors,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.w,
              AppSpacing.lg.h,
              AppSpacing.lg.w,
              AppSpacing.xxl.h,
            ),
            child: ConstrainedPage(
              child: _FormulaPanel(definition: widget.definition, color: color),
            ),
          ),
        );
      },
    );
  }

  void _resetDefaults() {
    setState(() {
      _values = TelemetryCalculatorRegistry.defaultValues(widget.definition);
      for (final input in widget.definition.inputs) {
        final value = _values[input.id];
        _controllers[input.id]?.text =
            input.kind == TelemetryInputKind.expression
            ? value?.text ?? ''
            : _formatInputNumber(value?.value);
      }
      _result = TelemetryCalculatorEngine.calculate(widget.definition, _values);
    });
  }

  Future<void> _saveTemplate() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _TemplateNameDialog(
        title: '保存模板',
        initialName: '${widget.definition.title}模板',
      ),
    );
    if (name == null) return;
    await _store.saveTemplate(widget.definition.id, name, _values);
    if (mounted) {
      setState(() {
        final label = name.trim().isEmpty ? '未命名模板' : name.trim();
        _templateSaveNotice = '模板已保存：$label';
      });
    }
  }

  void _showTemplates() {
    final templates = _store.loadTemplates(widget.definition.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (templates.isEmpty) {
          return const SizedBox(
            height: 260,
            child: AppEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: '暂无模板',
              message: '保存常用参数后可以从这里快速载入。',
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: Text(template.name),
                subtitle: Text(_formatDateTime(template.updatedAt)),
                trailing: IconButton(
                  tooltip: '删除模板',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    await _store.deleteTemplate(template.id);
                    if (mounted) {
                      Get.back();
                      _showTemplates();
                    }
                  },
                ),
                onTap: () {
                  setState(() {
                    _values = {
                      ...TelemetryCalculatorRegistry.defaultValues(
                        widget.definition,
                      ),
                      ...template.values,
                    };
                    for (final input in widget.definition.inputs) {
                      final value = _values[input.id];
                      _controllers[input.id]?.text =
                          input.kind == TelemetryInputKind.expression
                          ? value?.text ?? ''
                          : _formatInputNumber(value?.value);
                    }
                    _result = TelemetryCalculatorEngine.calculate(
                      widget.definition,
                      _values,
                    );
                  });
                  Get.back();
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TemplateNameDialog extends StatefulWidget {
  final String title;
  final String initialName;

  const _TemplateNameDialog({required this.title, required this.initialName});

  @override
  State<_TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<_TemplateNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '模板名称'),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final Color color;

  const _InlineNotice({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.md.h,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 18.sp),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class FormulaLibraryDetailView extends StatelessWidget {
  final FormulaLibraryEntry entry;

  const FormulaLibraryDetailView({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final color = _formulaDomainColor(entry.domain, semantic);
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.id),
        actions: [
          IconButton(
            tooltip: '复制公式',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: entry.expression));
              Get.snackbar('已复制', entry.id);
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ConstrainedPage(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            children: [
              AppCard(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm.w,
                      runSpacing: AppSpacing.xs.h,
                      children: [
                        AppPill(
                          label: entry.domain.label,
                          icon: _formulaDomainIcon(entry.domain),
                          color: color,
                        ),
                        AppPill(label: entry.status.label, color: color),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    _FormulaMathBlock(
                      expression: entry.expression,
                      texExpression: entry.texExpression,
                      color: color,
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    Text(
                      entry.explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Text(
                      entry.sourceFamily,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              const AppSectionHeader(title: '参数说明'),
              SizedBox(height: AppSpacing.md.h),
              for (final variable in entry.variables) ...[
                _FormulaVariableCard(variable: variable, color: color),
                SizedBox(height: AppSpacing.sm.h),
              ],
              if (entry.relatedCalculatorIds.isNotEmpty) ...[
                SizedBox(height: AppSpacing.lg.h),
                const AppSectionHeader(title: '关联工作台'),
                SizedBox(height: AppSpacing.md.h),
                for (final calculatorId in entry.relatedCalculatorIds)
                  _RelatedCalculatorTile(calculatorId: calculatorId),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormulaVariableCard extends StatelessWidget {
  final FormulaVariableInfo variable;
  final Color color;

  const _FormulaVariableCard({required this.variable, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.md.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              variable.displaySymbol,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variable.meaning,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (variable.concept.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    variable.concept,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  variable.units.isEmpty
                      ? '单位：按公式上下文确定'
                      : '单位：${variable.units}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCalculatorTile extends StatelessWidget {
  final String calculatorId;

  const _RelatedCalculatorTile({required this.calculatorId});

  @override
  Widget build(BuildContext context) {
    final definition = TelemetryCalculatorRegistry.byId(calculatorId);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: AppCard(
        onTap: () =>
            Get.to(() => TelemetryCalcDetailView(definition: definition)),
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Row(
          children: [
            Icon(_categoryIcon(definition.category), size: 22.sp),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Text(
                definition.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppSemanticColors semantic;

  const _Header({required this.semantic});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: semantic.stats.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.settings_input_antenna_rounded,
              color: semantic.stats,
              size: 28.sp,
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '工程计算工具箱',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  '${TelemetryCalculatorRegistry.formulaCatalogEntryCount} 条公式 / ${TelemetryCalculatorRegistry.definitions.length} 个工作台',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTemplates extends StatelessWidget {
  final List<TelemetryTemplate> templates;
  final ValueChanged<TelemetryTemplate> onTap;
  final ValueChanged<TelemetryTemplate> onLongPress;

  const _RecentTemplates({
    required this.templates,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '最近模板'),
        SizedBox(height: AppSpacing.md.h),
        SizedBox(
          height: 86.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
            itemBuilder: (context, index) {
              final template = templates[index];
              final definition = TelemetryCalculatorRegistry.byId(
                template.calculatorId,
              );
              return SizedBox(
                width: 220.w,
                child: GestureDetector(
                  onLongPress: () => onLongPress(template),
                  child: AppCard(
                    onTap: () => onTap(template),
                    padding: EdgeInsets.all(AppSpacing.md.w),
                    child: Row(
                      children: [
                        Icon(_categoryIcon(definition.category), size: 24.sp),
                        SizedBox(width: AppSpacing.md.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                template.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs.h),
                              Text(
                                definition.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12.sp,
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
}

class _FormulaDomainChips extends StatelessWidget {
  final List<FormulaDomainSummary> summaries;
  final FormulaDomain value;
  final ValueChanged<FormulaDomain> onChanged;

  const _FormulaDomainChips({
    required this.summaries,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm.w,
      runSpacing: AppSpacing.sm.h,
      children: [
        for (final summary in summaries)
          ChoiceChip(
            selected: summary.domain == value,
            label: Text('${summary.domain.label} ${summary.count}'),
            avatar: Icon(
              _formulaDomainIcon(summary.domain),
              size: 16.sp,
              color: summary.domain == value
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (_) => onChanged(summary.domain),
          ),
      ],
    );
  }
}

class _FormulaLibraryCard extends StatelessWidget {
  final FormulaLibraryEntry entry;
  final VoidCallback onTap;

  const _FormulaLibraryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    return AppCard(
      key: const ValueKey('formulaDirectoryCard'),
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.lg.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: semantic.stats.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(
              _formulaDomainIcon(entry.domain),
              color: semantic.stats,
              size: 22.sp,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm.w,
                  runSpacing: AppSpacing.xs.h,
                  children: [
                    AppPill(
                      label: entry.id,
                      icon: Icons.article_outlined,
                      color: semantic.stats,
                    ),
                    AppPill(
                      label: entry.status.label,
                      color: entry.status == FormulaStatus.implemented
                          ? semantic.success
                          : semantic.warning,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  entry.explanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  entry.domain.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22.sp,
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final TelemetryCalculatorDefinition definition;
  final Color color;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.definition,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.lg.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_categoryIcon(definition.category), color: color),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Text(
                  definition.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            definition.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
              height: 1.3,
            ),
          ),
          const Spacer(),
          Text(
            definition.standards,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final TelemetryCalculatorDefinition definition;
  final Color color;

  const _DetailHeader({required this.definition, required this.color});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs.w,
        AppSpacing.xs.h,
        AppSpacing.xs.w,
        AppSpacing.xs.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_categoryIcon(definition.category), color: color),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detailTitle(definition),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  definition.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Wrap(
                  spacing: AppSpacing.sm.w,
                  runSpacing: AppSpacing.sm.h,
                  children: [
                    _InfoPill(
                      label: _categoryLabel(definition.category),
                      color: color,
                    ),
                    _InfoPill(
                      label: '本地计算',
                      color: Theme.of(context).semanticColors.success,
                    ),
                    _InfoPill(label: definition.standards, color: color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 220.w),
      child: AppPill(label: label, color: color),
    );
  }
}

class _CompactInputItem {
  final Widget child;
  final bool isShort;

  const _CompactInputItem({required this.child, required this.isShort});
}

class _CalculationWorkbench extends StatelessWidget {
  static const _twoColumnMinWidth = AppBreakpoints.tabletMin - 40;

  final TelemetryCalculationResult result;
  final Color color;
  final List<_CompactInputItem> primaryInputs;
  final List<_CompactInputItem> advancedInputs;
  final bool showAdvanced;
  final VoidCallback onToggleAdvanced;

  const _CalculationWorkbench({
    required this.result,
    required this.color,
    required this.primaryInputs,
    required this.advancedInputs,
    required this.showAdvanced,
    required this.onToggleAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    final outputPane = _WorkbenchPane(
      title: '输出',
      subtitle: '含工程判断',
      icon: Icons.analytics_outlined,
      color: color,
      emphasized: true,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.standardDecelerate,
        switchOutCurve: AppMotion.standard,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: _CompactResultPanel(
          key: ValueKey(_resultSignature(result)),
          result: result,
          color: color,
        ),
      ),
    );
    final inputPane = _WorkbenchPane(
      title: '输入',
      subtitle: '实时刷新输出',
      icon: Icons.tune_rounded,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactInputGrid(items: primaryInputs),
          if (advancedInputs.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm.h),
            _AdvancedToggle(expanded: showAdvanced, onTap: onToggleAdvanced),
            AnimatedSize(
              duration: AppMotion.normal,
              curve: AppMotion.standardDecelerate,
              alignment: Alignment.topCenter,
              child: showAdvanced
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppSpacing.md.h),
                        _CompactInputGrid(items: advancedInputs),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              outputPane,
              SizedBox(height: AppSpacing.md.h),
              inputPane,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: inputPane),
            SizedBox(width: AppSpacing.md.w),
            Expanded(flex: 10, child: outputPane),
          ],
        );
      },
    );
  }
}

class _CompactInputGrid extends StatelessWidget {
  final List<_CompactInputItem> items;

  const _CompactInputGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.sm.w;
        final canUseTwoColumns = constraints.maxWidth >= 560.w;
        return Wrap(
          key: const ValueKey('compactInputTileWrap'),
          spacing: gap,
          runSpacing: AppSpacing.sm.h,
          children: [
            for (final item in items)
              SizedBox(
                width: canUseTwoColumns && item.isShort
                    ? (constraints.maxWidth - gap) / 2
                    : constraints.maxWidth,
                child: item.child,
              ),
          ],
        );
      },
    );
  }
}

class _CompactResultPanel extends StatelessWidget {
  final TelemetryCalculationResult result;
  final Color color;

  const _CompactResultPanel({
    super.key,
    required this.result,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (result.hasErrors) {
      return _StatusPanel(
        icon: Icons.error_outline_rounded,
        color: theme.colorScheme.error,
        title: '等待有效输入',
        message: result.errors.join('\n'),
      );
    }
    final insight = _resultInsight(context, result.outputs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = AppSpacing.sm.w;
            final canUseTwoColumns = constraints.maxWidth >= 260.w;
            final shortOutputs = result.outputs
                .where(_isShortOutput)
                .toList(growable: false);
            final longOutputs = result.outputs
                .where((output) => !_isShortOutput(output))
                .toList(growable: false);
            final orderedOutputs = [...shortOutputs, ...longOutputs];
            return Wrap(
              key: const ValueKey('adaptiveResultTileWrap'),
              spacing: gap,
              runSpacing: AppSpacing.sm.h,
              children: [
                for (final output in orderedOutputs)
                  SizedBox(
                    width: canUseTwoColumns && _isShortOutput(output)
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth,
                    child: _AdaptiveResultTile(output: output, color: color),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: AppSpacing.sm.h),
        _OutputInsightPanel(insight: insight),
      ],
    );
  }
}

class _AdaptiveResultTile extends StatelessWidget {
  final TelemetryCalculationOutput output;
  final Color color;

  const _AdaptiveResultTile({required this.output, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _outputStatusColor(context, output, color);
    final tileColor = Color.alphaBlend(
      color.withValues(alpha: 0.06),
      theme.semanticColors.mutedSurface,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 170.w;
        return Container(
          key: const ValueKey('adaptiveResultTile'),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.sm.h,
          ),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.semanticColors.border),
          ),
          child: narrow
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    key: const ValueKey('adaptiveResultTileInlineRow'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ResultLabel(output: output),
                      SizedBox(width: AppSpacing.md.w),
                      _ResultValue(output: output, color: statusColor),
                    ],
                  ),
                )
              : Row(
                  key: const ValueKey('adaptiveResultTileInlineRow'),
                  children: [
                    Expanded(child: _ResultLabel(output: output)),
                    SizedBox(width: AppSpacing.md.w),
                    _ResultValue(output: output, color: statusColor),
                  ],
                ),
        );
      },
    );
  }
}

class _ResultLabel extends StatelessWidget {
  final TelemetryCalculationOutput output;

  const _ResultLabel({required this.output});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            output.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (output.helper.isNotEmpty) ...[
          SizedBox(width: AppSpacing.xs.w),
          Tooltip(
            message: output.helper,
            child: Icon(
              Icons.help_outline_rounded,
              size: 13.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultValue extends StatelessWidget {
  final TelemetryCalculationOutput output;
  final Color color;

  const _ResultValue({required this.output, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 88.w),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              output.displayValue,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Roboto',
                height: 1,
              ),
            ),
          ),
        ),
        if (output.unitLabel.isNotEmpty) ...[
          SizedBox(width: AppSpacing.xs.w),
          Container(
            constraints: BoxConstraints(maxWidth: 58.w),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs.w,
              vertical: AppSpacing.xs.h,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: theme.semanticColors.border),
            ),
            child: Text(
              output.unitLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
                height: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

bool _isShortOutput(TelemetryCalculationOutput output) {
  final lengthScore =
      _calculateTextWidthScore(output.label) +
      _calculateTextWidthScore(output.displayValue) +
      _calculateTextWidthScore(output.unitLabel);
  return lengthScore < 16 && output.unitLabel.length <= 4;
}

bool _isShortInput(TelemetryInputDefinition input) {
  if (input.kind == TelemetryInputKind.select) return false;
  final lengthScore =
      _calculateTextWidthScore(input.label) +
      _calculateTextWidthScore(input.units.isEmpty ? '' : input.units.first);
  return lengthScore < 16;
}

int _calculateTextWidthScore(String value) {
  var score = 0;
  for (final rune in value.runes) {
    score += rune > 255 ? 2 : 1;
  }
  return score;
}

class _WorkbenchPane extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final bool emphasized;

  const _WorkbenchPane({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withValues(alpha: 0.06)
            : theme.semanticColors.mutedSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: emphasized
              ? color.withValues(alpha: 0.24)
              : theme.semanticColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
          ),
          SizedBox(height: AppSpacing.md.h),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(icon, color: color, size: 17.sp),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.1,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  message,
                  style: TextStyle(color: color, fontSize: 12.sp, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultInsight {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _ResultInsight({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

class _OutputInsightPanel extends StatelessWidget {
  final _ResultInsight insight;

  const _OutputInsightPanel({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('compactInsightBar'),
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: insight.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color, size: 18.sp),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '工程判断',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: insight.color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  insight.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  insight.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _outputStatusColor(
  BuildContext context,
  TelemetryCalculationOutput output,
  Color fallback,
) {
  if ((output.id == 'margin' || output.id == 'guard_margin') &&
      output.value < 0) {
    return Theme.of(context).colorScheme.error;
  }
  if (output.id == 'margin' || output.id == 'guard_margin') {
    return Theme.of(context).semanticColors.success;
  }
  return fallback;
}

String _resultSignature(TelemetryCalculationResult result) {
  if (result.hasErrors) return result.errors.join('|');
  return result.outputs
      .map(
        (output) => '${output.id}:${output.displayValue}:${output.unitLabel}',
      )
      .join('|');
}

_ResultInsight _resultInsight(
  BuildContext context,
  List<TelemetryCalculationOutput> outputs,
) {
  final theme = Theme.of(context);
  final margin = _findOutput(outputs, 'margin');
  if (margin != null) {
    return _marginInsight(
      margin,
      passTitle: '链路余量满足要求',
      failTitle: '链路余量不足',
      passColor: theme.semanticColors.success,
      failColor: theme.colorScheme.error,
    );
  }

  final guardMargin = _findOutput(outputs, 'guard_margin');
  if (guardMargin != null) {
    final passed = guardMargin.value >= 0;
    final value = _outputValueLabel(guardMargin, absolute: !passed);
    return _ResultInsight(
      icon: passed
          ? Icons.check_circle_outline_rounded
          : Icons.warning_amber_rounded,
      color: passed ? theme.semanticColors.success : theme.colorScheme.error,
      title: passed ? '保护带覆盖误差' : '保护带不足',
      message: passed ? '余量 $value，覆盖误差。' : '缺口 $value，需加保护带。',
    );
  }

  final orbitEnergyMargin = _findOutput(outputs, 'orbit_energy_margin');
  if (orbitEnergyMargin != null) {
    return _marginInsight(
      orbitEnergyMargin,
      passTitle: '轨道能量闭合',
      failTitle: '轨道能量不足',
      passColor: theme.semanticColors.success,
      failColor: theme.colorScheme.error,
    );
  }

  final thermalLimitMargin = _findOutput(outputs, 'thermal_limit_margin');
  if (thermalLimitMargin != null) {
    return _marginInsight(
      thermalLimitMargin,
      passTitle: '热控限值满足',
      failTitle: '热控限值超差',
      passColor: theme.semanticColors.success,
      failColor: theme.colorScheme.error,
    );
  }

  final closureScore = _findOutput(outputs, 'closure_score');
  if (closureScore != null) {
    final passed = closureScore.value >= 0;
    final value = _outputValueLabel(closureScore, absolute: !passed);
    return _ResultInsight(
      icon: passed
          ? Icons.check_circle_outline_rounded
          : Icons.warning_amber_rounded,
      color: passed ? theme.semanticColors.success : theme.colorScheme.error,
      title: passed ? '资源闭合可用' : '资源闭合不足',
      message: passed ? '短板 $value，继续看分项。' : '缺口 $value，需调预算。',
    );
  }

  return _ResultInsight(
    icon: Icons.check_circle_outline_rounded,
    color: theme.semanticColors.success,
    title: '实时计算完成',
    message: '结果已更新，可继续调参。',
  );
}

_ResultInsight _marginInsight(
  TelemetryCalculationOutput output, {
  required String passTitle,
  required String failTitle,
  required Color passColor,
  required Color failColor,
}) {
  final passed = output.value >= 0;
  final value = _outputValueLabel(output);
  final message = passed ? '余量 $value，配置可用。' : '余量 $value，需调整预算。';
  return _ResultInsight(
    icon: passed
        ? Icons.check_circle_outline_rounded
        : Icons.warning_amber_rounded,
    color: passed ? passColor : failColor,
    title: passed ? passTitle : failTitle,
    message: message,
  );
}

String _outputValueLabel(
  TelemetryCalculationOutput output, {
  bool absolute = false,
}) {
  final value = absolute ? output.value.abs() : output.value;
  final displayValue = _formatOutputValue(value, output.precision);
  return '$displayValue ${output.unitLabel}'.trim();
}

String _formatOutputValue(double value, int precision) {
  if (value.abs() >= 100000 || value.abs() < 0.001 && value != 0) {
    return value.toStringAsExponential(precision);
  }
  return value.toStringAsFixed(precision);
}

TelemetryCalculationOutput? _findOutput(
  List<TelemetryCalculationOutput> outputs,
  String id,
) {
  for (final output in outputs) {
    if (output.id == id) return output;
  }
  return null;
}

class _CompactNumberInput extends StatefulWidget {
  final TelemetryInputDefinition input;
  final TelemetryInputValue value;
  final TextEditingController controller;
  final void Function(String id, String text) onChanged;
  final void Function(String id, String unitId) onUnitChanged;

  const _CompactNumberInput({
    required this.input,
    required this.value,
    required this.controller,
    required this.onChanged,
    required this.onUnitChanged,
  });

  @override
  State<_CompactNumberInput> createState() => _CompactNumberInputState();
}

class _CompactNumberInputState extends State<_CompactNumberInput> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invalid =
        widget.controller.text.trim().isEmpty ||
        double.tryParse(widget.controller.text.trim()) == null;
    return _CompactInputShell(
      label: widget.input.label,
      helper: widget.input.helper,
      invalid: invalid,
      focusNode: _focusNode,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 62,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (text) => widget.onChanged(widget.input.id, text),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
                height: 1,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.xs.w),
          _UnitMenuButton(
            value: widget.value.unitId,
            units: widget.input.units,
            onChanged: (unitId) =>
                widget.onUnitChanged(widget.input.id, unitId),
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _CompactSelectInput extends StatelessWidget {
  final TelemetryInputDefinition input;
  final String selectedId;
  final void Function(String id, String optionId) onChanged;

  const _CompactSelectInput({
    required this.input,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = input.options.firstWhere(
      (option) => option.id == selectedId,
      orElse: () => input.options.first,
    );
    return _CompactInputShell(
      label: input.label,
      helper: input.helper,
      child: _OptionMenuButton(
        selected: selected,
        options: input.options,
        onChanged: (optionId) => onChanged(input.id, optionId),
      ),
    );
  }
}

class _CompactExpressionInput extends StatefulWidget {
  final TelemetryInputDefinition input;
  final TextEditingController controller;
  final void Function(String id, String text) onChanged;

  const _CompactExpressionInput({
    required this.input,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_CompactExpressionInput> createState() =>
      _CompactExpressionInputState();
}

class _CompactExpressionInputState extends State<_CompactExpressionInput> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CompactInputShell(
      label: widget.input.label,
      helper: widget.input.helper,
      focusNode: _focusNode,
      child: SizedBox(
        width: 120,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: 1,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.end,
          onChanged: (text) => widget.onChanged(widget.input.id, text),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Roboto',
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _CompactInputShell extends StatefulWidget {
  final String label;
  final String helper;
  final bool invalid;
  final FocusNode? focusNode;
  final Widget child;

  const _CompactInputShell({
    required this.label,
    required this.helper,
    required this.child,
    this.invalid = false,
    this.focusNode,
  });

  @override
  State<_CompactInputShell> createState() => _CompactInputShellState();
}

class _CompactInputShellState extends State<_CompactInputShell> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
    _focused = widget.focusNode?.hasFocus ?? false;
  }

  @override
  void didUpdateWidget(_CompactInputShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    oldWidget.focusNode?.removeListener(_onFocusChange);
    widget.focusNode?.addListener(_onFocusChange);
    _focused = widget.focusNode?.hasFocus ?? false;
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _focused = widget.focusNode?.hasFocus ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final borderColor = widget.invalid
        ? theme.colorScheme.error
        : _focused
        ? theme.colorScheme.primary
        : semantic.border;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: semantic.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.helper.isNotEmpty) ...[
                  SizedBox(width: AppSpacing.xs.w),
                  Tooltip(
                    message: widget.helper,
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 13.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            flex: 7,
            child: Align(alignment: Alignment.centerRight, child: widget.child),
          ),
        ],
      ),
    );
  }
}

class _UnitMenuButton extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;
  final bool compact;

  const _UnitMenuButton({
    required this.value,
    required this.units,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: '选择单位',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final unitId in units)
          PopupMenuItem(
            value: unitId,
            child: Text(UnitCatalog.unit(unitId).label),
          ),
      ],
      child: Container(
        constraints: BoxConstraints(
          minWidth: compact ? 42 : 70.w,
          maxWidth: compact ? 50 : double.infinity,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs.w : AppSpacing.md.w,
          vertical: compact ? AppSpacing.sm.h : AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: theme.semanticColors.border),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                UnitCatalog.unit(value).label,
                maxLines: 1,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: AppSpacing.xs.w),
              Icon(Icons.expand_more_rounded, size: compact ? 14.sp : 16.sp),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionMenuButton extends StatelessWidget {
  final TelemetryOption selected;
  final List<TelemetryOption> options;
  final ValueChanged<String> onChanged;

  const _OptionMenuButton({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: '选择参数',
      initialValue: selected.id,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option.id, child: Text(option.label)),
      ],
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: theme.semanticColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, size: 16.sp),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Text(
                selected.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

class _AdvancedToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _AdvancedToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
        child: Row(
          children: [
            const Expanded(child: AppSectionHeader(title: '高级参数')),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaPanel extends StatelessWidget {
  final TelemetryCalculatorDefinition definition;
  final Color color;

  const _FormulaPanel({required this.definition, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formulas = definition.formulas;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions_rounded, color: color, size: 18.sp),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  '依据',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '公式与来源',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          for (var i = 0; i < formulas.length; i++) ...[
            _FormulaCompactRow(formula: formulas[i], color: color),
            if (i < formulas.length - 1) SizedBox(height: AppSpacing.sm.h),
          ],
        ],
      ),
    );
  }
}

class _FormulaCompactRow extends StatelessWidget {
  final FormulaReference formula;
  final Color color;

  const _FormulaCompactRow({required this.formula, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: theme.semanticColors.mutedSurface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formula.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '复制公式',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: formula.expression));
                  Get.snackbar('已复制', formula.title);
                },
                icon: const Icon(Icons.copy_rounded),
                style: IconButton.styleFrom(
                  minimumSize: Size(32.w, 32.w),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          _FormulaExpression(expression: formula.expression, color: color),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            formula.source,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaExpression extends StatelessWidget {
  final String expression;
  final Color color;

  const _FormulaExpression({required this.expression, required this.color});

  @override
  Widget build(BuildContext context) {
    return _FormulaMathBlock(
      expression: expression,
      texExpression: expression,
      color: color,
    );
  }
}

class _FormulaMathBlock extends StatelessWidget {
  final String expression;
  final String texExpression;
  final Color color;

  const _FormulaMathBlock({
    required this.expression,
    required this.texExpression,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                texExpression,
                textStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 17.sp,
                ),
                onErrorFallback: (_) => Text(
                  _readableFormulaExpression(expression),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.sp,
                    height: 1.35,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _readableFormulaExpression(String expression) {
  var readable = expression;
  const replacements = {
    'lambda': 'λ',
    'pi': 'π',
    'theta': 'θ',
    'phi': 'φ',
    'eta': 'η',
    'sigma': 'σ',
    'gamma': 'γ',
    'rho': 'ρ',
    'alpha': 'α',
    'beta': 'β',
  };
  for (final entry in replacements.entries) {
    readable = readable.replaceAllMapped(
      RegExp('(^|[^A-Za-z])${RegExp.escape(entry.key)}([^A-Za-z]|\$)'),
      (match) => '${match.group(1)}${entry.value}${match.group(2)}',
    );
  }
  return readable;
}

String _categoryLabel(TelemetryCalculatorCategory category) {
  return switch (category) {
    TelemetryCalculatorCategory.link => '链路',
    TelemetryCalculatorCategory.rate => '码率',
    TelemetryCalculatorCategory.frame => 'PCM',
    TelemetryCalculatorCategory.coding => '编码',
    TelemetryCalculatorCategory.command => '遥控',
    TelemetryCalculatorCategory.ranging => '测距',
    TelemetryCalculatorCategory.frequency => '频率',
    TelemetryCalculatorCategory.system => '系统',
    TelemetryCalculatorCategory.custom => '公式',
  };
}

String _categoryFilterLabel(TelemetryCalculatorCategory category) {
  return '${_categoryLabel(category)} ${TelemetryCalculatorRegistry.countByCategory(category)}';
}

String _detailTitle(TelemetryCalculatorDefinition definition) {
  return switch (definition.id) {
    'link_budget' => '链路预算',
    'rate_bandwidth' => '带宽计算',
    'pcm_frame' => 'PCM 计算',
    'channel_coding' => '编码开销',
    'telecommand' => '遥控吞吐',
    'ranging' => '测距时延',
    'doppler' => '频率校核',
    'spacecraft_power' => '电源计算',
    'spacecraft_thermal' => '热控计算',
    'mission_closure' => '资源闭合',
    'custom_formula' => '自定义公式',
    _ => definition.title,
  };
}

IconData _categoryIcon(TelemetryCalculatorCategory category) {
  return switch (category) {
    TelemetryCalculatorCategory.link => Icons.settings_input_antenna_rounded,
    TelemetryCalculatorCategory.rate => Icons.speed_rounded,
    TelemetryCalculatorCategory.frame => Icons.view_timeline_rounded,
    TelemetryCalculatorCategory.coding => Icons.memory_rounded,
    TelemetryCalculatorCategory.command => Icons.keyboard_command_key_rounded,
    TelemetryCalculatorCategory.ranging => Icons.social_distance_rounded,
    TelemetryCalculatorCategory.frequency => Icons.graphic_eq_rounded,
    TelemetryCalculatorCategory.system => Icons.account_tree_rounded,
    TelemetryCalculatorCategory.custom => Icons.functions_rounded,
  };
}

IconData _formulaDomainIcon(FormulaDomain domain) {
  return switch (domain) {
    FormulaDomain.rfAntennaReceiver => Icons.settings_input_antenna_rounded,
    FormulaDomain.propagationLink => Icons.public_rounded,
    FormulaDomain.baseband => Icons.graphic_eq_rounded,
    FormulaDomain.telemetryFrames => Icons.view_timeline_rounded,
    FormulaDomain.telecommand => Icons.keyboard_command_key_rounded,
    FormulaDomain.rangingTracking => Icons.social_distance_rounded,
    FormulaDomain.system => Icons.account_tree_rounded,
    FormulaDomain.optical => Icons.light_mode_rounded,
    FormulaDomain.orbitContact => Icons.travel_explore_rounded,
    FormulaDomain.compression => Icons.compress_rounded,
    FormulaDomain.protocol => Icons.security_rounded,
    FormulaDomain.measurement => Icons.straighten_rounded,
  };
}

Color _categoryColor(
  TelemetryCalculatorCategory category,
  AppSemanticColors semantic,
) {
  return switch (category) {
    TelemetryCalculatorCategory.link => semantic.stats,
    TelemetryCalculatorCategory.rate => semantic.work,
    TelemetryCalculatorCategory.frame => semantic.project,
    TelemetryCalculatorCategory.coding => semantic.expense,
    TelemetryCalculatorCategory.command => semantic.warning,
    TelemetryCalculatorCategory.ranging => semantic.success,
    TelemetryCalculatorCategory.frequency => semantic.stats,
    TelemetryCalculatorCategory.system => semantic.work,
    TelemetryCalculatorCategory.custom => semantic.project,
  };
}

Color _formulaDomainColor(FormulaDomain domain, AppSemanticColors semantic) {
  return switch (domain) {
    FormulaDomain.rfAntennaReceiver => semantic.stats,
    FormulaDomain.propagationLink => semantic.success,
    FormulaDomain.baseband => semantic.stats,
    FormulaDomain.telemetryFrames => semantic.project,
    FormulaDomain.telecommand => semantic.warning,
    FormulaDomain.rangingTracking => semantic.success,
    FormulaDomain.system => semantic.work,
    FormulaDomain.optical => semantic.project,
    FormulaDomain.orbitContact => semantic.stats,
    FormulaDomain.compression => semantic.expense,
    FormulaDomain.protocol => semantic.warning,
    FormulaDomain.measurement => semantic.success,
  };
}

String _formatInputNumber(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
