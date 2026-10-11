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

- `AppTabHeader`, `AppTabAction` and `AppTabIconAction`: consistent primary-tab
  titles and optional 48px header actions; More uses one account card.
- `AppPressFeedback`: shared subtle press feedback, including cancellation and
  disabled-state reset; respects reduced motion through AppMotion.
- `appPageRoute`/`AppMaterialPageRoute`: shared timing while retaining platform
  Material transitions, route results and predictive back.
- `showAppBottomSheet`: shared enter/reverse timing without changing the caller's
  dismissal, focus, layout or controller ownership.
- `AppFeedback`: captured parent-messenger feedback with measured compact width,
  paired success/info/error colors and queue replacement.
- `AppFormFeedback`: visible inline form/modal status with optional semantic icon.
- `AppPill`/`AppStatusColors`: wrapping display badges and contrast-checked opaque
  foreground/container pairs in both themes and dynamic colors.
- `AppSettingsGroup`/`AppSettingsTile`: common settings rows, dividers and labelled
  merged switch semantics; reflows under larger system text.

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

## Interaction and verification additions (2026-09-16)

- `AppLoadFailure`: retryable local-read failures. Use compact mode above retained
  content for partial failures; never replace a failed read with an empty state.
- `AppUnsavedChangesGuard`: protects changed work/subscription form drafts on
  back navigation; busy commands block dismissal. It is independent of sync dirty
  metadata. Guarded editor sheets use an explicit close action rather than drag
  or barrier dismissal. Successful explicit save/delete may close the route.
- `AppListPage.embedded`: suppresses the page app bar when a list is hosted under
  another page's navigation/filter header (for example, timeline subscriptions).
- `AppMotion.duration`: respects the platform reduced-motion setting. Use it for
  shared transitions and calculator workbench expansion/results.

`test/ui_refinement_test.dart` covers dynamic-color text contrast, guarded draft
exit, subscription single-flight saves/failure recovery, work-read failure, and
work/more/subscription layout at 390px normal text and 320px double text scale
in both themes. Subscription checks exercise empty-category filtering, large
amounts, long names, currency conversion and confirmed deletion cancellation.
The subscription overview emphasizes the current-month estimate, with a secondary
annual estimate. Reminder details expand on demand; item actions use an explicit
overflow menu. Missing exchange rates must remain visible beside estimated totals.
Optional `UI_REVIEW_DIR`, `UI_REVIEW_FONT`, and `UI_REVIEW_ICONS` dart defines
produce local render previews. Fonts are local test inputs only, not redistributed
application assets. These previews do not replace Android device verification.

## Project stages and amount input (2026-10-07)

- `AppAmountField`: shared explicit amount/currency input for expenses and receipts;
  optional receipt values stay absent, errors remain inline and busy input locks.
- `ProjectStageField`: preserves selected historical stage names and labels the
  relationship consistently in photo, expense and evidence editors.
- `showProjectStagesSheet`: ordered, additive stage management with retryable save.
  Names are existing relationship keys; do not silently rename/remove old stages.
- Project detail uses one stage selector across its three destinations. Keep
  unassigned history reachable and scope each original-currency expense total.
- Normal expense categories use rounded choices; large text uses a picker.
  All form cards share a full-width edge. Actual CJK layout and interaction coverage
  lives in `test/features/project/project_detail_ui_test.dart`.
