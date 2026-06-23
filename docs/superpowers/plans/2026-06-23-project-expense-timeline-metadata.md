# Project Expense Timeline Metadata Implementation Plan

> **For WZH:** implement the first usable slice of project-expense timeline metadata. Keep photos local-only and record defects in BUG_TRACKER.md.

**Goal:** Project detail should treat expenses as “项目费用”, support event-date vs import-date timeline sorting, preserve photo captured-time/GPS metadata when available, and expose enough domain timestamps for later linkage between project expenses, evidence, and work logs.

**Scope**

- Rename project-detail expense surfaces from `支出` to `项目费用`.
- Split photo import/archive time from captured/event time.
- Store optional photo GPS latitude/longitude locally, hidden by default.
- Add project timeline sort mode: `事件日期` and `导入日期`.
- Expose created/updated audit timestamps in evidence and expense domain entries so import-date sorting can work.
- Add optional project association fields to work logs for later trip/project reporting.

**Compatibility**

- Additive nullable fields only.
- Existing rows remain valid; missing captured time falls back to `createdAt`.
- Existing expense/evidence rows without audit timestamps fall back to their business dates in timeline sorting.
- Photo metadata remains local-only and must not be added to sync protocols.

**Validation**

- Focused tests for photo local-only metadata, project dashboard source contract, expense/evidence timestamp mapping, and work-log project association.
- Run analyzer and photo local-only architecture test before completion.

## Trip and Project Expense Link Slice

**Goal:** Make `工时-出差` the only work-log type that can link to a project, show those trips in the project timeline, and let project expenses optionally link back to a trip without blocking late imports or uncertain receipts.

**Scope**

- Add editable project association to business-trip work logs only.
- Clear project association when a work log is changed to work/rest/leave.
- Show project-linked business trips in project overview/timeline.
- Add optional trip-work-log association to project expenses using the work-log stable sync id for cloud sync.
- Warn about likely duplicate project expenses by same date, amount, and currency; do not block saving.
- When deleting a project, unlink work-log trips instead of deleting the labor/travel history.

**Compatibility**

- New trip-link fields are nullable; old expenses remain valid.
- Missing trip links show as unlinked expenses.
- Existing work logs without project ids continue to behave as before.
- Photos stay local-only and remain outside every sync path.
