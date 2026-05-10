import 'package:flutter/widgets.dart';

class ConstrainedPage extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const ConstrainedPage({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final constrained = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (!scrollable) return constrained;

    return SingleChildScrollView(child: constrained);
  }
}
