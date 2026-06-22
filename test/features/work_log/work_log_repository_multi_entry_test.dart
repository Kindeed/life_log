import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/work_log/data/work_log_local_data_source.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/work_log/data/work_log_repository.dart';
import 'package:life_log/features/work_log/data/work_log_sync_gateway.dart';

void main() {
  group('WorkLogRepository multi-entry day policy', () {
    test('saveLog does not delete existing same-day entries', () async {
      final local = _FakeWorkLogLocalDataSource([
        _log(id: 1, date: DateTime(2026, 5, 9), note: 'morning'),
      ]);
      final repository = WorkLogRepository(
        localDataSource: local,
        syncGateway: const _FakeWorkLogSyncGateway(),
      );

      await repository.saveLog(
        _log(id: 2, date: DateTime(2026, 5, 9, 18), note: 'overtime'),
      );

      expect(local.addedLogs.map((log) => log.id), [2]);
      expect(local.markedDeletedIds, isEmpty);
      expect(local.purgedIds, isEmpty);
    });

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

WorkLog _log({required int id, required DateTime date, String? note}) {
  return WorkLog()
    ..id = id
    ..date = date
    ..type = LogType.work
    ..overtimeHours = 1
    ..note = note;
}

final class _FakeWorkLogLocalDataSource implements WorkLogLocalDataSource {
  final List<WorkLog> logs;
  final addedLogs = <WorkLog>[];
  final markedDeletedIds = <int>[];
  final purgedIds = <int>[];

  _FakeWorkLogLocalDataSource(this.logs);

  @override
  Future<int> addLog(WorkLog log) async {
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
