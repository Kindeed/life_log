import 'package:equatable/equatable.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';

final class WorkLogEditDraft extends Equatable {
  final WorkLogEntry entry;
  final bool alreadyDirty;

  const WorkLogEditDraft({required this.entry, this.alreadyDirty = false});

  @override
  List<Object?> get props => [entry, alreadyDirty];
}
