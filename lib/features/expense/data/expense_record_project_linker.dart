import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/project/data/project_repository.dart';

abstract interface class ExpenseRecordProjectLinker {
  Future<ExpenseRecordLinkedProject> ensureSyncableProject(String name);
}

final class ExpenseRecordLinkedProject {
  final int id;
  final String name;
  final String? syncId;

  const ExpenseRecordLinkedProject({
    required this.id,
    required this.name,
    this.syncId,
  });
}

final class GetItExpenseRecordProjectLinker
    implements ExpenseRecordProjectLinker {
  const GetItExpenseRecordProjectLinker();

  @override
  Future<ExpenseRecordLinkedProject> ensureSyncableProject(String name) async {
    final project = await serviceLocator<ProjectRepository>()
        .ensureSyncableProject(name);
    return ExpenseRecordLinkedProject(
      id: project.id,
      name: project.name,
      syncId: project.syncId,
    );
  }
}
