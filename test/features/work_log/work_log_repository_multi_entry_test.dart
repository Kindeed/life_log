import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/work_log/data/work_log_local_data_source.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/work_log/data/work_log_repository.dart';
import 'package:life_log/features/work_log/data/work_log_sync_gateway.dart';

void main() {
  group('WorkLogRepository multi-entry day policy', () {
    test('saveLog preserves different same-day entry types', () async {
      final local = _FakeWorkLogLocalDataSource([
        _log(
          id: 1,
          date: DateTime(2026, 5, 9),
          type: LogType.leave,
          note: 'leave',
        ),
      ]);
      final repository = WorkLogRepository(
        localDataSource: local,
        syncGateway: const _FakeWorkLogSyncGateway(),
      );

      await repository.saveLog(
        _log(id: 0, date: DateTime(2026, 5, 9, 18), note: 'work'),
      );

      final logs = await repository.getLogsByMonth(DateTime(2026, 5));

      expect(logs.map((log) => log.note), ['leave', 'work']);
      expect(local.addedLogs.map((log) => log.id), [2]);
      expect(local.markedDeletedIds, isEmpty);
      expect(local.purgedIds, isEmpty);
    });

    test('new same-day work entry updates the existing work record', () async {
      final local = _FakeWorkLogLocalDataSource([
        _log(id: 4, date: DateTime(2026, 7, 7), note: 'first')
          ..syncId = 'work-20260707',
      ]);
      final repository = WorkLogRepository(
        localDataSource: local,
        syncGateway: const _FakeWorkLogSyncGateway(),
      );

      await repository.saveLog(
        _log(id: 0, date: DateTime(2026, 7, 7), note: 'second')
          ..overtimeHours = 3,
      );

      final logs = await repository.getLogsByMonth(DateTime(2026, 7));

      expect(logs, hasLength(1));
      expect(logs.single.id, 4);
      expect(logs.single.syncId, 'work-20260707');
      expect(logs.single.note, 'second');
      expect(logs.single.overtimeHours, 3);
      expect(local.addedLogs.map((log) => log.id), [4]);
      expect(local.markedDeletedIds, isEmpty);
      expect(local.purgedIds, isEmpty);
    });

    test(
      'saveLog keeps adjacent days when repeated same-day work is updated',
      () async {
        final local = _FakeWorkLogLocalDataSource();
        final repository = WorkLogRepository(
          localDataSource: local,
          syncGateway: const _FakeWorkLogSyncGateway(),
        );

        await repository.saveLog(
          _log(id: 0, date: DateTime(2026, 6, 23), note: 'yesterday-1')
            ..ownerUserId = 'user-1',
        );
        await repository.saveLog(
          _log(id: 0, date: DateTime(2026, 6, 24), note: 'today')
            ..ownerUserId = 'user-1',
        );
        await repository.saveLog(
          _log(id: 0, date: DateTime(2026, 6, 23), note: 'yesterday-2')
            ..ownerUserId = 'user-1',
        );

        final logs = await repository.getLogsByMonth(DateTime(2026, 6));

        expect(
          logs
              .where((log) => log.date == DateTime(2026, 6, 23))
              .map((log) => log.note),
          ['yesterday-2'],
        );
        expect(
          logs
              .where((log) => log.date == DateTime(2026, 6, 24))
              .map((log) => log.note),
          ['today'],
        );
        expect(local.markedDeletedIds, isEmpty);
        expect(local.purgedIds, isEmpty);
      },
    );

    test(
      'normalizeDuplicateDays normalizes dates without purging duplicates',
      () async {
        final local = _FakeWorkLogLocalDataSource([
          _log(id: 1, date: DateTime(2026, 5, 9, 8), note: 'morning'),
          _log(id: 2, date: DateTime(2026, 5, 9, 18), note: 'overtime'),
        ]);
        final repository = WorkLogRepository(
          localDataSource: local,
          syncGateway: const _FakeWorkLogSyncGateway(),
        );

        await repository.normalizeDuplicateDays();

        expect(local.addedLogs.map((log) => log.id), [1, 2]);
        expect(local.addedLogs.map((log) => log.date), [
          DateTime(2026, 5, 9),
          DateTime(2026, 5, 9),
        ]);
        expect(local.markedDeletedIds, isEmpty);
        expect(local.purgedIds, isEmpty);
      },
    );

    test('deleteLog deletes only the requested entry id', () async {
      final local = _FakeWorkLogLocalDataSource([
        _log(id: 1, date: DateTime(2026, 5, 9), note: 'morning'),
        _log(id: 2, date: DateTime(2026, 5, 9), note: 'overtime'),
      ]);
      final repository = WorkLogRepository(
        localDataSource: local,
        syncGateway: const _FakeWorkLogSyncGateway(),
      );

      await repository.deleteLog(1);

      expect(local.markedDeletedIds, [1]);
      expect(local.purgedIds, [1]);
    });
  });
}

WorkLog _log({
  required int id,
  required DateTime date,
  LogType type = LogType.work,
  String? note,
}) {
  return WorkLog()
    ..id = id
    ..date = date
    ..type = type
    ..overtimeHours = 1
    ..note = note;
}

final class _FakeWorkLogLocalDataSource implements WorkLogLocalDataSource {
  final List<WorkLog> logs;
  final addedLogs = <WorkLog>[];
  final markedDeletedIds = <int>[];
  final purgedIds = <int>[];
  var _nextId = 1;

  _FakeWorkLogLocalDataSource([List<WorkLog>? logs]) : logs = logs ?? [] {
    for (final log in this.logs) {
      if (log.id >= _nextId) {
        _nextId = log.id + 1;
      }
    }
  }

  @override
  Future<int> addLog(WorkLog log) async {
    if (log.id == 0) {
      log.id = _nextId++;
    }
    logs.removeWhere((existing) => existing.id == log.id);
    logs.add(log);
    logs.sort((a, b) => a.date.compareTo(b.date));
    addedLogs.add(log);
    return log.id;
  }

  @override
  Future<List<WorkLog>> getAllLogs() async => logs;

  @override
  Future<List<WorkLog>> getLogsByMonth(DateTime month) async => logs;

  @override
  Future<List<WorkLog>> getLogsForDay(DateTime date) async {
    return logs
        .where(
          (log) =>
              log.date.year == date.year &&
              log.date.month == date.month &&
              log.date.day == date.day,
        )
        .toList();
  }

  @override
  Future<WorkLog?> getWorkLog(int id) async {
    for (final log in logs) {
      if (log.id == id) return log;
    }
    return null;
  }

  @override
  Future<WorkLog?> markLogDeleted(int id) async {
    markedDeletedIds.add(id);
    final log = await getWorkLog(id);
    if (log == null) return null;
    log.pendingDelete = true;
    log.deletedAt = DateTime(2026, 5, 10);
    return log;
  }

  @override
  Future<void> purgeDeletedLog(int id) async {
    purgedIds.add(id);
  }

  @override
  Stream<void> watchWorkLogs() => const Stream.empty();
}

final class _FakeWorkLogSyncGateway implements WorkLogSyncGateway {
  const _FakeWorkLogSyncGateway();

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestSync(WorkLog log, {required String reason}) async => true;
}
