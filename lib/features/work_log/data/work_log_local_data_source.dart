import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';

abstract interface class WorkLogLocalDataSource {
  Future<List<WorkLog>> getAllLogs();
  Future<List<WorkLog>> getLogsByMonth(DateTime month);
  Stream<void> watchWorkLogs();
  Future<int> addLog(WorkLog log);
  Future<List<WorkLog>> getLogsForDay(DateTime date);
  Future<WorkLog?> getWorkLog(int id);
  Future<WorkLog?> markLogDeleted(int id);
  Future<void> purgeDeletedLog(int id);
}

final class DbWorkLogLocalDataSource implements WorkLogLocalDataSource {
  const DbWorkLogLocalDataSource();

  @override
  Future<int> addLog(WorkLog log) => serviceLocator<DbService>().addLog(log);

  @override
  Future<List<WorkLog>> getAllLogs() =>
      serviceLocator<DbService>().getAllLogs();

  @override
  Future<List<WorkLog>> getLogsByMonth(DateTime month) {
    return serviceLocator<DbService>().getLogsByMonth(month);
  }

  @override
  Future<List<WorkLog>> getLogsForDay(DateTime date) {
    return serviceLocator<DbService>().getLogsForDay(date);
  }

  @override
  Future<WorkLog?> getWorkLog(int id) {
    return serviceLocator<DbService>().getWorkLog(id);
  }

  @override
  Future<WorkLog?> markLogDeleted(int id) {
    return serviceLocator<DbService>().markLogDeleted(id);
  }

  @override
  Future<void> purgeDeletedLog(int id) {
    return serviceLocator<DbService>().purgeDeletedLog(id);
  }

  @override
  Stream<void> watchWorkLogs() => serviceLocator<DbService>().watchWorkLogs();
}
