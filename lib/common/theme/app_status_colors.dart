import 'package:flutter/material.dart';

/// An opaque container and a readable foreground for small status text.
/// Resolving the pair together avoids depending on the surface beneath a pill.
class AppStatusColors {
  final Color foreground;
  final Color container;

  const AppStatusColors(this.foreground, this.container);

  factory AppStatusColors.fromTint(
    ThemeData theme,
    Color tint, {
    bool selected = false,
  }) {
    final container = Color.alphaBlend(
      tint.withValues(alpha: selected ? 0.16 : 0.10),
      theme.colorScheme.surface,
    );
    if (contrast(tint, container) >= 4.5) {
      return AppStatusColors(tint, container);
    }
    final endpoint =
        contrast(Colors.black, container) > contrast(Colors.white, container)
        ? Colors.black
        : Colors.white;
    var low = 0.0;
    var high = 1.0;
    for (var step = 0; step < 20; step++) {
      final middle = (low + high) / 2;
      if (contrast(Color.lerp(tint, endpoint, middle)!, container) >= 4.5) {
        high = middle;
      } else {
        low = middle;
      }
    }
    return AppStatusColors(Color.lerp(tint, endpoint, high)!, container);
  }

  static double contrast(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    return (first > second ? first + 0.05 : second + 0.05) /
        (first > second ? second + 0.05 : first + 0.05);
  }
}
