import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppFloatingActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool visible;
  final VoidCallback onPressed;

  const AppFloatingActionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: AppMotion.normal,
      curve: AppMotion.standardDecelerate,
      offset: visible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: AppMotion.normal,
        curve: AppMotion.standardDecelerate,
        opacity: visible ? 1 : 0,
        child: FloatingActionButton.extended(
          backgroundColor: color,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          icon: Icon(icon, color: Colors.white),
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          onPressed: visible ? onPressed : null,
        ),
      ),
    );
  }
}
