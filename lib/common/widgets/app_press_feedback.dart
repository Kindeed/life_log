import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Adds a small press response without taking ownership of taps or semantics.
class AppPressFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AppPressFeedback({super.key, required this.child, this.enabled = true});

  @override
  State<AppPressFeedback> createState() => _AppPressFeedbackState();
}

class _AppPressFeedbackState extends State<AppPressFeedback> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if ((value && !widget.enabled) || value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant AppPressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && widget.enabled && !reduceMotion ? 0.98 : 1,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.standardDecelerate,
        child: widget.child,
      ),
    );
  }
}
