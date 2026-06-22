import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/utils/formatters.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_empty_state.dart';
import 'package:life_log/common/widgets/app_loading.dart';
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

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<SyncCenterSnapshot> _loadSnapshot() {
    return serviceLocator<LoadSyncCenterSnapshot>().call();
  }

  void _reload() {
    setState(() => _snapshotFuture = _loadSnapshot());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步状态'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<SyncCenterSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoading(label: '正在读取同步状态');
            }
            if (snapshot.hasError) {
              return AppEmptyState(
                icon: Icons.sync_problem_rounded,
                title: '无法读取同步状态',
                message: snapshot.error.toString(),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const AppEmptyState(
                icon: Icons.sync_disabled_rounded,
                title: '暂无同步状态',
                message: '当前没有可显示的同步任务或冲突。',
              );
            }

            final pendingQueueEntries = data.pendingQueueEntries;
            final unresolvedConflicts = data.unresolvedConflicts;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _SummaryCard(snapshot: data),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(title: '失败任务', count: pendingQueueEntries.length),
                const SizedBox(height: AppSpacing.sm),
                if (pendingQueueEntries.isEmpty)
                  const _QuietEmptyState(
                    icon: Icons.task_alt_rounded,
                    message: '没有待重试任务',
                  )
                else
                  ...pendingQueueEntries.map(_QueueEntryTile.new),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(
                  title: '待处理冲突',
                  count: unresolvedConflicts.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (unresolvedConflicts.isEmpty)
                  const _QuietEmptyState(
                    icon: Icons.verified_user_outlined,
                    message: '没有待处理冲突',
                  )
                else
                  ...unresolvedConflicts.map(
                    (entry) => _ConflictTile(entry: entry, onResolved: _reload),
                  ),
              ],
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: '失败任务',
              value: snapshot.pendingQueueCount.toString(),
              icon: Icons.pending_actions_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _SummaryMetric(
              label: '冲突',
              value: snapshot.unresolvedConflictCount.toString(),
              icon: Icons.report_problem_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _SummaryMetric(
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

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
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

  const _QueueEntryTile(this.entry);

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
                    '${entry.entityName} · ${entry.entityKey}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '重试 ${entry.attemptCount} 次 · 下次 ${_formatDateTime(entry.nextAttemptAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

class _ConflictTile extends StatelessWidget {
  final SyncConflictEntry entry;
  final VoidCallback onResolved;

  const _ConflictTile({required this.entry, required this.onResolved});

  @override
  Widget build(BuildContext context) {
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
                    '${entry.entityName} · ${entry.conflictType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                  resolution: 'keep-local',
                  entryId: entry.id,
                  onResolved: onResolved,
                ),
                _ConflictActionButton(
                  label: '采用远端',
                  resolution: 'use-remote',
                  entryId: entry.id,
                  onResolved: onResolved,
                ),
                _ConflictActionButton(
                  label: '复制为新记录',
                  resolution: 'copy',
                  entryId: entry.id,
                  onResolved: onResolved,
                ),
                OutlinedButton(
                  onPressed: onResolved,
                  child: const Text('稍后处理'),
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
  final String resolution;
  final int entryId;
  final VoidCallback onResolved;

  const _ConflictActionButton({
    required this.label,
    required this.resolution,
    required this.entryId,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await serviceLocator<ResolveSyncConflict>().call(
          entryId,
          resolution: resolution,
        );
        messenger.showSnackBar(SnackBar(content: Text('$label 已记录')));
        onResolved();
      },
      child: Text(label),
    );
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
