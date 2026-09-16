import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// A local read failure is distinct from an empty database or cloud outage.
class AppLoadFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;
  const AppLoadFailure({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Icon(Icons.error_outline_rounded, color: colors.error, size: 32),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.text(
              label: '重试',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
