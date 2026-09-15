import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_view.dart';
import 'package:life_log/features/work_log/work_log_feature_di.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets(
    'DayLogList displays compact cards with type tags, durations, project link and notes for multiple same-day entries',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date = DateTime(2026, 5, 1);
      final entries = [
        WorkLogEntry(
          id: 1,
          date: date,
          type: WorkLogEntryType.work,
          overtimeHours: 2.5,
          projectName: '智慧园区项目',
          projectStageName: '一期交付',
          note: '完成接口联调与验收测试',
        ),
        WorkLogEntry(
          id: 2,
          date: date,
          type: WorkLogEntryType.businessTrip,
          location: '上海',
          transport: '高铁',
          expenses: 320,
          isReimbursed: false,
          projectName: '华东区总部',
          note: '客户技术交流会议',
        ),
        WorkLogEntry(
          id: 3,
          date: date,
          type: WorkLogEntryType.leave,
          location: '事假',
          note: '下午家中有事',
        ),
        WorkLogEntry(
          id: 4,
          date: date,
          type: WorkLogEntryType.rest,
          note: '调休半天',
        ),
      ];

      final repository = _TestWorkLogRepository(entries);
      configureWorkLogFeatureDependencies(
        repository: repository,
        initialNow: () => date,
      );

      await tester.pumpWidget(_harness(const WorkLogView()));
      await tester.pumpAndSettle();

      // Header should show multiple entries badge
      expect(find.text('5月1日'), findsOneWidget);
      expect(find.text('共 4 条记录'), findsOneWidget);

      // Verify all type titles are shown simultaneously (no over-folding)
      expect(find.text('工作'), findsOneWidget);
      expect(find.text('出差'), findsOneWidget);
      expect(find.text('请假'), findsOneWidget);
      expect(find.text('休息'), findsOneWidget);

      // Verify work hours duration badges
      expect(find.text('10.5小时'), findsOneWidget); // 8 + 2.5
      expect(find.text('8小时'), findsNWidgets(2)); // trip & leave
      expect(find.text('0小时'), findsOneWidget); // rest

      // Verify overtime tag and status
      expect(find.text('加班 2.5 小时'), findsOneWidget);
      expect(find.text('上海'), findsOneWidget);
      expect(find.text('高铁'), findsOneWidget);
      expect(find.text('垫付 ¥320.0'), findsOneWidget);
      expect(find.text('待报销'), findsOneWidget);
      expect(find.text('事假'), findsOneWidget);
      expect(find.text('休息日'), findsOneWidget);

      // Verify associated project links
      expect(find.text('智慧园区项目 · 一期交付'), findsOneWidget);
      expect(find.text('华东区总部'), findsOneWidget);

      // Verify notes
      expect(find.text('完成接口联调与验收测试'), findsOneWidget);
      expect(find.text('客户技术交流会议'), findsOneWidget);
      expect(find.text('下午家中有事'), findsOneWidget);
      expect(find.text('调休半天'), findsOneWidget);

      // Verify actions for each card (4 edit + 4 delete icons)
      expect(find.byIcon(Icons.edit_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(4));
    },
  );

  testWidgets(
    'empty day state displays compact friendly card without full-screen stretching',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date = DateTime(2026, 5, 2);
      final repository = _TestWorkLogRepository(const []);
      configureWorkLogFeatureDependencies(
        repository: repository,
        initialNow: () => date,
      );

      await tester.pumpWidget(_harness(const WorkLogView()));
      await tester.pumpAndSettle();

      expect(find.text('这天还没有记录'), findsOneWidget);
      expect(find.text('使用右下角「记工时」添加工作、出差、请假或休息。'), findsOneWidget);
      expect(find.byIcon(Icons.edit_calendar_rounded), findsWidgets);
    },
  );

  testWidgets(
    'WorkLogView instantly reflects reactive stream updates from repository without delay',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date = DateTime(2026, 5, 1);
      final repository = _TestWorkLogRepository([
        WorkLogEntry(
          id: 1,
          date: date,
          type: WorkLogEntryType.work,
          note: '初始记录',
        ),
      ]);
      configureWorkLogFeatureDependencies(
        repository: repository,
        initialNow: () => date,
      );

      await tester.pumpWidget(_harness(const WorkLogView()));
      await tester.pumpAndSettle();

      expect(find.text('初始记录'), findsOneWidget);
      expect(find.text('新保存的即时工时'), findsNothing);

      // Simulate an external/background save or instant DB stream notification
      repository.addAndNotify(
        WorkLogEntry(
          id: 2,
          date: date,
          type: WorkLogEntryType.work,
          overtimeHours: 3,
          note: '新保存的即时工时',
        ),
      );

      // Millisecond-level stream delivery: pump once
      await tester.pump();
      await tester.pumpAndSettle();

      // UI should immediately display both entries
      expect(find.text('初始记录'), findsOneWidget);
      expect(find.text('新保存的即时工时'), findsOneWidget);
      expect(find.text('加班 3.0 小时'), findsOneWidget);
      expect(find.text('共 2 条记录'), findsOneWidget);
    },
  );

  testWidgets(
    'DayCell prioritizes the latest entry on the calendar when multiple entries exist on the same day',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date = DateTime(2026, 5, 1);
      final earlierRest = WorkLogEntry(
        id: 1,
        date: date,
        type: WorkLogEntryType.rest,
        createdAt: DateTime(2026, 5, 1, 8, 0),
      );
      final laterOvertime = WorkLogEntry(
        id: 2,
        date: date,
        type: WorkLogEntryType.work,
        overtimeHours: 2,
        createdAt: DateTime(2026, 5, 1, 18, 0),
      );

      final repository = _TestWorkLogRepository([earlierRest, laterOvertime]);
      configureWorkLogFeatureDependencies(
        repository: repository,
        initialNow: () => date,
      );

      await tester.pumpWidget(_harness(const WorkLogView()));
      await tester.pumpAndSettle();

      // Calendar cell should reflect the latest work entry status (+加班) instead of earlier rest
      expect(find.text('+2h'), findsOneWidget);

      // Both records exist in the detail list
      expect(find.text('共 2 条记录'), findsOneWidget);
      expect(find.text('休息'), findsOneWidget);
      expect(find.text('工作'), findsOneWidget);
    },
  );
}

Widget _harness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(home: child),
  );
}

final class _TestWorkLogRepository implements WorkLogRepositoryPort {
  final List<WorkLogEntry> _entries;
  final StreamController<void> _watchController =
      StreamController<void>.broadcast();

  _TestWorkLogRepository([List<WorkLogEntry> entries = const []])
    : _entries = List<WorkLogEntry>.from(entries);

  void addAndNotify(WorkLogEntry entry) {
    _entries.add(entry);
    _watchController.add(null);
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() async =>
      List.unmodifiable(_entries);

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async {
    return _entries
        .where(
          (entry) =>
              entry.date.year == month.year && entry.date.month == month.month,
        )
        .toList(growable: false);
  }

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {
    if (entry.id != 0) {
      _entries.removeWhere((existing) => existing.id == entry.id);
    }
    _entries.add(entry);
    _watchController.add(null);
  }

  @override
  Future<void> deleteEntry(int id) async {
    _entries.removeWhere((e) => e.id == id);
    _watchController.add(null);
  }

  @override
  Stream<void> watchEntries() => _watchController.stream;
}
