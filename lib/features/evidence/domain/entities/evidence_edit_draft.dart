import 'package:equatable/equatable.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';

final class EvidenceEditDraft extends Equatable {
  final EvidenceEntry entry;
  final bool alreadyDirty;

  const EvidenceEditDraft({required this.entry, this.alreadyDirty = false});

  @override
  List<Object?> get props => [entry, alreadyDirty];
}
