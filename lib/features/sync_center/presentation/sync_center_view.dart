import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_loading.dart';
import 'package:life_log/common/widgets/app_load_failure.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/sync_center/application/load_sync_center_snapshot.dart';
import 'package:life_log/features/sync_center/application/resolve_sync_conflict.dart';
import 'package:life_log/features/sync_center/domain/sync_center_snapshot.dart';

class SyncCenterView extends StatefulWidget {
  const SyncCenterView({super.key});

  @override
  State<SyncCenterView> createState() => _SyncCenterViewState();
}

class _SyncCenterViewState extends State<SyncCenterView> {
  late Future<SyncCenterSnapshot> _snapshotFuture;
  SyncCenterSnapshot? _cachedSnapshot;
  int _requestId = 0;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<SyncCenterSnapshot> _loadSnapshot() async {
    final requestId = ++_requestId;
    _refreshing = true;
    try {
      final data = await serviceLocator<LoadSyncCenterSnapshot>().call();
      if (mounted && requestId == _requestId) _cachedSnapshot = data;
      return data;
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _reload({bool force = false}) async {
    if (!mounted || (_refreshing && !force)) return;
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
    try {
      await _snapshotFuture;
    } catch (_) {
      // FutureBuilder presents the failure while retaining the last snapshot.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步状态'),
        actions: [
          if (_refreshing)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Semantics(
                label: '正在读取同步状态',
                liveRegion: true,
                child: const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            onPressed: _refreshing ? null : () => unawaited(_reload()),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<SyncCenterSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? _cachedSnapshot;
            if (snapshot.connectionState == ConnectionState.waiting &&
                data == null) {
              return const AppLoading(label: '正在读取同步状态');
            }
            if (snapshot.hasError && data == null) {
              return AppLoadFailure(
                message: '无法读取同步状态，请重试。',
                onRetry: () => unawaited(_reload()),
              );
            }

            if (data == null) {
              return const AppEmptyState(
                icon: Icons.sync_disabled_rounded,
                title: '暂无同步状态',
                message: '当前没有可显示的同步任务或冲突。',
              );
            }

            final pendingQueueEntries = data.pendingQueueEntries;
            final unresolvedConflicts = data.unresolvedConflicts;
            final queueIndices = <Key, int>{
              for (var i = 0; i < pendingQueueEntries.length; i++)
                ValueKey(
                  'queue:${pendingQueueEntries[i].entityName}:${pendingQueueEntries[i].entityKey}',
                ): i,
            };
            final conflictIndices = <Key, int>{
              for (var i = 0; i < unresolvedConflicts.length; i++)
                ValueKey(unresolvedConflicts[i].id): i,
            };
            return RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (snapshot.hasError)
                            AppLoadFailure(
                              compact: true,
                              message: '同步状态暂未刷新，正在显示上次读取的记录。',
                              onRetry: () => unawaited(_reload()),
                            ),
                          _SummaryCard(snapshot: data),
                          const SizedBox(height: AppSpacing.lg),
                          _SectionTitle(
                            title: '失败任务',
                            count: pendingQueueEntries.length,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: pendingQueueEntries.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _QuietEmptyState(
                              icon: Icons.task_alt_rounded,
                              message: '没有待重试任务',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = pendingQueueEntries[index];
                                return _QueueEntryTile(
                                  entry,
                                  key: ValueKey(
                                    'queue:${entry.entityName}:${entry.entityKey}',
                                  ),
                                );
                              },
                              childCount: pendingQueueEntries.length,
                              findChildIndexCallback: (key) =>
                                  queueIndices[key],
                            ),
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          _SectionTitle(
                            title: '待处理冲突',
                            count: unresolvedConflicts.length,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: unresolvedConflicts.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _QuietEmptyState(
                              icon: Icons.verified_user_outlined,
                              message: '没有待处理冲突',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = unresolvedConflicts[index];
                                return _ConflictTile(
                                  key: ValueKey(entry.id),
                                  entry: entry,
                                  enabled: !_refreshing,
                                  onResolved: () =>
                                      unawaited(_reload(force: true)),
                                );
                              },
                              childCount: unresolvedConflicts.length,
                              findChildIndexCallback: (key) =>
                                  conflictIndices[key],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SyncCenterSnapshot snapshot;

  const _SummaryCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final horizontal = MediaQuery.sizeOf(context).width < 420 && scale > 1.4;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Flex(
        direction: horizontal ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: horizontal
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: horizontal ? 0 : 1,
            fit: horizontal ? FlexFit.loose : FlexFit.tight,
            child: _SummaryMetric(
              horizontal: horizontal,
              label: '失败任务',
              value: snapshot.pendingQueueCount.toString(),
              icon: Icons.pending_actions_rounded,
            ),
          ),
          SizedBox(
            width: horizontal ? 0 : AppSpacing.md,
            height: horizontal ? AppSpacing.md : 0,
          ),
          Flexible(
            flex: horizontal ? 0 : 1,
            fit: horizontal ? FlexFit.loose : FlexFit.tight,
            child: _SummaryMetric(
              horizontal: horizontal,
              label: '冲突',
              value: snapshot.unresolvedConflictCount.toString(),
              icon: Icons.report_problem_outlined,
            ),
          ),
          SizedBox(
            width: horizontal ? 0 : AppSpacing.md,
            height: horizontal ? AppSpacing.md : 0,
          ),
          Flexible(
            flex: horizontal ? 0 : 1,
            fit: horizontal ? FlexFit.loose : FlexFit.tight,
            child: _SummaryMetric(
              horizontal: horizontal,
              label: '状态',
              value:
                  snapshot.pendingQueueCount +
                          snapshot.unresolvedConflictCount ==
                      0
                  ? '正常'
                  : '需处理',
              icon: Icons.sync_rounded,
              color:
                  snapshot.pendingQueueCount +
                          snapshot.unresolvedConflictCount ==
                      0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final bool horizontal;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    if (horizontal) {
      return Row(
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: effectiveColor,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: effectiveColor),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: effectiveColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QueueEntryTile extends StatelessWidget {
  final SyncQueueEntry entry;

  const _QueueEntryTile(this.entry, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.pending_actions_rounded, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _entityLabel(entry.entityName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '重试 ${entry.attemptCount} 次 · 下次 ${_formatDateTime(entry.nextAttemptAt)}',
                    style: TextStyle(color: secondary),
                  ),
                  if (entry.lastError?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      entry.lastError!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secondary),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: '查看任务详情',
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => _showDiagnostics(
                context,
                '任务详情',
                '${entry.entityName}\n${entry.entityKey}\n'
                    '重试 ${entry.attemptCount} 次\n'
                    '下次尝试 ${_formatDateTime(entry.nextAttemptAt)}\n'
                    '${entry.lastError ?? ""}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictTile extends StatefulWidget {
  final SyncConflictEntry entry;
  final VoidCallback onResolved;
  final bool enabled;

  const _ConflictTile({
    super.key,
    required this.entry,
    required this.onResolved,
    this.enabled = true,
  });

  @override
  State<_ConflictTile> createState() => _ConflictTileState();
}

class _ConflictTileState extends State<_ConflictTile>
    with AutomaticKeepAliveClientMixin {
  bool _resolving = false;

  @override
  bool get wantKeepAlive => _resolving;

  Future<void> _resolve(String resolution) async {
    if (_resolving || !widget.enabled) return;
    setState(() => _resolving = true);
    updateKeepAlive();
    try {
      if (resolution == 'use-remote') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('采用远端版本'),
            content: const Text('这会替换本地修改；远端已删除的记录也会从列表中移除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('采用远端'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      await serviceLocator<ResolveSyncConflict>().call(
        widget.entry.id,
        resolution: resolution,
      );
      if (!mounted) return;
      final message = switch (resolution) {
        'keep-local' => '已保留本地修改，等待同步',
        'copy' => '已复制本地记录并采用远端版本，副本等待同步',
        _ => '已采用远端版本',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      widget.onResolved();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('处理失败，冲突已保留：$error')));
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
        updateKeepAlive();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final entry = widget.entry;
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${_entityLabel(entry.entityName)} · 冲突',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '查看冲突详情',
                  icon: const Icon(Icons.info_outline_rounded),
                  onPressed: () => _showDiagnostics(
                    context,
                    '冲突详情',
                    '${entry.entityName}\n${entry.entitySyncId ?? ""}\n'
                        '${entry.conflictType}\n'
                        '本地版本 ${entry.localVersion ?? "未知"}\n'
                        '远端版本 ${entry.remoteVersion ?? "未知"}\n'
                        '${entry.message}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              entry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: secondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '发现于 ${_formatDateTime(entry.detectedAt)}',
              style: TextStyle(color: secondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ConflictActionButton(
                  label: '保留本地',
                  onPressed: _resolving || !widget.enabled
                      ? null
                      : () => _resolve('keep-local'),
                ),
                _ConflictActionButton(
                  label: '采用远端',
                  onPressed: _resolving || !widget.enabled
                      ? null
                      : () => _resolve('use-remote'),
                ),
                _ConflictActionButton(
                  label: '复制为新记录',
                  onPressed: _resolving || !widget.enabled
                      ? null
                      : () => _resolve('copy'),
                ),
                OutlinedButton(
                  onPressed: _resolving || !widget.enabled
                      ? null
                      : widget.onResolved,
                  child: const Text('稍后处理'),
                ),
                if (_resolving)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ConflictActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(onPressed: onPressed, child: Text(label));
  }
}

class _QuietEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _QuietEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: TextStyle(color: secondary)),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatDateYmd(local)} $hour:$minute';
}

String _entityLabel(String name) => switch (name) {
  'work_log' => '工时记录',
  'subscription' => '订阅',
  'project' => '项目',
  'expense_record' => '费用记录',
  'evidence' => '凭证',
  'evidence_attachment' => '凭证附件',
  _ => '其他记录',
};

Future<void> _showDiagnostics(
  BuildContext context,
  String title,
  String details,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      scrollable: true,
      content: SelectableText(details),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
