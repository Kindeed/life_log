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

## UI / Design System

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U1 | Medium | fixed | `AppSheetScaffold` | Keyboard inset changes jump without transition. | Fixed: scroll content uses tokenized animated padding; header/grabber remain stable. |
| U2 | Low | open | `AddLogSheet` | Cross-field focus switch can flicker the bottom bar. | Focus state is coalesced so only final focus state rebuilds. |
| U3 | Low | fixed | `AppSkeleton` | Skeleton color uses raw `Colors.white10`. | Fixed: color comes from theme color scheme. |
| U4 | Low | open | `AppEmptyState` | 74x74 icon container is hard-coded. | Size comes from design token. |
| U5 | Low | open | `AppMetricTile` | 38x38 icon container is hard-coded. | Size comes from design token. |
| U6 | Low | fixed | `AppLoading` | Loading label gap uses raw `12`. | Fixed: uses `AppSpacing.md`. |
| U7 | Low | fixed | `AppSafeBottomBar` | Shadow blur uses raw `24`. | Fixed: uses elevation/shadow token. |
| U8 | Low | fixed | `AppMotion` | Uses both `Easing.*` and raw `Curves.easeInOutCubic`. | Fixed: motion constants use tokenized `Easing.*`. |
| U9 | Low | fixed | `AppTheme` | Text styles force `letterSpacing: 0`; dialog theme is missing. | Fixed: app-theme text styles no longer force letter spacing and dialog theme exists. |
| U10 | Low | open | `DayCell` | Holiday badge can overlap double-digit dates. | Badge/content layout no longer overlaps. |
| U11 | Low | open | `StatisticsView` | Overtime text may become too small in calendar cells. | Calendar cell text uses stable sizing, not whole-cell `FittedBox`. |

## Tooling / Validation

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| T1 | Medium | fixed | Flutter/Dart CLI | `flutter`/`dart` commands timed out inside the sandbox because the CLI could not write normal analytics/tool-state files under `C:\Users\WZH\AppData\Roaming`. | Fixed: reran with approved Flutter/Dart permissions; `flutter --version`, `dart --version`, `flutter analyze`, and `flutter test` complete successfully. |
| T2 | Low | fixed | GitHub Actions | GitHub Actions warned that Node.js 20 action runtime is deprecated and will default to Node.js 24 on 2026-06-02. | Fixed: opted both APK workflows into Node.js 24 action runtime with `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`. |

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
