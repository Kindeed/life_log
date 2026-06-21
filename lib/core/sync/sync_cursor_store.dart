class SyncCursor {
  final DateTime updatedAt;
  final String rowId;

  const SyncCursor({required this.updatedAt, required this.rowId});
}

abstract interface class SyncCursorStore {
  Future<SyncCursor?> read(String entityName);
  Future<void> write(String entityName, SyncCursor cursor);
}

final class InMemorySyncCursorStore implements SyncCursorStore {
  final _cursors = <String, SyncCursor>{};

  void seed(String entityName, SyncCursor cursor) {
    _cursors[entityName] = cursor;
  }

  SyncCursor? peek(String entityName) => _cursors[entityName];

  @override
  Future<SyncCursor?> read(String entityName) async {
    return _cursors[entityName];
  }

  @override
  Future<void> write(String entityName, SyncCursor cursor) async {
    _cursors[entityName] = cursor;
  }
}
