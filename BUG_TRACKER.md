# LifeLog BUG Tracker

**Last updated**: 2026-05-13  
**Status values**: `open`, `in_progress`, `fixed`, `deferred`, `invalidated`

This is the active defect ledger. `REVIEW_REPORT.md` is historical context only. Photo sync findings from older reports are superseded by `AGENTS.md`: photos remain local-only and must not enter Supabase sync.

## Data / Sync

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D1 | High | fixed | `Project` sync | `Project` has cloud fields and remote schema, but client pull/push is incomplete. | Fixed: project pull/push/delete exists, and sync is limited to cloud-eligible projects or projects referenced by synced expense/evidence records. |
| D2 | High | fixed | owner claim | `claimUnownedRecordsForCurrentUser()` omits projects. | Fixed: unowned projects are claimed locally; only sync-eligible projects become dirty. |
| D3 | Medium | fixed | dirty marking | Save paths rely on UI to set `isDirty`. | Fixed: DB save paths mark dirty from business-field changes even if UI forgets. |
| D4 | Medium | fixed | backup | Backup exports Isar DB only, not photo/evidence files. | Fixed: UI and share text explicitly say database-only and warn that media files are not included. |
| D5 | Low | fixed | diagnostics | Diagnostic export includes the full Supabase URL. | Fixed: diagnostic/log exports mask the Supabase URL. |
| D6 | Medium | fixed | record audit timestamps | `WorkLog`, `ExpenseRecord`, and `ExpenseEvidence` store business dates but do not have explicit local `createdAt` / `updatedAt` audit timestamps. | Fixed: added local schema-backed audit timestamps, backfilled existing rows on DB init, stamped local save/delete and remote-pull writes, regenerated Isar code, and kept photos out of cloud-sync fields/protocols. |

## UI / Design System

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U1 | Medium | fixed | `AppSheetScaffold` | Keyboard inset changes jump without transition. | Fixed: scroll content uses tokenized animated padding; header/grabber remain stable. |
| U2 | Low | fixed | `AddLogSheet` | Cross-field focus switch can flicker the bottom bar. | Fixed: focus listeners coalesce to one post-frame final focus-state update. |
| U3 | Low | fixed | `AppSkeleton` | Skeleton color uses raw `Colors.white10`. | Fixed: color comes from theme color scheme. |
| U4 | Low | fixed | `AppEmptyState` | 74x74 icon container is hard-coded. | Fixed: icon container and icon sizes come from `AppSizes`. |
| U5 | Low | fixed | `AppMetricTile` | 38x38 icon container is hard-coded. | Fixed: icon container and icon sizes come from `AppSizes`. |
| U6 | Low | fixed | `AppLoading` | Loading label gap uses raw `12`. | Fixed: uses `AppSpacing.md`. |
| U7 | Low | fixed | `AppSafeBottomBar` | Shadow blur uses raw `24`. | Fixed: uses elevation/shadow token. |
| U8 | Low | fixed | `AppMotion` | Uses both `Easing.*` and raw `Curves.easeInOutCubic`. | Fixed: motion constants use tokenized `Easing.*`. |
| U9 | Low | fixed | `AppTheme` | Text styles force `letterSpacing: 0`; dialog theme is missing. | Fixed: app-theme text styles no longer force letter spacing and dialog theme exists. |
| U10 | Low | fixed | `DayCell` | Holiday badge can overlap double-digit dates. | Fixed: badge is pinned to a clipped corner with reserved top padding in a stable cell box. |
| U11 | Low | fixed | `StatisticsView` | Overtime text may become too small in calendar cells. | Fixed: calendar cell uses stable text sizing, not whole-cell `FittedBox`. |
| U12 | Medium | fixed | `WorkLogView` / `DayCell` | Selected calendar day renders as a stretched pill and can clip day metadata. | Fixed: selected/today decoration now uses stable per-cell bounds and keeps day/lunar text readable. |
| U13 | Medium | fixed | `WorkLogView` | Empty work-log detail area can overscroll indefinitely and the "记一笔" action feels unbounded. | Fixed: empty state occupies remaining viewport without an inner scroll body. |
| U18 | High | fixed | `WorkLogView` / `DayCell` | Selected calendar day can look oval and clip content on tighter layouts. | Fixed: calendar cell uses a smaller tokenized box, tighter margin, and reduced corner radius to keep selected content legible. |
| U19 | High | fixed | `WorkLogView` | Calendar rebuilds with `dataVersion` in the key and can discard taps in flight. | Fixed: table key now tracks the selected day only, so data refreshes do not recreate the calendar subtree. |
| U20 | Medium | fixed | `SubscriptionView` | Empty state and FAB both expose "添加支出", creating duplicate entry points. | Fixed: the FAB is hidden when there are no fixed costs or project expenses yet. |
| U21 | Medium | fixed | `CaptureDialog` | New-photo flow defaults to `DefaultProject`, which hides the create-project path. | Fixed: the project field starts blank and prompts the user to choose or create a project. |
| U22 | Medium | fixed | `CaptureDialog` | Function-scoped text controllers are never disposed. | Fixed: capture dialog now uses a stateful sheet and disposes its controllers with the sheet lifecycle. |
| U23 | High | fixed | `PhotoRepository` | Saved photo `fileName` can diverge from the actual archived filename after collision handling or rename. | Fixed: `fileName` now mirrors the basename of the real stored path. |
| U24 | High | fixed | `ProfileController` / `LoginView` | Logout leaves the user on the profile page, and registration lacks password confirmation. | Fixed: logout now redirects to `/login`, and registration includes a confirm-password field with a mismatch check. |
| U25 | Medium | fixed | `TabsView` | The center add entry was a generic icon-only button, so work/finance/project creation paths felt hidden and page switching felt abrupt. | Fixed: the center action is now contextual per tab, and page transitions use a slower eased animation with smoother tab-state updates. |
| U26 | Medium | fixed | `CalendarHeader` / `StatisticsView` | 真机日志出现 `RenderFlex overflowed`，月份标题行和统计头部右侧文案在窄屏下会横向溢出。 | Fixed: header rows now use flexible/ellipsis layout and reduced padding so the content can shrink cleanly on narrow devices. |
| U27 | High | fixed | `DayCell` | 真机日志出现 Flutter assertion: `decoration != null || clipBehavior == Clip.none`，普通日期单元格在无 decoration 时仍设置了裁剪。 | Fixed: day cells always provide a default rounded decoration before applying `Clip.antiAlias`. |
| U28 | Medium | fixed | `WorkLogView` layout / semantics | 真机 debug 日志出现 `RenderViewport does not support returning intrinsic dimensions`，随后触发 `!semantics.parentDataDirty`。根因是工时详情区在 `SliverFillRemaining(hasScrollBody: false)` 内嵌套 `ListView`，导致 Flutter 对 viewport 做 intrinsic height 测量。 | Fixed: 工时详情区改为普通 `Padding + DayLogList` 非 viewport 布局；重新安装 debug APK 后启动日志未再出现 `RenderViewport`、`semantics.parentDataDirty`、`RenderFlex overflowed` 或崩溃关键字。 |
| U29 | Medium | fixed | main tabs / work / finance / project | UI 中同时存在多个添加入口，且工作页空状态、财务页和项目页各自保留旧按钮，导致入口不统一、文案不一致、按钮时有时无。 | Fixed: removed page-local add buttons and empty-state add actions, and kept the bottom center tab action as the single primary add entry. |
| U30 | Medium | fixed | date display / date-only fields | `DateTime` 被当成时间戳直接格式化，导致日历、凭证、订阅和项目列表里的日期在真机上出现偏一天或偏时分的问题。 | Fixed: added local date normalization helpers and normalized work log, subscription, evidence, expense, and display formatting paths to `toLocal()` / `dateOnlyLocal()`. |
| U31 | Medium | fixed | `ProjectGalleryView` multi-select | 项目图片进入多选后只有“全选/全不选/取消”，没有持续可见的后续操作栏，用户容易误以为功能没完成。 | Fixed: multi-select now always shows a bottom action bar with delete/export/finish actions, even before selection is made. |
| U32 | Medium | fixed | evidence capture/import | 项目里的“凭证”入口只剩文字手工录入，拍照/相册导入链路没有从项目页直接暴露，容易被误判为功能未实现。 | Fixed: project evidence actions now expose capture, import, and manual entry; the editor already stores local files for attached evidence. |
| U33 | Medium | fixed | finance scope | 财务页同时承载固定支出和项目支出，和项目页里的项目支出入口重复。 | Fixed: finance page now only manages fixed subscriptions; project expenses remain in the project area. |
| U34 | High | fixed | work log calendar / statistics | 同一天不应同时存在多个工时状态，但当前保存和展示仍允许同日出现多条记录，并把它们当成不同状态处理。 | Fixed: same-day work logs now resolve to one final status per day; add/edit opens the existing day record when present, duplicate same-day saves are normalized away, and day cells/statistics render only the canonical state. |
| U35 | Medium | fixed | project empty state | 项目模块为空时直接引导添加照片/凭证/支出，没有先建立第一个项目，项目作为容器的工作流不清晰。 | Fixed: empty project state now prompts creating the first project, and existing project/photo/evidence/expense data still renders project cards instead of getting blocked by the empty prompt. |
| U36 | Medium | fixed | evidence editor attachments | 凭证编辑页只能显示已有附件或从入口带入附件，表单内没有拍摄/导入/更换发票和付款截图的动作，用户会认为不能保存凭证文件。 | Fixed: evidence editor now exposes camera, gallery, and file-import attachment actions, and saves the selected local attachment path and extension with the record. |
| U37 | Medium | fixed | date grouping / due-date display | 部分按月统计和到期判断仍在直接读原始 `DateTime` 的年月日，容易把本地/UTC 转换后的记录再算偏一天。 | Fixed: normalized the remaining expense, evidence, subscription, stats, and today-view date grouping/display paths to local dates. |
| U38 | Medium | fixed | project deletion | 创建项目后项目页没有明确删除入口，用户无法删除空项目或不再需要的项目。 | Fixed: project detail now exposes a visible destructive delete action, confirms impact, removes the project and its linked local records, and does not leave orphan project cards behind. |
| U39 | Medium | fixed | `DayCell` alignment | 日历日期数字和状态文本没有相对整个日期格居中，尤其是带 `+2h...` 状态时视觉偏移明显。 | Fixed: day-cell content now fills the whole cell before centering text, so date and status labels align to the cell center. |
| U40 | High | fixed | work log duplicate days | 旧数据中同一天可同时保留加班、出差等多条状态记录，显示层局部归并后仍可能在详情/编辑路径暴露冲突状态。 | Fixed: work-log loading now normalizes existing same-day duplicates through the repository, keeps the latest canonical record, and deletes duplicate records. |
| D7 | High | fixed | sync parsing | Remote row parsing and push response handling used `DateTime.parse` / direct casts and could abort a sync path on malformed or null fields. | Fixed: pull rows, push responses, server-time reads, and stored cursors now use safe numeric/string/date parsing with fallbacks or controlled failure for invalid remote IDs. |
| D8 | Medium | fixed | sync trigger dedupe | `syncAll` skipped a fresh manual sync for 2 seconds after the previous one finished. | Fixed: only an in-flight sync is reused now. |
| U14 | Medium | fixed | `ExpenseRecordEditView` | One-time expense add/edit UI is visually inconsistent with the current finance design system. | Fixed: reworked to a clearer amount-first card, category chips, tokenized surfaces, and stable bottom actions. |
| U15 | Medium | fixed | `PhotoView` / `ProjectGalleryView` / `PhotoPreviewView` | Empty project media flow hides credential/expense creation, project-first guidance is unclear, and photo preview has no remark editing path. | Fixed: empty and project actions expose photos, credentials, and expenses; preview supports remark editing. |
| U16 | Low | fixed | `PhotoPreviewView` | Delete action can pop navigation twice because both preview and controller call `Get.back()`. | Fixed: controller owns the post-delete pop. |
| U17 | Medium | fixed | `PhotoPreviewView` | 真机日志出现 `A TextEditingController was used after being disposed`，备注编辑弹窗把控制器交给 `whenComplete`，关闭/重建时存在生命周期竞态。 | Fixed: 备注编辑改为独立 stateful sheet，自行管理 `TextEditingController` 生命周期。 |

## Tooling / Validation

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| T1 | Medium | fixed | Flutter/Dart CLI | `flutter`/`dart` commands timed out inside the sandbox because the CLI could not write normal analytics/tool-state files under `C:\Users\WZH\AppData\Roaming`. | Fixed: reran with approved Flutter/Dart permissions; `flutter --version`, `dart --version`, `flutter analyze`, and `flutter test` complete successfully. |
| T2 | Low | fixed | GitHub Actions | GitHub Actions warned that Node.js 20 action runtime is deprecated and will default to Node.js 24 on 2026-06-02. | Fixed: opted both APK workflows into Node.js 24 action runtime with `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`. |
| T6 | High | fixed | Release content | `v1.4.2` / `v1.4.3` release builds did not include the full UI and business-content changes from the `codex/actions-node24-compat` test APK source commit `e115424`, even though the version number advanced. | Fixed: restored `e115424` UI/business-content changes onto `main`, kept the newer release metadata, revalidated, and prepared a corrected release. |

## Maintenance / Cleanup

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| C1 | Low | fixed | project cache | Regenerable Flutter project caches were present after prior local builds. | Fixed: ran `flutter clean`, restored dependency metadata with `flutter pub get`, verified the project, then removed test-regenerated `build` cache while keeping required `.dart_tool` metadata. |

## Invalidated Historical Findings

| ID | Status | Finding | Reason |
| --- | --- | --- | --- |
| H1 | invalidated | Add `syncId`/`remoteId`/`isDirty` etc. to `PhotoItem`. | Violates current hard constraint: photos are local-only. |
| H2 | invalidated | Add photo pull/push/merge paths to `SyncService`/`DbService`. | Violates current hard constraint: photos must not enter cloud sync. |

## Codex Review Findings (2026-05-11) - 未修改

### Data / Sync

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D9 | Critical | open | Sync - ExpenseRecord | `syncRemoteExpenseRecordToLocal` 中 `record.remoteId = remoteId` 为无条件赋值，而 WorkLog/Subscription/Evidence/Project 均使用条件赋值。不一致写法可能导致脏记录的 remoteId 被错误覆盖。 | 修正为条件赋值 `if (record.remoteId != remoteId) { record.remoteId = remoteId; }`，与其他实体保持一致。 |
| D10 | Critical | open | Sync - Migration | 迁移 `20260429_expense_evidence.sql` 创建表时缺少 `updated_at` 列，该列在后续迁移 `20260507_remote_schema_repair.sql` 中才添加。两个迁移之间存在窗口期，依赖 `updated_at` 的同步逻辑可能失败。 | 在 `20260429_expense_evidence.sql` 中添加 `updated_at timestamptz not null default now()` 列。 |
| D11 | Critical | open | Sync - WorkLog | `saveLog` 在同日已有记录时，先通过 `_adoptCanonicalIdentity` 复制旧记录身份，再调用 `addLog`。若 `addLog` 抛出异常，旧记录身份已被覆盖但新数据未持久化，存在数据丢失风险。 | 重构保存逻辑：先持久化新数据，成功后再处理同日旧记录清理。 |
| D12 | High | open | Local owner claim - PhotoItem | `claimUnownedRecordsForCurrentUser()` 认领 WorkLog、Subscription、ExpenseEvidence、ExpenseRecord、Project，但未认领本地 `PhotoItem`。未登录时创建的照片在登录后可能因本地账号隔离而不可见。 | 在不接入云同步、不添加云同步字段的前提下，仅补充本地 `PhotoItem.ownerUserId` 认领处理。 |
| D13 | High | open | Sync - Backup | `restoreFromBackup` 关闭数据库后到重新初始化之间存在状态窗口，期间任何数据库访问都可能失败。`_rebuildDatabaseControllers` 仅删除控制器并依赖懒加载重建。 | 在关闭旧 DB 前预加载新 DB；或提供明确恢复状态 UI，防止期间访问。 |
| D14 | High | open | Sync - Statistics | `refreshStats()` 使用 `Future.wait` 并发获取 4 个数据源，任一失败则 `catch` 仅记录错误，`_calculateAllStats()` 不执行，可能导致所有统计指标保持陈旧。 | 将各数据源的错误处理独立到每个 future 内部，确保部分成功时仍能计算已有数据。 |
| D15 | High | open | Sync - WorkLog race | `_normalizeDuplicateDays` 与 `saveLog` 均会删除同日重复记录，但 `saveLog` 运行在归一化保护锁之外，可能出现竞态。 | 将 `saveLog` 的同日去重逻辑纳入 `_normalizeDuplicateDaysFuture` 保护。 |
| D16 | High | open | Sync - Subscription | `reorderSubscriptions` 标记 `isDirty=true` 但不显式触发同步，用户关闭应用前排序变更可能丢失。 | 在 `reorderSubscriptions` 末尾显式调用 `SyncService.to.pushSubscription` 或 `syncAll`。 |
| D17 | Medium | open | Sync - Project auto-create | `syncRemoteExpenseRecordToLocal` 自动创建缺失 Project 时，设置 `isDirty = false` 且无 `syncId`，该项目不会同步到云端。 | 创建时分配 `syncId` 并标记 `isDirty = true`。 |
| D18 | Medium | open | Performance - Index | 多个模型的 `deletedAt` 字段未建立索引，而查询会按 `deletedAt == null` 过滤软删除记录。记录数增长后查询性能可能下降。 | 为包含 `deletedAt` 过滤的模型评估并添加 `@Index()` 注解。 |
| D19 | Medium | open | Sync - ExpenseRecord txn | `syncRemoteExpenseRecordToLocal` 在 writeTxn 内嵌套项目创建写入，Isar 事务行为需验证，可能导致不可预期错误。 | 将项目创建逻辑提取到外层单独事务，或避免嵌套写事务。 |
| D20 | Medium | open | Validation | `validateExpenseEvidence` 调用 `evidence.projectName.trim()` 时未判空，`projectName` 为 null 时会抛出异常。 | 增加 `evidence.projectName?.trim().isNotEmpty` 空值安全检查。 |
| D21 | Medium | open | Sync dedup | `syncAll` 复用 `_activeSync` 防重复，但手动下拉刷新等场景无法强制启动新同步。 | 增加 `forceNew` 参数，允许绕过复用机制。 |
| D22 | Medium | open | Sync - syncId consistency | `syncId` 分配在不同实体间条件不一致，维护成本高且容易引入行为差异。 | 统一 syncId 分配策略，并补充回归测试。 |
| D23 | Low | open | Sync - RefreshGate loop | `_RefreshGate._runLoop` 在 `_rerun` 被触发时可能长时间循环。 | 增加最大循环次数限制。 |

### UI / Design System

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U41 | Low | open | TodayView | `today_view.dart` 中 `TabsController.to.changePage(2)` 为硬编码 Tab 索引。若 Tab 顺序变更，将跳转至错误页面。 | 替换为命名路由或定义常量。 |

### Tooling / Configuration

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| T3 | Medium | open | CI/CD | `build.yml` 中 Supabase Secret 验证发生在依赖安装、代码生成、分析之后。若 Secret 缺失，前面步骤会白白执行。 | 将 Secret 验证移至 job 开始第一步。 |
| T4 | Low | open | Dependencies | `pubspec.yaml` 中 `get: ^4.6.6` 使用 `^` 范围，未来大版本变化可能带来构建风险。 | 定期运行 `flutter pub outdated`，或按需要锁定依赖范围。 |
| T5 | Medium | open | Auth | `AuthService` 无显式会话过期处理逻辑。Supabase 会话过期后，应用可能静默进入未登录状态，同步操作无声失败。 | 添加会话状态检查，在检测到 401 时自动登出并跳转登录页。 |

### Backup / Restore

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D24 | Low | open | Backup | `restoreFromBackup` 缺少明确警告：备份文件仅含数据库，不含照片、凭证等媒体文件。恢复后用户可能误以为数据完整。 | 恢复确认对话框中增加“照片和凭证文件需要单独备份”的提示。 |
