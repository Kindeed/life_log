# LifeLog Component Catalog

Use existing tokens and components before adding new UI primitives.

## Tokens

- `AppTheme`: app-level Material 3 theme setup in `lib/common/theme/app_theme.dart`
- `AppTypography`: shared text theme in `lib/common/theme/app_typography.dart`
- `AppSpacing`: spacing scale in `lib/common/theme/app_spacing.dart`
- `AppRadius`: radius scale in `lib/common/theme/app_radius.dart`
- `AppMotion`: motion timing in `lib/common/theme/app_motion.dart`
- `AppSizes`: stable component dimensions in `lib/common/theme/app_sizes.dart`

## Page Templates

- `AppPage`: constrained generic pages. Example: `lib/common/widgets/app_page.dart`
- `AppListPage`: list screens with overview and slivers. Example:
  `lib/features/subscription/presentation/subscription_view.dart`
- `AppFormPage`: form screens. Example: `lib/common/widgets/app_form_page.dart`
- `AppDetailPage`: detail screens. Example: `lib/common/widgets/app_detail_page.dart`

## Reusable Components

- `AppCard`: use for individual repeated items, dashboard summaries, and
  tappable rows. Do not nest cards inside cards.
- `AppButton`: use for explicit commands and empty-state actions.
- `AppMetricGrid` and `AppMetricTile`: use for compact summary metrics when the
  screen genuinely needs comparison.
- `AppSection`: use for titled groups inside forms and list overviews.
- `AppEmptyState`: use for empty, blocked, or no-results states.
- `AppFilterChipBar`: use for local filters such as Records filters:
  all, work, expense, evidence, subscription.
- `AppSwipeAction`: use for destructive list actions that need a stable delete
  affordance.
- `AppFloatingActionPill`: use only when a floating primary action is more
  scannable than a regular app-bar or inline button.

## Visual Roles

- Hero Card: one high-emphasis card for the most important current status.
- Summary Row: compact metrics without making every number a large card.
- Timeline Item: lightweight historical row with type, title, subtitle, amount
  or status, and timestamp.
- Action Sheet: bottom sheet for choosing record type or add mode.
- Quiet Card: low-emphasis card for secondary context.

Every component must cover loading, empty, failure, disabled, and narrow-screen
states when those states apply to the screen.
