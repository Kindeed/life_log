import 'package:equatable/equatable.dart';

/// Read-only membership. Names are a fallback for unlinked legacy records.
final class ProjectRecordScope extends Equatable {
  final String name;
  final int? id;
  final String? syncId;

  const ProjectRecordScope({required this.name, this.id, this.syncId});

  bool contains({String? name, int? id, String? syncId}) {
    final recordSyncId = syncId?.trim();
    final scopeSyncId = this.syncId?.trim();
    if (recordSyncId?.isNotEmpty == true && scopeSyncId?.isNotEmpty == true) {
      return recordSyncId == scopeSyncId;
    }
    if (id != null && this.id != null) return id == this.id;
    if (id != null || recordSyncId?.isNotEmpty == true) return false;
    return name?.trim() == this.name.trim();
  }

  @override
  List<Object?> get props => [name, id, syncId];
}
