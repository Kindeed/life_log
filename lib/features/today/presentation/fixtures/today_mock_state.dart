import 'package:flutter/material.dart';

final todayMockState = TodayMockState.normal();

enum TodayMockStatus { loading, empty, ready, failure }

final class TodayMockState {
  final TodayMockStatus status;
  final String dateLabel;
  final String primarySummary;
  final List<QuickActionFixture> quickActions;
  final List<PendingTaskFixture> pendingTasks;
  final List<RecentRecordFixture> recentItems;
  final String? failureMessage;

  const TodayMockState({
    required this.status,
    required this.dateLabel,
    required this.primarySummary,
    required this.quickActions,
    required this.pendingTasks,
    required this.recentItems,
    this.failureMessage,
  });

  factory TodayMockState.loading() {
    return const TodayMockState(
      status: TodayMockStatus.loading,
      dateLabel: '6月21日 星期日',
      primarySummary: '正在加载今天的记录',
      quickActions: [],
      pendingTasks: [],
      recentItems: [],
    );
  }

  factory TodayMockState.empty() {
    return const TodayMockState(
      status: TodayMockStatus.empty,
      dateLabel: '6月21日 星期日',
      primarySummary: '今天还没有记录',
      quickActions: _quickActions,
      pendingTasks: [],
      recentItems: [],
    );
  }

  factory TodayMockState.normal() {
    return const TodayMockState(
      status: TodayMockStatus.ready,
      dateLabel: '6月21日 星期日',
      primarySummary: '工作 8.0 小时 · 加班 1.0 小时',
      quickActions: _quickActions,
      pendingTasks: [
        PendingTaskFixture(
          icon: Icons.subscriptions_rounded,
          label: '7 天内扣款',
          value: '2 项 · ¥126.00',
        ),
        PendingTaskFixture(
          icon: Icons.pending_actions_rounded,
          label: '待报销凭证',
          value: '¥438.50',
        ),
      ],
      recentItems: [
        RecentRecordFixture(
          typeLabel: '工时',
          title: '今天 · 工作',
          subtitle: '加班 1.0 小时',
          statusLabel: '已记录',
        ),
        RecentRecordFixture(
          typeLabel: '支出',
          title: '午餐',
          subtitle: '项目 A · ¥35.00',
          statusLabel: '待归档',
        ),
        RecentRecordFixture(
          typeLabel: '凭证',
          title: '高铁票',
          subtitle: '等回去报销',
          statusLabel: '待报销',
        ),
      ],
    );
  }

  factory TodayMockState.overflowText() {
    return const TodayMockState(
      status: TodayMockStatus.ready,
      dateLabel: '6月21日 星期日',
      primarySummary: '一个很长很长的项目现场工作记录，用来检查移动端文本换行和按钮宽度',
      quickActions: _quickActions,
      pendingTasks: [
        PendingTaskFixture(
          icon: Icons.pending_actions_rounded,
          label: '待处理事项名称非常长需要换行',
          value: '¥123456.78',
        ),
      ],
      recentItems: [
        RecentRecordFixture(
          typeLabel: '工时',
          title: '超长记录标题用于验证文本不会挤压图标或覆盖金额',
          subtitle: '很长的项目名 · 很长的地点说明 · 很长的备注',
          statusLabel: '已记录',
        ),
      ],
    );
  }

  factory TodayMockState.failure() {
    return const TodayMockState(
      status: TodayMockStatus.failure,
      dateLabel: '6月21日 星期日',
      primarySummary: '今天状态暂时不可用',
      quickActions: _quickActions,
      pendingTasks: [],
      recentItems: [],
      failureMessage: '读取本地记录失败，请稍后重试',
    );
  }
}

final class QuickActionFixture {
  final String id;
  final String label;
  final IconData icon;
  final bool enabled;

  const QuickActionFixture({
    required this.id,
    required this.label,
    required this.icon,
    this.enabled = true,
  });
}

final class PendingTaskFixture {
  final IconData icon;
  final String label;
  final String value;

  const PendingTaskFixture({
    required this.icon,
    required this.label,
    required this.value,
  });
}

final class RecentRecordFixture {
  final String typeLabel;
  final String title;
  final String subtitle;
  final String statusLabel;

  const RecentRecordFixture({
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
  });
}

const _quickActions = [
  QuickActionFixture(
    id: 'work-log',
    label: '工时',
    icon: Icons.work_history_rounded,
  ),
  QuickActionFixture(id: 'expense', label: '支出', icon: Icons.payments_rounded),
  QuickActionFixture(
    id: 'evidence',
    label: '凭证',
    icon: Icons.receipt_long_rounded,
  ),
  QuickActionFixture(
    id: 'project',
    label: '项目',
    icon: Icons.folder_special_rounded,
  ),
];
