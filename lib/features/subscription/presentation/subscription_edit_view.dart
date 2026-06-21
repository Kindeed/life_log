import 'package:flutter/material.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';

import 'add_subscription_sheet.dart';

class SubscriptionEditView extends StatelessWidget {
  final SubscriptionEntry? existingEntry;
  final bool existingAlreadyDirty;

  const SubscriptionEditView({
    super.key,
    this.existingEntry,
    this.existingAlreadyDirty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AddSubscriptionSheet(
          existingEntry: existingEntry,
          existingAlreadyDirty: existingAlreadyDirty,
          asPage: true,
        ),
      ),
    );
  }
}
