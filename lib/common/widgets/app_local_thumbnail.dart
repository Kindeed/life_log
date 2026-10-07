import 'dart:io';

import 'package:flutter/material.dart';

/// Bounded decoding for local list/grid media. Full-screen previews use their
/// original provider so zoom quality is independent of thumbnail caching.
class AppLocalThumbnail extends StatelessWidget {
  final String filePath;
  final ImageErrorWidgetBuilder? errorBuilder;

  const AppLocalThumbnail({
    super.key,
    required this.filePath,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        int? pixels(double extent) => extent.isFinite && extent > 0
            ? (extent * pixelRatio).ceil().clamp(1, 4096)
            : null;
        final width = pixels(constraints.maxWidth);
        final height = pixels(constraints.maxHeight);
        final original = FileImage(File(filePath));
        return Image(
          image: width == null && height == null
              ? original
              : ResizeImage(
                  original,
                  width: width,
                  height: height,
                  policy: ResizeImagePolicy.fit,
                ),
          fit: BoxFit.cover,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
