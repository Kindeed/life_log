import 'package:flutter/material.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/subscription/application/load_subscription_edit_draft.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

import 'subscription_edit_view.dart';

Future<void> openSubscriptionEditorPage(
  BuildContext context, {
  SubscriptionEntry? entry,
}) async {
  final input = await _resolveEditorInput(entry: entry);
  if (!context.mounted) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SubscriptionEditView(
        existingEntry: input.entry,
        existingAlreadyDirty: input.alreadyDirty,
      ),
    ),
  );
}

Future<_SubscriptionEditorInput> _resolveEditorInput({
  SubscriptionEntry? entry,
}) async {
  final activeEntry = entry;
  if (activeEntry == null || activeEntry.id == 0) {
    return _SubscriptionEditorInput(entry: activeEntry);
  }

  final result = await serviceLocator<LoadSubscriptionEditDraft>().call(
    activeEntry.id,
  );
  return result.valueOrNull == null
      ? _SubscriptionEditorInput(entry: activeEntry)
      : _SubscriptionEditorInput(
          entry: result.valueOrNull!.entry,
          alreadyDirty: result.valueOrNull!.alreadyDirty,
        );
}

final class _SubscriptionEditorInput {
  final SubscriptionEntry? entry;
  final bool alreadyDirty;

  const _SubscriptionEditorInput({
    required this.entry,
    this.alreadyDirty = false,
  });
}
