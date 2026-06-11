# 遥测计算模块 UI 紧凑型重构技术设计方案
*(Telemetry Calculator UI Compact Redesign Tech Plan)*

本方案专为 Codex 重构设计，旨在实现用户指定的**“输入/输出横向单行对齐”**与**“短参数前置双列、长参数后置单列”**的动态排序自适应布局，彻底解决计算工作台高度冗余与网格不对称的痛点。

---

## 1. 核心布局构想 (Visual Wireframe)

重构后，无论输入还是输出区域，每个参数瓦片（Tile）均采用**横向单行**排布。整体列表在渲染前根据长度智能排序：

```text
+-----------------------------------------------------------------------------------+
|  [输入] 实时参数调节                                                                |
|  G/T值 .............. [  4.0 ] dB/K   |  载波频率 .......... [  2.2 ] GHz   |  <-- (短参数并排)
|  发射天线增益 ....... [ 20.0 ] dBi    |  接收天线增益 ....... [ 32.0 ] dBi    |  <-- (短参数并排)
|  发射机输出功率 ............................................. [ 10.0 ] dBW   |  <-- (长参数独占整宽)
|  工作模式和信道编码方式 ....................................... [ BPSK_LDPC ]   |  <-- (长选择框独占整宽)
+-----------------------------------------------------------------------------------+
|  [输出] 计算结果看板                                                                |
|  EIRP ..................... 15.0 dBW   |  链路距离 ............... 1000 km    |  <-- (短结果并排)
|  接收载噪比 ............... 54.2 dBHz  |  接收信号电平 ......... -110.2 dBm   |  <-- (短结果并排)
|  自由空间传播损耗 ............................................. 150.23 dB    |  <-- (长结果独占整宽)
|  [判断] 链路余量满足设计规范要求 (余量: 4.5 dB)                                      |  <-- (工程洞察 Banner)
+-----------------------------------------------------------------------------------+
```

---

## 2. 宽度评分与排序算法 (Width Scoring & Sorting Algorithm)

在代码中引入字符宽度估算机制。中文字符权重为 2，英文字符/数字权重为 1。

### 2.1 基础算法逻辑
```dart
/// 计算文本显示的估算宽度得分（中文算2字节，英文算1字节）
int _calculateTextWidthScore(String text) {
  var score = 0;
  for (final rune in text.runes) {
    score += rune > 255 ? 2 : 1;
  }
  return score;
}

/// 判断输入参数是否属于短参数（得分 < 16）
bool _isShortInput(TelemetryInputDefinition input) {
  final labelScore = _calculateTextWidthScore(input.label);
  final unitScore = _calculateTextWidthScore(input.units.firstOrNull ?? '');
  // 如果是下拉选择框，一般占用宽度较大，默认不作为短参数并排
  if (input.kind == TelemetryInputKind.select) return false;
  return (labelScore + unitScore) < 16;
}

/// 判断输出结果是否属于短参数（得分 < 16 且单位长度 <= 4）
bool _isShortOutput(TelemetryCalculationOutput output) {
  final labelScore = _calculateTextWidthScore(output.label);
  final valueScore = _calculateTextWidthScore(output.displayValue);
  final unitScore = _calculateTextWidthScore(output.unitLabel);
  return (labelScore + valueScore + unitScore) < 16 && output.unitLabel.length <= 4;
}
```

### 2.2 列表重组排序（短前置，长后置）
在 Build 面板时，将 Widget 列表重组，保证双列排布紧凑无空白间隙：
```dart
// 输入列表重新排序示例
final List<Widget> primaryInputs = ...; 

// 在 _CalculationWorkbench 渲染输入时：
final shortInputs = <Widget>[];
final longInputs = <Widget>[];

for (final input in widget.definition.inputs) {
  final widgetItem = _buildCompactInput(input);
  if (_isShortInput(input)) {
    shortInputs.add(widgetItem);
  } else {
    longInputs.add(widgetItem);
  }
}
final sortedInputWidgets = [...shortInputs, ...longInputs];
```

---

## 3. 核心 Widget 重构实现 (Widget Spec & Code Snippets)

### 3.1 统一单行输入框容器 (`_CompactInputShell` 重构)
废除原本垂直堆叠的布局，改用 `Row` 水平排列。同时**集成 FocusNode 监听，激活焦点高亮态**。

```dart
class _CompactInputShell extends StatefulWidget {
  final String label;
  final String helper;
  final bool invalid;
  final FocusNode? focusNode; // 注入焦点监听
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
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _focused = widget.focusNode?.hasFocus ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    // 决定边框颜色：错误态红 > 焦点态蓝/紫 > 普通灰边框
    final borderSideColor = widget.invalid
        ? theme.colorScheme.error
        : (_focused ? theme.colorScheme.primary : semantic.border);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: semantic.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderSideColor,
          width: _focused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // 左侧：标签与提示
          Expanded(
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
          // 右侧：紧凑输入内容与单位（由子组件提供 Row）
          widget.child,
        ],
      ),
    );
  }
}
```

### 3.2 数值输入行 (`_CompactNumberInput` 重构)
```dart
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
    final invalid = widget.controller.text.trim().isEmpty ||
        double.tryParse(widget.controller.text.trim()) == null;

    return _CompactInputShell(
      label: widget.input.label,
      helper: widget.input.helper,
      invalid: invalid,
      focusNode: _focusNode,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 限制输入框宽度，保持右对齐
          Container(
            width: 80.w,
            alignment: Alignment.centerRight,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textAlign: TextAlign.end, // 右对齐输入
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
            onChanged: (unitId) => widget.onUnitChanged(widget.input.id, unitId),
            compact: true,
          ),
        ],
      ),
    );
  }
}
```

### 3.3 统一单行输出瓦片 (`_AdaptiveResultTile` 重构)
输出结果同样采用 `Row` 水平排列，并**集成 Tooltip 提示以提供名词解析**。

```dart
class _AdaptiveResultTile extends StatelessWidget {
  final TelemetryCalculationOutput output;
  final Color color;

  const _AdaptiveResultTile({required this.output, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final statusColor = _outputStatusColor(context, output, color);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        // 与大面板强调色配合：如果是强调态面板，背景保持半透明甚至透明，避免双重灰底冲突
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: semantic.border),
      ),
      child: Row(
        children: [
          // 左侧：标签名与含义提示
          Expanded(
            child: Row(
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
                // 新增输出 Tooltip 机制（U103 规范）
                if (output.helper != null && output.helper!.isNotEmpty) ...[
                  SizedBox(width: AppSpacing.xs.w),
                  Tooltip(
                    message: output.helper!,
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 13.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          // 右侧：值与单位
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                output.displayValue,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Roboto',
                  height: 1,
                ),
              ),
              if (output.unitLabel.isNotEmpty) ...[
                SizedBox(width: AppSpacing.xs.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: semantic.mutedSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: semantic.border),
                  ),
                  child: Text(
                    output.unitLabel,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 4. 网格自适应与面板对齐重构 (`_CalculationWorkbench` / `_CompactResultPanel`)

在工作台和大面板中应用评分和排序算法，使输入输出在排布网格上达到 100% 对称。

```dart
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

            // 1. 根据长度评分对输出列表进行归类
            final shorts = <TelemetryCalculationOutput>[];
            final longs = <TelemetryCalculationOutput>[];
            for (final output in result.outputs) {
              if (_isShortOutput(output)) {
                shorts.add(output);
              } else {
                longs.add(output);
              }
            }

            // 2. 合并列表：短的在前，长的在后
            final orderedOutputs = [...shorts, ...longs];

            return Wrap(
              spacing: gap,
              runSpacing: AppSpacing.sm.h,
              children: [
                for (final output in orderedOutputs)
                  SizedBox(
                    // 短输出在宽屏下占 50% 宽，长输出独占 100%
                    width: canUseTwoColumns && _isShortOutput(output)
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth,
                    child: _AdaptiveResultTile(output: output, color: color),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: AppSpacing.md.h),
        _OutputInsightPanel(insight: insight),
      ],
    );
  }
}
```

---

## 5. Codex 实施清单与检查表 (Checklist)

1.  [ ] **数学评分工具函数**：在文件末尾定义 `_calculateTextWidthScore` 以及 `_isShortInput` / `_isShortOutput` 判定逻辑。
2.  [ ] **FocusNode 联动**：在输入外壳 `_CompactInputShell` 和输入字段中整合 `FocusNode` 监听，保证用户点入文本框时外层边框能精确触发 `focusedBorder` 主题高亮。
3.  [ ] **横向 Row 改造**：将 `_CompactInputShell` 和 `_AdaptiveResultTile` 内部全部改为 `Row`（左侧标签，右侧内容）。
4.  [ ] **输入和输出的分组重组**：在 `inputPane` 和 `_CompactResultPanel` 中，按照 `shorts` 在前、`longs` 在后的顺序对组件数组进行重排，再送入 `Wrap` 进行自适应宽度渲染。
5.  [ ] **开启公式手柄与搜索清除**：
    *   在 `_showFormulaSheet` 底部抽屉加入 `showDragHandle: true`。
    *   在 `AppTextField(key: ValueKey('telemetryCalcSearchField'))` 处，若 `_searchQuery.isNotEmpty`，则在其 `suffixIcon` 渲染 `IconButton(Icons.clear_rounded)`。
