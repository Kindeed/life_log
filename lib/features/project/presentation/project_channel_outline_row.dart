import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';

enum ProjectChannelOutlineLevel { month, day, record }

/// One lazy row in a continuous month surface. The channel supplies endpoints;
/// no record subtree is built or measured to draw the outline.
class ProjectChannelOutlineRow extends StatelessWidget {
  final ProjectChannelOutlineLevel level;
  final bool isLastInMonth;
  final bool hasFollowingDay;
  final bool continuesDay;
  final Widget child;

  const ProjectChannelOutlineRow({
    super.key,
    required this.level,
    required this.isLastInMonth,
    required this.hasFollowingDay,
    this.continuesDay = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth < 340
            ? AppSpacing.md
            : AppSpacing.lg;
        final isMonth = level == ProjectChannelOutlineLevel.month;
        final isRecord = level == ProjectChannelOutlineLevel.record;
        final radius = BorderRadius.vertical(
          top: Radius.circular(isMonth ? AppRadius.sm : 0),
          bottom: Radius.circular(isLastInMonth ? AppRadius.sm : 0),
        );
        return Padding(
          padding: EdgeInsets.only(bottom: isLastInMonth ? AppSpacing.md : 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              // Flat interior rows share an edge. A zero-radius RRect can
              // antialias that edge into a hairline at fractional coordinates.
              borderRadius: isMonth || isLastInMonth ? radius : null,
            ),
            child: CustomPaint(
              painter: _OutlineRowPainter(
                level: level,
                inset: inset,
                isLastInMonth: isLastInMonth,
                hasFollowingDay: hasFollowingDay,
                continuesDay: continuesDay,
                color: scheme.outlineVariant,
                surfaceColor: scheme.surfaceContainerLow,
                textDirection: Directionality.of(context),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  isMonth ? 0 : (isRecord ? inset * 3 : inset),
                  isRecord ? AppSpacing.sm : 0,
                  isRecord ? AppSpacing.sm : 0,
                  isRecord ? AppSpacing.sm : 0,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OutlineRowPainter extends CustomPainter {
  final ProjectChannelOutlineLevel level;
  final double inset;
  final bool isLastInMonth;
  final bool hasFollowingDay;
  final bool continuesDay;
  final Color color;
  final Color surfaceColor;
  final TextDirection textDirection;

  const _OutlineRowPainter({
    required this.level,
    required this.inset,
    required this.isLastInMonth,
    required this.hasFollowingDay,
    required this.continuesDay,
    required this.color,
    required this.surfaceColor,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Adjacent lazy rows can meet at fractional pixels. Paint their straight
    // joins without edge antialiasing; actual month corners remain rounded by
    // the decoration behind this band. Nothing paints outside the row bounds.
    final top = level == ProjectChannelOutlineLevel.month ? AppRadius.sm : 0.0;
    final bottom = isLastInMonth ? size.height - AppRadius.sm : size.height;
    if (bottom > top) {
      canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, bottom),
        Paint()
          ..color = surfaceColor
          ..isAntiAlias = false,
      );
    }
    if (level == ProjectChannelOutlineLevel.month) return;
    canvas.save();
    if (textDirection == TextDirection.rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Guides finish before disclosure icons/cards, so they remain decorative
    // even when a large-text heading has more than one line.
    const monthRail = AppSpacing.md;
    final dayRail = inset + AppSpacing.sm + 9;
    if (level == ProjectChannelOutlineLevel.day) {
      final branchY = size.height.clamp(0, 48).toDouble() / 2;
      _branch(canvas, paint, monthRail, inset + AppSpacing.xs, branchY);
      if (hasFollowingDay) {
        canvas.drawLine(
          const Offset(monthRail, 0),
          Offset(monthRail, size.height),
          paint,
        );
      }
      if (continuesDay) {
        canvas.drawLine(
          Offset(dayRail, branchY + AppSpacing.md),
          Offset(dayRail, size.height),
          paint,
        );
      }
    } else {
      if (hasFollowingDay) {
        canvas.drawLine(
          const Offset(monthRail, 0),
          Offset(monthRail, size.height),
          paint,
        );
      }
      final branchY = (AppSpacing.sm + 24).clamp(0, size.height).toDouble();
      _branch(canvas, paint, dayRail, inset * 3 - AppSpacing.xs, branchY);
      if (continuesDay) {
        canvas.drawLine(
          Offset(dayRail, 0),
          Offset(dayRail, size.height),
          paint,
        );
      }
    }
    canvas.restore();
  }

  void _branch(Canvas canvas, Paint paint, double rail, double end, double y) {
    final bend = (end - rail).clamp(0, AppSpacing.xs).toDouble();
    final path = Path()
      ..moveTo(rail, 0)
      ..lineTo(rail, y - bend)
      ..quadraticBezierTo(rail, y, rail + bend, y)
      ..lineTo(end, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OutlineRowPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.inset != inset ||
      oldDelegate.isLastInMonth != isLastInMonth ||
      oldDelegate.hasFollowingDay != hasFollowingDay ||
      oldDelegate.continuesDay != continuesDay ||
      oldDelegate.color != color ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.textDirection != textDirection;
}
