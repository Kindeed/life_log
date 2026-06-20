# LifeLog UI AI Handoff

Use this document when asking Gemini, Claude, or another UI design assistant to
propose LifeLog interface changes.

## Non-negotiable Constraints

- Build for Flutter with the existing Material 3 theme in `lib/common/theme`.
- Reuse common widgets from `lib/common/widgets` before proposing new patterns.
- Do not change persistence, sync, database schemas, Supabase tables, or service
  contracts from a UI prompt.
- Photos are local-only. Do not add photo cloud sync, photo remote metadata, or
  photo conflict-resolution UI.
- Treat `BUG_TRACKER.md` as the active defect ledger. UI layout, motion,
  accessibility, token, and consistency issues count as tracked bugs.

## Expected Output From AI Design Tools

- A screen-by-screen UI spec with layout, hierarchy, states, and interaction
  behavior.
- Explicit notes for loading, empty, error, disabled, and narrow-screen states.
- Token-level guidance using existing spacing, radius, color, typography, and
  motion concepts instead of raw one-off values.
- Accessibility notes for labels, contrast, focus order, touch targets, and text
  scaling.
- No generated backend code, schema changes, or sync logic.

## Integration Rule

AI output is design input only. The accepted implementation must be translated
into this Flutter codebase, covered by widget/source tests, checked against
`BUG_TRACKER.md`, and verified with the standard gates:

- `flutter analyze --no-fatal-infos`
- `flutter test`
- `git diff --check`
- `flutter build apk --debug` when preparing a test APK
