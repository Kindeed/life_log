class LocalDataMigrationSummary {
  final int workLogs;
  final int subscriptions;
  final int evidence;
  final int expenseRecords;
  final int projects;
  final int photos;

  const LocalDataMigrationSummary({
    required this.workLogs,
    required this.subscriptions,
    required this.evidence,
    required this.expenseRecords,
    required this.projects,
    required this.photos,
  });

  int get totalCount =>
      workLogs + subscriptions + evidence + expenseRecords + projects + photos;

  bool get hasData => totalCount > 0;
}
