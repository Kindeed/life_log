import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_edit_draft.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/data/expense_record_repository.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_edit_draft.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/photo/presentation/project_gallery_view.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/project/presentation/project_detail_view.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  Widget harness(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('ProjectDetailView', () {
    testWidgets(
      'renders project title, stages, 3 tabs, and quick action capsule',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(375, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final projectRepo = _FakeProjectRepository([
          const ProjectEntry(
            id: 1,
            name: '项目A',
            status: ProjectEntryStatus.active,
            stageNames: ['立项', '研发'],
          ),
        ]);
        final projectCubit = ProjectCubit(
          loadEntries: LoadProjectEntries(projectRepo),
          watchEntries: WatchProjectEntries(projectRepo),
          saveEntry: SaveProjectEntry(projectRepo),
        );
        await projectCubit.loadEntries();

        final photoRepo = _FakePhotoRepository([]);
        final photoCubit = PhotoCubit(
          loadEntries: LoadPhotoEntries(photoRepo),
          watchEntries: WatchPhotoEntries(photoRepo),
        );

        final evidenceRepo = _FakeEvidenceRepository([]);
        final evidenceCubit = EvidenceCubit(
          loadEntries: LoadEvidenceEntries(evidenceRepo),
          watchEntries: WatchEvidenceEntries(evidenceRepo),
        );

        final expenseRepo = _FakeExpenseRecordRepository([]);
        final expenseCubit = ExpenseRecordCubit(
          loadEntries: LoadExpenseRecordEntries(_FakeExpensePort([])),
          watchEntries: WatchExpenseRecordEntries(_FakeExpensePort([])),
        );

        final workLogRepo = _FakeWorkLogRepository([]);
        final loadTrips = LoadProjectWorkLogTrips(workLogRepo);

        await tester.pumpWidget(
          harness(
            ProjectDetailView(
              projectName: '项目A',
              projectId: 1,
              projectCubit: projectCubit,
              photoCubit: photoCubit,
              evidenceCubit: evidenceCubit,
              expenseCubit: expenseCubit,
              expenseRecordRepository: expenseRepo,
              loadProjectWorkLogTrips: loadTrips,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证项目名称与阶段标签
        expect(find.text('项目A'), findsOneWidget);
        expect(find.text('立项'), findsOneWidget);
        expect(find.text('研发'), findsOneWidget);

        // 验证 3 个 Tab
        expect(find.widgetWithText(Tab, '动态'), findsOneWidget);
        expect(find.widgetWithText(Tab, '照片'), findsOneWidget);
        expect(find.widgetWithText(Tab, '费用'), findsOneWidget);

        // 验证快速操作胶囊
        expect(find.text('添加照片'), findsOneWidget);
        expect(find.text('记录支出'), findsOneWidget);
        expect(find.text('添加凭证'), findsOneWidget);
      },
    );

    testWidgets(
      'timeline aggregates all activity cards for the current project and supports filter chips',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(375, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final projectRepo = _FakeProjectRepository([
          const ProjectEntry(
            id: 1,
            name: '项目A',
            status: ProjectEntryStatus.active,
          ),
        ]);
        final projectCubit = ProjectCubit(
          loadEntries: LoadProjectEntries(projectRepo),
          watchEntries: WatchProjectEntries(projectRepo),
          saveEntry: SaveProjectEntry(projectRepo),
        );
        await projectCubit.loadEntries();

        // 项目A的照片 + 其他项目的照片（应被过滤）
        final photoRepo = _FakePhotoRepository([
          _createPhoto(
            id: 101,
            projectName: '项目A',
            fileName: '现场测试图.jpg',
            description: '现场测试照片',
          ),
          _createPhoto(id: 102, projectName: '其他项目', fileName: '无关照片.jpg'),
        ]);
        final photoCubit = PhotoCubit(
          loadEntries: LoadPhotoEntries(photoRepo),
          watchEntries: WatchPhotoEntries(photoRepo),
        );
        await photoCubit.loadEntries();

        // 项目A的凭证 + 其他项目凭证
        final evidenceRepo = _FakeEvidenceRepository([
          EvidenceEntry(
            id: 201,
            projectName: '项目A',
            evidenceDate: DateTime(2026, 6, 2),
            merchant: '顺丰速运',
            amount: 45.0,
            status: EvidenceEntryStatus.submitted,
          ),
          EvidenceEntry(
            id: 202,
            projectName: '其他项目',
            evidenceDate: DateTime(2026, 6, 2),
            merchant: '无关速运',
            amount: 99.0,
          ),
        ]);
        final evidenceCubit = EvidenceCubit(
          loadEntries: LoadEvidenceEntries(evidenceRepo),
          watchEntries: WatchEvidenceEntries(evidenceRepo),
        );
        await evidenceCubit.loadEntries();

        // 项目A的费用 + 其他项目费用
        final expenseRecord1 = ExpenseRecord()
          ..id = 301
          ..projectId = 1
          ..projectName = '项目A'
          ..expenseDate = DateTime(2026, 6, 3)
          ..amount = 260.0
          ..category = ExpenseCategory.meal
          ..merchant = '项目聚餐';
        final expenseRecord2 = ExpenseRecord()
          ..id = 302
          ..projectId = 2
          ..projectName = '其他项目'
          ..expenseDate = DateTime(2026, 6, 3)
          ..amount = 500.0
          ..category = ExpenseCategory.office
          ..merchant = '无关聚餐';

        final expenseRepo = _FakeExpenseRecordRepository([
          expenseRecord1,
          expenseRecord2,
        ]);
        final expenseCubit = ExpenseRecordCubit(
          loadEntries: LoadExpenseRecordEntries(_FakeExpensePort([])),
          watchEntries: WatchExpenseRecordEntries(_FakeExpensePort([])),
        );
        await expenseCubit.loadEntries();

        // 项目A的出差记录
        final workLogRepo = _FakeWorkLogRepository([
          WorkLogEntry(
            id: 401,
            date: DateTime(2026, 6, 4),
            type: WorkLogEntryType.businessTrip,
            location: '深圳出差',
            projectName: '项目A',
            transport: '高铁',
            expenses: 600,
            isReimbursed: false,
          ),
          WorkLogEntry(
            id: 402,
            date: DateTime(2026, 6, 4),
            type: WorkLogEntryType.businessTrip,
            location: '广州出差',
            projectName: '其他项目',
            expenses: 300,
          ),
        ]);
        final loadTrips = LoadProjectWorkLogTrips(workLogRepo);

        await tester.pumpWidget(
          harness(
            ProjectDetailView(
              projectName: '项目A',
              projectId: 1,
              projectCubit: projectCubit,
              photoCubit: photoCubit,
              evidenceCubit: evidenceCubit,
              expenseCubit: expenseCubit,
              expenseRecordRepository: expenseRepo,
              loadProjectWorkLogTrips: loadTrips,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证时间线中展示了该项目的 4 类活动卡片，且没有无关项目
        expect(find.text('现场测试照片'), findsOneWidget);
        expect(find.text('顺丰速运'), findsOneWidget);
        expect(find.text('项目聚餐'), findsOneWidget);
        expect(find.text('深圳出差'), findsOneWidget);
        expect(find.text('无关照片.jpg'), findsNothing);
        expect(find.text('无关速运'), findsNothing);
        expect(find.text('无关聚餐'), findsNothing);
        expect(find.text('广州出差'), findsNothing);

        // 筛选芯片测试：切换至「照片」
        await tester.tap(find.widgetWithText(FilterChip, '照片'));
        await tester.pumpAndSettle();
        expect(find.text('现场测试照片'), findsOneWidget);
        expect(find.text('顺丰速运'), findsNothing);
        expect(find.text('项目聚餐'), findsNothing);
        expect(find.text('深圳出差'), findsNothing);

        // 筛选芯片测试：切换至「出差」
        await tester.tap(find.widgetWithText(FilterChip, '出差'));
        await tester.pumpAndSettle();
        expect(find.text('深圳出差'), findsOneWidget);
        expect(find.text('现场测试照片'), findsNothing);

        // 筛选芯片测试：切换至「费用」
        await tester.tap(find.widgetWithText(FilterChip, '费用'));
        await tester.pumpAndSettle();
        expect(find.text('项目聚餐'), findsOneWidget);
        expect(find.text('顺丰速运'), findsOneWidget);
        expect(find.text('深圳出差'), findsNothing);
      },
    );

    testWidgets(
      'tab switching switches between Timeline, Photos, and Expenses tabs',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(375, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final projectRepo = _FakeProjectRepository([
          const ProjectEntry(
            id: 1,
            name: '项目A',
            status: ProjectEntryStatus.active,
          ),
        ]);
        final projectCubit = ProjectCubit(
          loadEntries: LoadProjectEntries(projectRepo),
          watchEntries: WatchProjectEntries(projectRepo),
          saveEntry: SaveProjectEntry(projectRepo),
        );
        await projectCubit.loadEntries();

        final photoRepo = _FakePhotoRepository([
          _createPhoto(
            id: 1,
            projectName: '项目A',
            fileName: 'photo_grid.jpg',
            description: '网格照片测试',
          ),
        ]);
        final photoCubit = PhotoCubit(
          loadEntries: LoadPhotoEntries(photoRepo),
          watchEntries: WatchPhotoEntries(photoRepo),
        );
        await photoCubit.loadEntries();

        final expenseRecord = ExpenseRecord()
          ..id = 1
          ..projectId = 1
          ..projectName = '项目A'
          ..expenseDate = DateTime(2026, 6, 1)
          ..amount = 188.0
          ..category = ExpenseCategory.office
          ..merchant = '办公用品耗材';

        final expenseRepo = _FakeExpenseRecordRepository([expenseRecord]);
        final expenseCubit = ExpenseRecordCubit(
          loadEntries: LoadExpenseRecordEntries(_FakeExpensePort([])),
          watchEntries: WatchExpenseRecordEntries(_FakeExpensePort([])),
        );
        await expenseCubit.loadEntries();

        final evidenceRepo = _FakeEvidenceRepository([]);
        final evidenceCubit = EvidenceCubit(
          loadEntries: LoadEvidenceEntries(evidenceRepo),
          watchEntries: WatchEvidenceEntries(evidenceRepo),
        );
        await evidenceCubit.loadEntries();

        final workLogRepo = _FakeWorkLogRepository([]);
        final loadTrips = LoadProjectWorkLogTrips(workLogRepo);

        await tester.pumpWidget(
          harness(
            ProjectDetailView(
              projectName: '项目A',
              projectId: 1,
              projectCubit: projectCubit,
              photoCubit: photoCubit,
              evidenceCubit: evidenceCubit,
              expenseCubit: expenseCubit,
              expenseRecordRepository: expenseRepo,
              loadProjectWorkLogTrips: loadTrips,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 默认在动态页，展示 4 个过滤芯片
        expect(find.byType(FilterChip), findsNWidgets(4));

        // 点击切换到「照片」Tab
        await tester.tap(find.widgetWithText(Tab, '照片'));
        await tester.pumpAndSettle();

        expect(find.text('网格照片测试'), findsOneWidget);
        expect(find.byIcon(Icons.checklist_rtl_rounded), findsOneWidget);

        // 点击切换到「费用」Tab
        await tester.tap(find.widgetWithText(Tab, '费用'));
        await tester.pumpAndSettle();

        // 验证统计栏与费用项
        expect(find.text('项目支出'), findsOneWidget);
        expect(find.text('待报销'), findsNWidgets(2)); // 统计栏与卡片 badge
        expect(find.text('已报销'), findsOneWidget);
        expect(find.text('办公用品耗材'), findsOneWidget);
        expect(find.text('¥188.00'), findsNWidgets(3)); // 统计栏 (支出 + 待报销) + 列表卡片
        // 验证附件凭证图标
        expect(find.byIcon(Icons.receipt_long_rounded), findsWidgets);
      },
    );

    testWidgets('ProjectGalleryView delegates smoothly to ProjectDetailView', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final projectRepo = _FakeProjectRepository([
        const ProjectEntry(
          id: 1,
          name: '兼容项目',
          status: ProjectEntryStatus.active,
        ),
      ]);
      final projectCubit = ProjectCubit(
        loadEntries: LoadProjectEntries(projectRepo),
        watchEntries: WatchProjectEntries(projectRepo),
        saveEntry: SaveProjectEntry(projectRepo),
      );
      serviceLocator.registerSingleton<ProjectCubit>(projectCubit);

      final photoRepo = _FakePhotoRepository([]);
      final photoCubit = PhotoCubit(
        loadEntries: LoadPhotoEntries(photoRepo),
        watchEntries: WatchPhotoEntries(photoRepo),
      );
      serviceLocator.registerSingleton<PhotoCubit>(photoCubit);

      final evidenceRepo = _FakeEvidenceRepository([]);
      final evidenceCubit = EvidenceCubit(
        loadEntries: LoadEvidenceEntries(evidenceRepo),
        watchEntries: WatchEvidenceEntries(evidenceRepo),
      );
      serviceLocator.registerSingleton<EvidenceCubit>(evidenceCubit);

      final expenseCubit = ExpenseRecordCubit(
        loadEntries: LoadExpenseRecordEntries(_FakeExpensePort([])),
        watchEntries: WatchExpenseRecordEntries(_FakeExpensePort([])),
      );
      serviceLocator.registerSingleton<ExpenseRecordCubit>(expenseCubit);

      final expenseRepo = _FakeExpenseRecordRepository([]);
      serviceLocator.registerSingleton<ExpenseRecordRepository>(expenseRepo);

      final workLogRepo = _FakeWorkLogRepository([]);
      final loadTrips = LoadProjectWorkLogTrips(workLogRepo);
      serviceLocator.registerSingleton<LoadProjectWorkLogTrips>(loadTrips);

      await tester.pumpWidget(
        harness(const ProjectGalleryView(projectName: '兼容项目')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 验证通过 ProjectGalleryView 进入时成功呈现 ProjectDetailView
      expect(find.byType(ProjectDetailView), findsOneWidget);
      expect(find.text('兼容项目'), findsOneWidget);
      expect(find.text('动态'), findsOneWidget);
      expect(find.text('添加照片'), findsOneWidget);
    });
  });
}

// --- Test doubles ---

final class _FakeProjectRepository implements ProjectRepositoryPort {
  List<ProjectEntry> entries;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  _FakeProjectRepository([this.entries = const []]);

  @override
  Future<List<ProjectEntry>> getAllEntries() async =>
      List.unmodifiable(entries);

  @override
  Stream<void> watchEntries() => _controller.stream;

  @override
  Future<ProjectEntry> ensureEntry(String name) async {
    final found = entries.where((e) => e.name == name).firstOrNull;
    if (found != null) return found;
    final created = ProjectEntry(
      id: entries.length + 1,
      name: name,
      status: ProjectEntryStatus.active,
    );
    entries = [...entries, created];
    _controller.add(null);
    return created;
  }

  @override
  Future<ProjectEntry> saveEntry(ProjectEntry entry) async {
    entries = [
      for (final e in entries)
        if (e.id == entry.id) entry else e,
    ];
    _controller.add(null);
    return entry;
  }

  @override
  Future<ProjectEntry> saveCoverPath(
    ProjectEntry entry, {
    required String? localCoverPath,
    required String? coverImagePath,
  }) async {
    return saveEntry(
      ProjectEntry(
        id: entry.id,
        syncId: entry.syncId,
        name: entry.name,
        status: entry.status,
        stageNames: entry.stageNames,
        localCoverPath: localCoverPath,
        coverImagePath: coverImagePath,
      ),
    );
  }

  @override
  Future<void> deleteEntry(ProjectEntry entry) async {
    entries = entries.where((e) => e.id != entry.id).toList();
    _controller.add(null);
  }
}

final class _FakePhotoRepository implements PhotoRepositoryPort {
  final List<PhotoEntry> entries;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  _FakePhotoRepository([this.entries = const []]);

  @override
  Future<List<PhotoEntry>> getAllEntries() async => List.unmodifiable(entries);

  @override
  Stream<void> watchEntries() => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeEvidenceRepository implements EvidenceRepositoryPort {
  final List<EvidenceEntry> entries;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  _FakeEvidenceRepository([this.entries = const []]);

  @override
  Future<List<EvidenceEntry>> getAllEntries() async =>
      List.unmodifiable(entries);

  @override
  Stream<void> watchEntries() => _controller.stream;

  @override
  Future<EvidenceEditDraft?> getEditDraft(int id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeExpensePort implements ExpenseRecordRepositoryPort {
  final List<ExpenseRecordEntry> entries;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  _FakeExpensePort([this.entries = const []]);

  @override
  Future<List<ExpenseRecordEntry>> getAllEntries() async =>
      List.unmodifiable(entries);

  @override
  Stream<void> watchEntries() => _controller.stream;

  @override
  Future<ExpenseRecordEditDraft?> getEditDraft(int id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExpenseRecordRepository implements ExpenseRecordRepository {
  final List<ExpenseRecord> records;

  _FakeExpenseRecordRepository([this.records = const []]);

  @override
  Future<List<ExpenseRecord>> getExpenseRecordsByProject(
    String projectName,
  ) async {
    return records.where((r) => r.projectName == projectName).toList();
  }

  @override
  Future<List<ExpenseRecord>> getExpenseRecordsByProjectId(
    int projectId,
  ) async {
    return records.where((r) => r.projectId == projectId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeWorkLogRepository implements WorkLogRepositoryPort {
  final List<WorkLogEntry> entries;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  _FakeWorkLogRepository([this.entries = const []]);

  @override
  Future<List<WorkLogEntry>> getAllEntries() async =>
      List.unmodifiable(entries);

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async => [];

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Stream<void> watchEntries() => _controller.stream;
}

PhotoEntry _createPhoto({
  required int id,
  required String projectName,
  String fileName = 'test.jpg',
  String filePath = '/tmp/test.jpg',
  DateTime? createdAt,
  String? description,
  String? deviceName,
}) {
  final now = createdAt ?? DateTime(2026, 6, 1);
  return PhotoEntry(
    id: id,
    ownerUserId: null,
    createdAt: now,
    fileName: fileName,
    filePath: filePath,
    description: description,
    deviceName: deviceName,
    projectName: projectName,
    projectId: null,
    dateIndexed: now,
  );
}
