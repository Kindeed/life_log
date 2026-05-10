import 'package:flutter/material.dart';
import 'package:life_log/modules/subscription/add_subscription_sheet.dart';
import 'package:life_log/modules/subscription/subscription_model.dart';

class SubscriptionEditView extends StatelessWidget {
  final Subscription? sub;

  const SubscriptionEditView({super.key, this.sub});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: AddSubscriptionSheet(sub: sub, asPage: true)),
    );
  }
}
