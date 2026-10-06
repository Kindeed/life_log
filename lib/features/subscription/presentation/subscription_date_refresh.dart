import 'dart:async';

import 'package:flutter/widgets.dart';

/// Checks the local day while the page is active and when the app resumes.
class SubscriptionDateRefresh extends StatefulWidget {
  final VoidCallback onRefresh;
  final Widget child;

  const SubscriptionDateRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<SubscriptionDateRefresh> createState() =>
      _SubscriptionDateRefreshState();
}

class _SubscriptionDateRefreshState extends State<SubscriptionDateRefresh>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      widget.onRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onRefresh();
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
