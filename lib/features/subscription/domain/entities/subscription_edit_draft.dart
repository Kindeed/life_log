import 'package:equatable/equatable.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

final class SubscriptionEditDraft extends Equatable {
  final SubscriptionEntry entry;
  final bool alreadyDirty;

  const SubscriptionEditDraft({required this.entry, this.alreadyDirty = false});

  @override
  List<Object?> get props => [entry, alreadyDirty];
}
