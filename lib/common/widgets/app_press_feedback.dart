import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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
  int? _activePointer;
  Offset? _pressOrigin;

  void _release() {
    _activePointer = null;
    _pressOrigin = null;
    _setPressed(false);
  }

  void _setPressed(bool value) {
    if ((value && !widget.enabled) || value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant AppPressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _activePointer = null;
      _pressOrigin = null;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (event) {
        if (!widget.enabled || _activePointer != null) return;
        _activePointer = event.pointer;
        _pressOrigin = event.position;
        _setPressed(true);
      },
      onPointerMove: (event) {
        if (event.pointer != _activePointer) return;
        if ((event.position - _pressOrigin!).distance > kTouchSlop) _release();
      },
      onPointerUp: (event) {
        if (event.pointer == _activePointer) _release();
      },
      onPointerCancel: (event) {
        if (event.pointer == _activePointer) _release();
      },
      child: AnimatedScale(
        scale: _pressed && widget.enabled && !reduceMotion ? 0.98 : 1,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.standardDecelerate,
        child: widget.child,
      ),
    );
  }
}
