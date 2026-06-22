import 'package:life_log/core/sync/sync_cursor_store.dart';

final class SyncPullPage {
  final SyncCursor? cursor;
  final DateTime upperBound;
  final int pageSize;

  const SyncPullPage({
    required this.cursor,
    required this.upperBound,
    required this.pageSize,
  });

  factory SyncPullPage.start({
    required SyncCursor? cursor,
    required int pageSize,
    DateTime? upperBound,
  }) {
    return SyncPullPage(
      cursor: cursor,
      upperBound: upperBound?.toUtc() ?? DateTime.now().toUtc(),
      pageSize: pageSize.clamp(1, 1000).toInt(),
    );
  }

  dynamic applyTo(dynamic query) {
    var next = query.lte('updated_at', upperBound.toIso8601String());
    final activeCursor = cursor;
    if (activeCursor != null) {
      next = next.or(_keysetFilter(activeCursor));
    }
    return next;
  }

  bool isAfterCursor(Map<String, dynamic> row) {
    final activeCursor = cursor;
    if (activeCursor == null) return true;
    final rowCursor = cursorFromRow(row);
    if (rowCursor == null) return false;
    if (rowCursor.updatedAt.isAfter(activeCursor.updatedAt)) return true;
    if (rowCursor.updatedAt.isBefore(activeCursor.updatedAt)) return false;
    return _compareRowId(rowCursor.rowId, activeCursor.rowId) > 0;
  }

  SyncPullPage advance(SyncCursor nextCursor) {
    return SyncPullPage(
      cursor: nextCursor,
      upperBound: upperBound,
      pageSize: pageSize,
    );
  }

  static SyncCursor? cursorFromRow(Map<String, dynamic> row) {
    final updatedAtRaw = row['updated_at'];
    final rowIdRaw = row['id'];
    if (updatedAtRaw == null || rowIdRaw == null) return null;

    final updatedAt = updatedAtRaw is DateTime
        ? updatedAtRaw.toUtc()
        : DateTime.tryParse(updatedAtRaw.toString())?.toUtc();
    if (updatedAt == null) return null;
    return SyncCursor(updatedAt: updatedAt, rowId: rowIdRaw.toString());
  }

  static String _keysetFilter(SyncCursor cursor) {
    final updatedAt = cursor.updatedAt.toIso8601String();
    final rowId = cursor.rowId;
    return 'updated_at.gt.$updatedAt,and(updated_at.eq.$updatedAt,id.gt.$rowId)';
  }

  static int _compareRowId(String left, String right) {
    final leftInt = int.tryParse(left);
    final rightInt = int.tryParse(right);
    if (leftInt != null && rightInt != null) {
      return leftInt.compareTo(rightInt);
    }
    return left.compareTo(right);
  }
}
