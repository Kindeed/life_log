# LifeLog BUG Tracker

**Last updated**: 2026-06-09
**Status values**: `open`, `in_progress`, `fixed`, `deferred`, `invalidated`

This is the active defect ledger. `REVIEW_REPORT.md` is historical context only. Photo sync findings from older reports are superseded by `AGENTS.md`: photos remain local-only and must not enter Supabase sync.

## Full Tracker Re-audit (2026-06-08)

- Scope: started a fresh sequential audit from the first tracker defect, using the current working tree as authoritative evidence.
- Checked this pass: D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19, D20, D21, D22, D23, D24, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14, U15, U16, U17, U18, U19, U20, U21, U22, U23, U24, U25, U26, U27, U28, U29, U30, U31, U32, U33, U34, U35, U36, U37, U38, U39, U40, U41, U42, U43, U44, U45, U46, U47, U48, U49, U50, U51, U52, U53, U54, U55, U56, U57, U58, U59, U60, U61, U62, U63, U64, U65, U66, U67, U68, U69, U70, U71, U72, U73, U74, U75, U76, U77, U78, U79, U80, U81, U82, U83, U84, U85, U86, U87, U88, U89, U90, U91.
- No same-problem recurrence found in this pass so far: D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19, D20, D21, D22, D23, D24, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14, U15, U16, U17, U18, U19, U20, U21, U22, U23, U24, U25, U26, U27, U28, U29, U30, U31, U32, U33, U34, U35, U36, U37, U38, U39, U40, U41, U42, U43, U44, U45, U46, U47, U48, U49, U50, U51, U52, U53, U54, U55, U56, U57, U58, U59, U60, U61, U62, U63, U64, U65, U66, U67, U68, U69, U70, U71, U72, U73, U74, U75, U76, U77, U78, U79, U80, U81, U82, U83, U84, U85, U86, U87, U88, U89, U90, U91.
- Newly discovered and fixed: D25. `ProjectBusinessChanges` no longer treats audit timestamps as business fields.
- Newly discovered and fixed: U91. Month grouping helpers now normalize the target month before comparing local date-only fields.
- Newly discovered and fixed: U92. The telemetry calculator entry now separates formula-catalog coverage from runnable calculator cards.
- Newly discovered and fixed: U93. Telemetry template save/rename dialogs no longer close through global Get routing or global snackbar overlays.
- Newly discovered and fixed: U94. The telemetry formula knowledge base is now exposed as a categorized local formula library with rendered formulas and parameter explanations.
- Continued checked after U91: F1, F2, F3, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, C1, C2, P25, P26, P27, P28, P29, P30, P31, P32, P33, P34, P35, P36, P37, P38, P1-1, P1-2, P1-3, P1-4, P1-5, P1-6, P1-7, P2-1, P2-2, P2-3, P2-4, P2-5, P3-1, P3-2, P3-3, P3-4, H1, H2.
- No same-problem recurrence found in continued checks: F1, F2, F3, T1, T2, T3, T4, T5, T6, T7, T8, T10, T11, T12, C1, C2, P25, P26, P27, P28, P29, P30, P31, P32, P33, P34, P35, P36, P37, P38, P1-1, P1-2, P1-3, P1-4, P1-5, P1-6, P2-1, P2-2, P2-3, P2-4, P3-1, P3-2, P3-3, H1, H2.
- Still deferred / externally pending: T9 remains blocked by the Isar generator analyzer constraint; T14 remains a WebAssembly-specific dependency compatibility warning; P1-7, P2-5, and P3-4 remain real-device smoke validation tasks.
- Newly fixed: T13. Web target startup now uses a Web-only entry point that does not import the Isar-backed local database startup chain, and `flutter build web --no-pub` succeeds.
- Newly discovered and recorded: T14. Flutter's WebAssembly dry run still reports dependency incompatibilities even though the default Web build succeeds.

## Repository Hygiene Audit (2026-05-28)

- Fixed in this cleanup pass: C2. A hidden AI-tool skill document under `.agent/` was tracked and present on GitHub even though repository guidance should live in `AGENTS.md`, `CLAUDE.md`, and project documentation.
- Hardened ignore rules for local AI attachments and APK/debug build artifact folders so `.codex-remote-attachments/` and `build_artifacts/` stay local.
- GitHub file-tree check found no tracked APK/AAB/IPA/ZIP artifacts, signing keys, `local.properties`, `.claude/`, `.codex-remote-attachments/`, or `build_artifacts/` on `origin/main`.

## Regression Audit (2026-05-27)

- Scope: checked every tracker entry against the current working tree by static code inspection, then reran `flutter analyze --no-fatal-infos`, `flutter test`, and `git diff --check`.
- Reopened: U20. `SubscriptionView` again exposes duplicate add-entry actions in the empty state (`AppBar` add button, FAB, and `AppEmptyState` action all point to the same flow).
- Newly closed from this audit: D10. The baseline `20260429_expense_evidence.sql` migration now includes `updated_at timestamptz not null default now()`.
- Still open / still reproducible in current code: D13, D18, D21, D22, T3, T4, T5.
- Still pending external validation: P1-7, P2-5, P3-4. Local analyze/test can pass, but the tracked real-device smoke checks are not represented by local CLI validation.
- No same-problem recurrence found in this pass: D1, D2, D3, D4, D5, D6, D7, D8, D9, D11, D12, D14, D15, D16, D17, D19, D20, D23, D24, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14, U15, U16, U17, U18, U19, U21, U22, U23, U24, U25, U26, U27, U28, U29, U30, U31, U32, U33, U34, U35, U36, U37, U38, U39, U40, U41, U42, U43, U44, U45, U46, U47, U48, U49, T1, T2, T6, T7, T8, C1, P25, P26, P27, P28, P29, P30, P31, P32, P33, P34, P35, P36, P37, P38, P1-1, P1-2, P1-3, P1-4, P1-5, P1-6, P2-1, P2-2, P2-3, P2-4, P3-1, P3-2, P3-3, H1, H2.

## Remediation Audit (2026-05-27)

- Fixed in this remediation pass: U20, D13, D18, D21, D22, T3, T4, T5.
- Newly discovered and recorded: T9. `dart run build_runner build --delete-conflicting-outputs` succeeds but warns that the current `analyzer` version may not fully support the current SDK language version. Follow-up investigation confirmed this is blocked by `isar_generator 3.1.0+1` constraining `analyzer` to `<6.0.0`; fixing it requires an Isar/generator migration rather than a lockfile refresh.
- Newly discovered and fixed in the project UI pass: U50, U51, U52, U53.
- Re-audit result after fixes: no recurrence found for U20, D13, D18, D21, D22, T3, T4, or T5 by static inspection; local CLI validation is listed at the end of this document.
- Still pending external validation: P1-7, P2-5, P3-4. These remain real-device smoke tasks and were not marked fixed by local CLI checks alone.

## Data / Sync

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D1 | High | fixed | `Project` sync | `Project` has cloud fields and remote schema, but client pull/push is incomplete. | Fixed: project pull/push/delete exists, and sync is limited to cloud-eligible projects or projects referenced by synced expense/evidence records. |
| D2 | High | fixed | owner claim | `claimUnownedRecordsForCurrentUser()` omits projects. | Fixed: unowned projects are claimed locally; only sync-eligible projects become dirty. |
| D3 | Medium | fixed | dirty marking | Save paths rely on UI to set `isDirty`. | Fixed: DB save paths mark dirty from business-field changes even if UI forgets. |
| D4 | Medium | fixed | backup | Backup exports Isar DB only, not photo/evidence files. | Fixed: UI and share text explicitly say database-only and warn that media files are not included. |
| D5 | Low | fixed | diagnostics | Diagnostic export includes the full Supabase URL. | Fixed: diagnostic/log exports mask the Supabase URL. |
| D6 | Medium | fixed | record audit timestamps | `WorkLog`, `ExpenseRecord`, and `ExpenseEvidence` store business dates but do not have explicit local `createdAt` / `updatedAt` audit timestamps. | Fixed: added local schema-backed audit timestamps, backfilled existing rows on DB init, stamped local save/delete and remote-pull writes, regenerated Isar code, and kept photos out of cloud-sync fields/protocols. |
| D25 | Medium | fixed | Project dirty marking | `ProjectBusinessChanges.hasBusinessChangesComparedTo()` compared `createdAt` and `updatedAt`, while WorkLog/Evidence/ExpenseRecord business-change helpers ignore audit timestamps. A project whose only difference was audit time could be treated as a business change and kept dirty unnecessarily. | Fixed: removed audit timestamps from `ProjectBusinessChanges`, added regression coverage showing timestamp-only differences are not business changes while `status` changes still are, and reran business-change tests. |

## UI / Design System

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U1 | Medium | fixed | `AppSheetScaffold` | Keyboard inset changes jump without transition. | Fixed: scroll content uses tokenized animated padding; header/grabber remain stable. |
| U2 | Low | fixed | `AddLogSheet` | Cross-field focus switch can flicker the bottom bar. | Fixed: the sheet keeps its bottom bar visible and relies on `AppSheetScaffold` animated keyboard padding, so focus switches no longer toggle the bottom bar. |
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
| U20 | Medium | fixed | `SubscriptionView` | Empty state and FAB both expose "添加支出", creating duplicate entry points. Regression 2026-05-27: current empty state also kept an AppBar add button, so the same add flow could appear in three places. | Fixed: empty fixed-cost state keeps a single FAB add action and no empty-state/AppBar duplicate action. |
| U21 | Medium | fixed | `CaptureDialog` | New-photo flow defaults to `DefaultProject`, which hides the create-project path. | Fixed: the project field starts blank and prompts the user to choose or create a project. |
| U22 | Medium | fixed | `CaptureDialog` | Function-scoped text controllers are never disposed. | Fixed: capture dialog now uses a stateful sheet and disposes its controllers with the sheet lifecycle. |
| U23 | High | fixed | `PhotoRepository` | Saved photo `fileName` can diverge from the actual archived filename after collision handling or rename. | Fixed: `fileName` now mirrors the basename of the real stored path. |
| U24 | High | fixed | `ProfileController` / `LoginView` | Logout leaves the user on the profile page, and registration lacks password confirmation. | Fixed: logout now redirects to `/login`, and registration includes a confirm-password field with a mismatch check. |
| U25 | Medium | fixed | `TabsView` | The center add entry was a generic icon-only button, so work/finance/project creation paths felt hidden and page switching felt abrupt. | Fixed: the generic center add entry was removed; main pages expose clear contextual FAB actions, and page transitions use `PageController.animateToPage()` with `AppMotion` tokens. |
| U26 | Medium | fixed | `CalendarHeader` / `StatisticsView` | 真机日志出现 `RenderFlex overflowed`，月份标题行和统计头部右侧文案在窄屏下会横向溢出。 | Fixed: header rows now use flexible/ellipsis layout and reduced padding so the content can shrink cleanly on narrow devices. |
| U27 | High | fixed | `DayCell` | 真机日志出现 Flutter assertion: `decoration != null || clipBehavior == Clip.none`，普通日期单元格在无 decoration 时仍设置了裁剪。 | Fixed: day cells always provide a default rounded decoration before applying `Clip.antiAlias`. |
| U28 | Medium | fixed | `WorkLogView` layout / semantics | 真机 debug 日志出现 `RenderViewport does not support returning intrinsic dimensions`，随后触发 `!semantics.parentDataDirty`。根因是工时详情区在 `SliverFillRemaining(hasScrollBody: false)` 内嵌套 `ListView`，导致 Flutter 对 viewport 做 intrinsic height 测量。 | Fixed: 工时详情区改为普通 `Padding + DayLogList` 非 viewport 布局；重新安装 debug APK 后启动日志未再出现 `RenderViewport`、`semantics.parentDataDirty`、`RenderFlex overflowed` 或崩溃关键字。 |
| U29 | Medium | fixed | main tabs / work / finance / project | UI 中同时存在多个添加入口，且工作页空状态、财务页和项目页各自保留旧按钮，导致入口不统一、文案不一致、按钮时有时无。 | Fixed: each main page now exposes one contextual primary FAB and empty states avoid duplicate action buttons. |
| U30 | Medium | fixed | date display / date-only fields | `DateTime` 被当成时间戳直接格式化，导致日历、凭证、订阅和项目列表里的日期在真机上出现偏一天或偏时分的问题。 | Fixed: added local date normalization helpers and normalized work log, subscription, evidence, expense, and display formatting paths to `toLocal()` / `dateOnlyLocal()`. |
| U31 | Medium | fixed | `ProjectGalleryView` multi-select | 项目图片进入多选后只有“全选/全不选/取消”，没有持续可见的后续操作栏，用户容易误以为功能没完成。 | Fixed: multi-select now always shows a bottom action bar with delete/export actions, while selection cancel remains visible in the AppBar. |
| U32 | Medium | fixed | evidence capture/import | 项目里的“凭证”入口只剩文字手工录入，拍照/相册导入链路没有从项目页直接暴露，容易被误判为功能未实现。 | Fixed: project evidence actions now expose capture, import, and manual entry; the editor already stores local files for attached evidence. |
| U33 | Medium | fixed | finance scope | 财务页同时承载固定支出和项目支出，和项目页里的项目支出入口重复。 | Fixed: finance page now only manages fixed subscriptions; project expenses remain in the project area. |
| U34 | High | fixed | work log calendar / statistics | 同一天不应同时存在多个工时状态，但当前保存和展示仍允许同日出现多条记录，并把它们当成不同状态处理。 | Fixed: same-day work logs now resolve to one final status per day; add/edit opens the existing day record when present, duplicate same-day saves are normalized away, and day cells/statistics render only the canonical state. |
| U35 | Medium | fixed | project empty state | 项目模块为空时直接引导添加照片/凭证/支出，没有先建立第一个项目，项目作为容器的工作流不清晰。 | Fixed: empty project state now prompts creating the first project, and existing project/photo/evidence/expense data still renders project cards instead of getting blocked by the empty prompt. |
| U36 | Medium | fixed | evidence editor attachments | 凭证编辑页只能显示已有附件或从入口带入附件，表单内没有拍摄/导入/更换发票和付款截图的动作，用户会认为不能保存凭证文件。 | Fixed: evidence editor now exposes camera, gallery, and file-import attachment actions, and saves the selected local attachment path and extension with the record. |
| U37 | Medium | fixed | date grouping / due-date display | 部分按月统计和到期判断仍在直接读原始 `DateTime` 的年月日，容易把本地/UTC 转换后的记录再算偏一天。 | Fixed: normalized the remaining expense, evidence, subscription, stats, and today-view date grouping/display paths to local dates. |
| U38 | Medium | fixed | project deletion | 创建项目后项目页没有明确删除入口，用户无法删除空项目或不再需要的项目。 | Fixed: project detail now exposes a visible destructive delete action, confirms impact, removes the project and its linked local records, and does not leave orphan project cards behind. |
| U39 | Medium | fixed | `DayCell` alignment | 日历日期数字和状态文本没有相对整个日期格居中，尤其是带 `+2h...` 状态时视觉偏移明显。 | Fixed: day-cell content now fills the whole cell before centering text, so date and status labels align to the cell center. |
| U40 | High | fixed | work log duplicate days | 旧数据中同一天可同时保留加班、出差等多条状态记录，显示层局部归并后仍可能在详情/编辑路径暴露冲突状态。 | Fixed: work-log loading now normalizes existing same-day duplicates through the repository, keeps the latest canonical record, and deletes duplicate records. |
| U42 | High | fixed | work log save | 工时保存会等待云端推送且没有保存中状态，网络慢或云同步失败时用户需要反复点击保存才看到结果。 | Fixed: work-log save now returns after local Isar persistence and duplicate cleanup, pushes cloud sync in the background, and disables the save button with loading while the local save is in flight. |
| U43 | High | fixed | work log startup refresh | 冷启动进入工时页时，日历没有显式订阅 `dataVersion`，异步记录加载完成后可能不重建，必须点一下页面才显示已有记录。 | Fixed: the calendar now observes `dataVersion`, and the detail area shows an initial loading state instead of a false empty state while logs are loading. |
| U44 | Medium | fixed | project creation | 创建第一个项目后，项目主页缺少持续可见的新建项目入口，只能依赖深层动作表。 | Fixed: project overview keeps a persistent right-bottom create-project FAB and the empty state points to the same creation flow. |
| U45 | Medium | fixed | project photo export | 项目图片多选底部栏在窄屏会把“选择了 N 张”挤成竖排，导致导出按钮看起来错位或不可用。 | Fixed: multi-select uses a stable stacked bottom bar with one-line selection text and equal-width delete/export actions. |
| U46 | High | fixed | work log startup refresh | 冷启动进入工时页后，已有工时记录仍可能不显示，必须点击页面或切换状态才刷新，说明日历单元格和详情区仍存在响应式订阅缺口。 | Fixed: day cells and the selected-day detail area now explicitly observe the work-log refresh version, so async startup loads repaint without user interaction. |
| U47 | Medium | fixed | work log calendar default | 工时页默认打开为周视图，不符合当前希望“打开默认是月视图”的产品行为。 | Fixed: the work-log controller now initializes the calendar format to month while preserving the existing month/week toggle. |
| U48 | Medium | fixed | main tabs / Material 3 UI | 底部导航实际只有四个页面，但中间快捷添加入口让主导航看起来像五栏；添加入口和页面主任务也不符合当前 Material 3 方向。 | Fixed: replaced the custom Apple-style tab bar with Material 3 `NavigationBar` / wide-screen `NavigationRail`, moved primary add actions into work/finance/project pages, and added dynamic color support in appearance settings. |
| U49 | High | fixed | startup / dynamic color | `MyApp` 在根级 `Obx` 中返回 `DynamicColorBuilder`，但实际读取 `dynamicColorEnabled` 发生在嵌套 builder 中，导致启动时 GetX 报 improper use 并红屏。 | Fixed: removed the root `Obx`, rebuilt app theme through a targeted `GetBuilder<ThemeController>`, and kept theme-mode switching on `Get.changeThemeMode()`. |
| U50 | Medium | fixed | work / finance / project add entry | 工时、财务和项目模块的新增入口位置不一致，财务页使用右上角添加，项目页同时存在顶部和右下角创建入口。 | Fixed: finance and project creation now use right-bottom FABs as their primary add entry; AppBar keeps only non-primary tools such as refresh. |
| U51 | Medium | fixed | `ProjectGalleryView` contextual add | 项目详情页在照片、凭证、支出栏目内点击添加后仍弹出总类型菜单，和当前栏目语义不一致。 | Fixed: project-detail FAB follows the active tab: photos open photo actions, evidence opens evidence actions, and expense opens project-expense editing with the project prefilled. |
| U52 | Low | fixed | `CreateProjectSheet` copy | 创建第一个项目后再次创建时，项目名称输入提示仍显示“输入第一个项目名称”。 | Fixed: the project-name hint now uses the neutral copy “输入项目名称”. |
| U53 | Medium | fixed | `ProjectGalleryView` multi-select | 照片多选底部三按钮在窄屏下容易挤压错位，“完成”含义不清，安卓返回/侧滑会返回上级而不是退出选择模式。 | Fixed: the bottom bar keeps only delete/export actions, top cancel remains the explicit exit, and system back/edge-back exits multi-select before leaving the page. |
| U54 | Medium | fixed | `WorkLogView` dark calendar | 暗色模式下工时日历仅依赖小号状态文字颜色区分工作、出差、请假和休息，选中日、今天或跨月日期容易让状态不明显。 | Fixed: work-log day cells now render logged statuses with a compact high-contrast fill and border while preserving selected/today/outside-month semantics. |
| U55 | Medium | fixed | `AddLogSheet` save action | 工时记录表单在手动输入加班时长、出差地点/金额、请假原因或备注时，键盘弹起会隐藏底部保存栏，让用户以为没有保存按钮。 | Fixed: work-log add/edit sheets keep the save bottom bar visible above the keyboard without changing the default sheet behavior used by other modules. |
| U56 | High | fixed | project evidence attachments | 项目详情页的凭证列表点击后直接进入编辑，PDF/文件凭证没有原件预览、打开、导出或本机文件缺失状态，导入后容易被误判为文件丢失。 | Fixed: project and global evidence entries share a detail sheet with image/PDF/file preview, open/export/edit actions, and missing-file restore messaging. |
| U57 | Medium | fixed | evidence local parsing | 凭证导入后完全依赖人工填写金额、日期和商家，没有本地发票内容解析入口；PDF 发票尤其容易保存成“看不见内容的文件”。 | Fixed: image/PDF evidence can run local OCR parsing from the editor or detail sheet, filling empty amount/date/merchant/note fields as best-effort suggestions without cloud AI; parsing now also records consumption content, route/time, buyer name, tax ID, and service item summaries in notes. |
| U58 | Medium | fixed | page FAB hero tags | 真机冒烟测试进入项目凭证页后日志出现 `multiple heroes share the same tag <default FloatingActionButton tag>`，多个保活页面的 FAB 使用默认 heroTag。 | Fixed: page-level FABs now use unique hero tags and reusable action-pill FABs default to no hero tag, preventing cross-page Hero collisions. |
| U59 | Low | fixed | evidence detail actions | 凭证详情页的打开、导出、解析、编辑四个按钮横向 Wrap 排列，在窄屏上不够稳定，也不符合四宫格操作区预期。 | Fixed: evidence detail actions now render as a stable 2x2 button grid with consistent heights and centered icon/text labels. |
| U60 | High | fixed | rail ticket parsing / evidence list | 铁路电子客票解析会把车站英文拼音当目的地，例如“广州 → Guangzhou”，并把购买方公司名作为列表主标题，导致项目凭证列表冗长且误导；重新解析还会追加旧的自动解析备注而不是替换。 | Fixed: rail route parsing now uses Chinese station names around the train number, including same-line layouts such as `广州站 G5133 阳江北站`, and travel date/time instead of invoice date; evidence lists prioritize consumption summary as the title, keep buyer/company details out of the compact title/subtitle, and avoid repeating the same summary in the subtitle; reparsing replaces generated invoice summary lines instead of accumulating stale OCR output. |
| U61 | Medium | fixed | evidence list date semantics | 项目凭证列表第一行把消费日期拼进标题，第二行又显示导入/开票日期，火车票、餐饮、交通等凭证看起来像日期错乱。 | Fixed: compact evidence rows split parsed consumption content into title and business date/time; first line shows only the route/service/content, second line shows parsed travel/consumption date plus category, and the imported/evidence date is no longer used as a list fallback. |
| U62 | Medium | fixed | `TelemetryCalcDetailView` layout | 遥测计算详情页结果区使用大尺寸双列指标卡，顶部说明、结果和输入参数分布割裂，窄屏下可读性和专业感不足。 | Fixed: details now use a compact calculation workbench with one primary result banner, a dense result table, and the input form in the same card so calculation context stays continuous. |
| U63 | High | fixed | `TelemetryCalcDetailView` unit selector | 数值输入框 suffix 中的 `DropdownButtonHideUnderline` / `DropdownButton` can trigger Flutter `_dependents.isEmpty` framework assertion when the unit selector is opened or the screen is deactivated. | Fixed: unit selection now uses a compact `PopupMenuButton` control outside the text-field inherited underline path, and a widget regression test opens the unit selector. |
| U64 | High | fixed | `TelemetryCalcDetailView` / `rate_bandwidth` | `码率与带宽` 页面仍表现为旧式上下割裂布局，公式依据在结果和输入之后，用户先看到结果卡片但看不到计算关系。 | Fixed: rate/bandwidth now opens directly into the compact result/input workbench, while formulas remain available from the AppBar `公式与依据` bottom sheet with styled selectable formula blocks. |
| U65 | High | fixed | `rate_bandwidth` calculation | `帧/协议开销` 默认 5% 在码率公式中按 `5` 参与 `1 - overhead`，导致编码后码率、符号率、占用带宽等结果为负数。 | Fixed: overhead is converted to `ratio` before calculation, and tests assert the default rate/bandwidth outputs stay positive and correctly scaled. |
| U66 | High | fixed | `rate_bandwidth` output units | `符号率` 输出定义把公式内部 Hz 结果标成 `Msps` 基准单位，导致显示值被放大并出现 `e+5 Msps` 级别的错误读数。 | Fixed: symbol-rate output now uses `Hz` as the internal unit and converts to `Msps` only for display. |
| U67 | Medium | fixed | `TelemetryCalcDetailView` input consistency | 其他遥测计算详情页仍可能混用独立选择卡片、普通文本框和数值 tile，导致公式、结果、输入虽在同页但视觉语言不统一。 | Fixed: number, select, and expression inputs now share the same compact input-tile surface, and widget tests iterate all calculator detail pages for result/input workbench consistency and formula-sheet access. |
| U68 | Medium | fixed | `TelemetryCalcDetailView` visual design | 真机反馈显示遥测计算详情页虽然已把公式、计算结果和输入参数放进同一 workbench，但视觉上仍像分离区块；长标题在 AppBar 和卡片标题中也显得臃肿，不够专业协调。 | Fixed: AppBar and detail headers now use short task-oriented titles such as `带宽计算`, and the old stacked result/input sections have been replaced by a linked workbench with `输出` and `输入` panes while formulas remain as supporting context. |
| U69 | Low | fixed | `TelemetryCalcDetailView` formula block | 真机验证发现窄屏详情页的公式表达式使用横向滚动，默认视图右侧像被硬截断，削弱了 `公式与依据` 到输出/输入 workbench 的连续感。 | Fixed: formula expressions now wrap within the card on narrow screens, and the rate/bandwidth widget test rejects horizontal formula scrolling. |
| U70 | Medium | fixed | `TelemetryCalcDetailView` reference alignment | 参考稿 B 强调输入/输出工作台先行、公式作为轻量依据，但实装版仍把公式作为首屏大区块，导致真机效果和预览稿不一致。 | Fixed: detail pages now keep the result/input workbench as the main content, keep tablet-width layouts as input-left/output-right, and move formula references into the AppBar `公式与依据` bottom sheet instead of a trailing main-scroll panel. |
| U71 | Medium | fixed | `TelemetryCalcDetailView` mobile workbench | 真机验证发现移动端若把完整输入表单放在输出前，输出摘要会被挤出首屏，底部“恢复默认 / 保存模板”按钮还会出现轻微纵向 overflow。 | Fixed: mobile workbench now puts the compact output pane before input, keeps formula references out of the main scroll behind `公式与依据`, and moves reset/save template actions into the AppBar so primary actions do not overflow the workbench. |
| U72 | Medium | fixed | `TelemetryCalcDetailView` reference alignment | 用户确认现版仍未满足“B：左输入右输出工作台，短标题 + 副标题，输入和结果空间上绑定，并吸收 A 的主结果强调”，因为移动端仍是上下堆叠而不是空间绑定。 | Fixed: the detail workbench now uses short titles, an emphasized primary-result panel, compact editable input rows, tablet-width input-left/output-right layout, and mobile result-first stacking per the later redesign review. |
| U73 | Medium | fixed | `TelemetryCalcDetailView` calculator-specific balance | 新增计算模块若输入参数明显多于输出项，当前固定左输入右输出双栏会显得左侧过重、右侧过空，影响详情页协调感和专业感。 | Fixed: output panes now use stronger surface treatment and include a compact `工程判断` insight block derived from existing calculation outputs, while preserving local-only calculation flow and adaptive result/input layout. |
| U74 | Medium | fixed | `TelemetryCalcDetailView` output insight readability | 真机验证链路预算详情页发现右侧 `工程判断` 卡片在半宽输出区内把“链路余量满足要求”和说明文字截成省略号，新增判断区虽然增强了视觉重量但可读性不足。 | Fixed: input/output pane subtitles and judgement messages were shortened, judgement titles can wrap to two lines, and widget coverage asserts the narrow-pane judgement title plus concise status copy. |
| U75 | Low | fixed | `TelemetryCalcDetailView` compact input labels | 真机验证链路预算详情页发现左侧首个参数标签“发射机输出功率”在半宽输入卡片内被截成“发射机输出...”，长参数名需要依赖提示图标才能确认。 | Fixed: compact input labels can wrap to two lines, and the narrow-pane widget test asserts the representative long input label is not forced to one line. |
| U76 | Medium | fixed | `TelemetryCalcDetailView` primary output value | 真机验证自定义公式详情页发现单输出主结果 `10.000000` 在半宽输出卡片内显示成 `10.00...`，数值本身不完整。 | Fixed: primary output values now scale down inside their card before truncating, preserving calculation precision while fitting long values in the narrow output pane. |
| U77 | Low | fixed | `TelemetryCalcDetailView` fallback insight copy | 真机验证自定义公式详情页发现兜底 `工程判断` 说明在半宽输出区内仍截断成“可继续...”，单输出页面的结论区显得未收口。 | Fixed: fallback judgement copy is now the concise `结果已更新，可继续调参。`, and widget coverage asserts the exact short copy is rendered. |
| U78 | High | fixed | `TelemetryCalcDetailView` Doppler ppm output | 真机验证频率校核详情页发现 `1 ppm` 被按 `1` 倍频率误差计算，输出出现 `-2.200e+6 kHz` 级保护间隔余量，并触发主结果说明和工程判断文案截断。 | Fixed: Doppler oscillator tolerance now converts ppm to ratio before applying carrier frequency; the output pane uses shorter Doppler summaries and guard-band judgement copy, with engine/widget tests covering the corrected default values. |
| D7 | High | fixed | sync parsing | Remote row parsing and push response handling used `DateTime.parse` / direct casts and could abort a sync path on malformed or null fields. | Fixed: pull rows, push responses, server-time reads, and stored cursors now use safe numeric/string/date parsing with fallbacks or controlled failure for invalid remote IDs. |
| D8 | Medium | fixed | sync trigger dedupe | `syncAll` skipped a fresh manual sync for 2 seconds after the previous one finished. | Fixed: only an in-flight sync is reused now. |
| U14 | Medium | fixed | `ExpenseRecordEditView` | One-time expense add/edit UI is visually inconsistent with the current finance design system. | Fixed: reworked to a clearer amount-first card, category chips, tokenized surfaces, and stable bottom actions. |
| U15 | Medium | fixed | `PhotoView` / `ProjectGalleryView` / `PhotoPreviewView` | Empty project media flow hides credential/expense creation, project-first guidance is unclear, and photo preview has no remark editing path. | Fixed: empty and project actions expose photos, credentials, and expenses; preview supports remark editing. |
| U16 | Low | fixed | `PhotoPreviewView` | Delete action can pop navigation twice because both preview and controller call `Get.back()`. | Fixed: controller owns the post-delete pop. |
| U17 | Medium | fixed | `PhotoPreviewView` | 真机日志出现 `A TextEditingController was used after being disposed`，备注编辑弹窗把控制器交给 `whenComplete`，关闭/重建时存在生命周期竞态。 | Fixed: 备注编辑改为独立 stateful sheet，自行管理 `TextEditingController` 生命周期。 |

## Calculation / Formula Engine

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| F1 | High | fixed | `TelemetryCalculatorEngine.validate` / system calculators | 数值输入的 `min` / `max` 校验直接比较用户输入的原始数值，没有按当前单位换算到规范单位；新增电源、热控等计算器允许 `percent` / `ratio` 双单位时，选择 `ratio` 后输入 `30` 仍可通过 `max: 100`，随后按 30 倍效率参与计算。 | Fixed: number validation converts values to each input's default unit before checking bounds; regression test `validates ratio inputs after unit conversion` passes. |
| F2 | High | fixed | `spacecraft_thermal` / `UnitCatalog` power units | `radiator_margin` 是可为负的 W 余量，但 `context.output` 会通过全局 `W` 单位换算路径；当前 `W.toBase` 使用 `log(value)` 支持 dBW 换算，负余量会变成 `NaN`，导致散热不足时输出值不可读。 | Fixed: same-unit conversions return the original value, preserving finite negative linear W margins; regression test `keeps negative thermal power margins finite` passes. |
| F3 | Medium | fixed | `spacecraft_thermal` radiator sizing | 热控计算允许 `radiator_temp <= space_temp`，`radiatorDenominator` 可为 0 或负数，进而让 `radiator_area_required` 变为 `Infinity` 或物理上无效的负面积；现有测试只覆盖默认正分母。 | Fixed: thermal calculation rejects non-radiating temperature boundaries before calculating dependent area/margin outputs; regression test `rejects non-radiating thermal temperature boundaries` passes. |

## Tooling / Validation

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| T1 | Medium | fixed | Flutter/Dart CLI | `flutter`/`dart` commands timed out inside the sandbox because the CLI could not write normal analytics/tool-state files under `C:\Users\WZH\AppData\Roaming`. | Fixed: reran with approved Flutter/Dart permissions; `flutter --version`, `dart --version`, `flutter analyze`, and `flutter test` complete successfully. |
| T2 | Low | fixed | GitHub Actions | GitHub Actions warned that Node.js 20 action runtime is deprecated and will default to Node.js 24 on 2026-06-02. | Fixed: opted both APK workflows into Node.js 24 action runtime with `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`. |
| T6 | High | fixed | Release content | `v1.4.2` / `v1.4.3` release builds did not include the full UI and business-content changes from the `codex/actions-node24-compat` test APK source commit `e115424`, even though the version number advanced. | Fixed: restored `e115424` UI/business-content changes onto `main`, kept the newer release metadata, revalidated, and prepared a corrected release. |
| T7 | Low | fixed | Repository hygiene | A generated Gradle problems report was tracked, and repository guidance still described stale test, collection, and photo-sync behavior. | Fixed: removed the generated report from Git, ignored `android/build/`, and updated README/CLAUDE guidance to match current repo rules. |
| T8 | High | fixed | Release build | `v1.4.5` release workflow failed in `Build APK (split per ABI)` because Gradle could not resolve the Kotlin Android plugin marker `org.jetbrains.kotlin.android:org.jetbrains.kotlin.android.gradle.plugin:2.2.20`. | Fixed: Gradle plugin management now maps the Kotlin Android plugin directly to `org.jetbrains.kotlin:kotlin-gradle-plugin`, and the release is retried as `v1.4.6`. |

## Maintenance / Cleanup

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| C1 | Low | fixed | project cache | Regenerable Flutter project caches were present after prior local builds. | Fixed: ran `flutter clean`, restored dependency metadata with `flutter pub get`, verified the project, then removed test-regenerated `build` cache while keeping required `.dart_tool` metadata. |
| C2 | Low | fixed | repository docs | Hidden AI-tool guidance under `.agent/skills/flutter_architecture/SKILL.md` was tracked and uploaded to GitHub, duplicating and partially conflicting with the canonical `AGENTS.md` / `CLAUDE.md` guidance. | Fixed: removed the tracked `.agent/` document and ignored `.agent/`, `.codex-remote-attachments/`, and `build_artifacts/` as local-only workspace state. |

## Performance / Startup / Sync

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| P25 | High | fixed | startup / sync watchers | Startup and sync writes can trigger multiple controller watch callbacks, causing repeated full reloads across work logs, subscriptions, projects, evidence, expenses, and statistics. | Fixed: bootstrap sync reuses/skips duplicate same-user auth/startup triggers, and pull writes are batched per collection to reduce watch fan-out. |
| P26 | High | fixed | Sync pull transactions | `_pullAll()` applies each remote row through an independent Isar `writeTxn()`, so large pulls create excessive transaction overhead. | Fixed: pulled rows are applied per collection in batched local transactions while preserving conflict behavior. |
| P27 | Medium | fixed | Sync push queries | `_pushUnsyncedData()` fetches all syncable rows and filters `remoteId == null || isDirty || pendingDelete` in Dart. | Fixed: push loops query only pending rows from Isar before pushing. |
| P28 | Medium | fixed | Statistics month navigation | `previousMonth()`, `nextMonth()`, and `resetToCurrentMonth()` call `refreshStats()` even though cached data is sufficient for recalculation. | Fixed: month navigation recalculates from cached lists without querying all four data sources. |
| P29 | Medium | fixed | WorkLog duplicate normalization | `WorkLogController.loadData()` runs duplicate-day normalization on every reload, including watch-triggered reloads. | Fixed: duplicate normalization runs during startup initialization, not every watch reload. |
| P30 | Medium | fixed | WorkLog same-day lookup | `_sameDayLogs()` calls `getAllLogs()` and filters in Dart, causing full scans for day-level operations. | Fixed: same-day lookup queries the target day range directly. |
| P31 | Low | fixed | WorkLog calendar rebuild | `TableCalendar` is keyed by `selectedDay`, forcing a calendar subtree rebuild on every day selection. | Fixed: removed the selected-day key and kept selection driven by `selectedDayPredicate`. |
| P32 | Medium | fixed | tabs page lifecycle | `PageView` tab pages are plain children without explicit keep-alive, so heavier tab subtrees can be rebuilt when switching pages. | Fixed: each tab child is wrapped in a keep-alive page shell without changing visual layout. |
| P33 | Medium | fixed | Photo derived data | Photo project grouping and summary getters rebuild maps/lists and sort data every time they are accessed by reactive builders; the first cache pass still re-sorted each already date-sorted group and rebuilt grouping on search/sort changes. | Fixed: photo project grouping, summaries, filtering, and counts are cached; group order relies on the DB `createdAt desc` query contract, search only rebuilds filtered results, and sort only reorders summaries. |
| P34 | Medium | fixed | Evidence derived data | Evidence project grouping and summary getters rebuild maps/lists and sort data every time they are accessed by reactive builders; the first cache pass still re-sorted each already date-sorted group and rebuilt grouping on search/sort changes. | Fixed: evidence grouping, summaries, filtering, and totals are cached; group order relies on the DB `evidenceDate desc` query contract, search only rebuilds filtered results, and sort only reorders summaries. |
| P35 | Medium | fixed | Subscription derived data | Subscription visible list, cost totals, and due-soon list are recomputed by getters on every reactive rebuild. | Fixed: visible subscriptions, totals, due-soon list, and due-soon count are cached and invalidated only when subscription/filter/sort inputs change. |
| P36 | Medium | fixed | Subscription reorder dirty marking | `reorderSubscriptions()` writes and marks every subscription dirty even if only a subset of sort indexes changed. | Fixed: reorder writes only changed rows, marks only changed rows dirty, and pushes changed rows when cloud sync is available. |
| P37 | Medium | fixed | Statistics watch refresh | Statistics watch coalescing regressed to a shared full refresh, so editing one table re-queried work logs, subscriptions, evidence, and expense records. | Fixed: collection watches share one refresh gate but carry changed-source sets, so normal watch events re-query only the changed tables while full refresh still loads all sources. |
| P38 | Low | fixed | Statistics derived total | `selectedMonthTotalCost` was a computed getter that read subscription and expense observables inside the same `Obx`, causing redundant dependency reads for one displayed total. | Fixed: selected-month total cost is now an observable updated with subscription and expense-record stat recalculation. |

### P1 Performance Remediation Tasks

| Task | Status | Scope | Acceptance |
| --- | --- | --- | --- |
| P1-1 | fixed | Sync startup/auth dedupe | Same logged-in user does not run duplicate bootstrap syncs from auth and startup callbacks. |
| P1-2 | fixed | Sync pull batch transactions | Pull writes are applied per collection instead of one transaction per row. |
| P1-3 | fixed | Pending sync query pushdown | Push loops receive only pending rows from Isar queries. |
| P1-4 | fixed | Statistics cached month recalculation | Month navigation recalculates cached stats without DB refresh. |
| P1-5 | fixed | WorkLog load/query optimization | Normalization is startup-only and same-day lookup avoids full scans. |
| P1-6 | fixed | Calendar key removal | Selected-day changes no longer recreate the whole `TableCalendar`. |
| P1-7 | in_progress | Validation | `flutter analyze` and `flutter test` passed on 2026-05-14; real-device smoke checks are still pending. |

### P2 Performance Remediation Tasks

| Task | Status | Scope | Acceptance |
| --- | --- | --- | --- |
| P2-1 | fixed | Tab page keep-alive | Switching tabs preserves page subtrees through a keep-alive wrapper without visual changes. |
| P2-2 | fixed | Photo derived data cache | Project grouping is recomputed only after photo data changes; search only filters cached summaries and sort only reorders cached summaries. |
| P2-3 | fixed | Evidence derived data cache | Project grouping is recomputed only after evidence data changes; search only filters cached summaries and sort only reorders cached summaries. |
| P2-4 | fixed | Subscription derived data cache | Visible list and subscription totals are recomputed only after subscription/filter/sort input changes. |
| P2-5 | in_progress | Validation | `flutter analyze` and `flutter test` passed on 2026-05-14; real-device smoke checks are still pending. |

### P3 Performance Remediation Tasks

| Task | Status | Scope | Acceptance |
| --- | --- | --- | --- |
| P3-1 | fixed | Subscription reorder dirty scope | Reorder persists only rows whose sort index changed and does not dirty untouched rows. |
| P3-2 | fixed | Subscription reorder sync | Changed reorder rows are pushed immediately when cloud sync is registered. |
| P3-3 | fixed | Statistics watch coalescing | Work/subscription/evidence/expense watches share one refresh gate and coalesced source set while preserving targeted table refreshes. |
| P3-4 | in_progress | Validation | `flutter analyze` and `flutter test` passed on 2026-05-14; real-device smoke checks are still pending. |

## Invalidated Historical Findings

| ID | Status | Finding | Reason |
| --- | --- | --- | --- |
| H1 | invalidated | Add `syncId`/`remoteId`/`isDirty` etc. to `PhotoItem`. | Violates current hard constraint: photos are local-only. |
| H2 | invalidated | Add photo pull/push/merge paths to `SyncService`/`DbService`. | Violates current hard constraint: photos must not enter cloud sync. |

## Codex Review Findings (2026-05-11) - 未修改

### Data / Sync

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D9 | Critical | fixed | Sync - ExpenseRecord | `syncRemoteExpenseRecordToLocal` 中 `record.remoteId = remoteId` 为无条件赋值，而 WorkLog/Subscription/Evidence/Project 均使用条件赋值。不一致写法可能导致脏记录的 remoteId 被错误覆盖。 | Fixed: dirty ExpenseRecord remote pulls now use conditional `remoteId` assignment, matching the other sync entities. |
| D10 | Critical | fixed | Sync - Migration | 迁移 `20260429_expense_evidence.sql` 创建表时缺少 `updated_at` 列，该列在后续迁移 `20260507_remote_schema_repair.sql` 中才添加。两个迁移之间存在窗口期，依赖 `updated_at` 的同步逻辑可能失败。 | Fixed: `20260429_expense_evidence.sql` now defines `updated_at timestamptz not null default now()` in the original table creation. |
| D11 | Critical | invalidated | Sync - WorkLog | `saveLog` 在同日已有记录时，先通过 `_adoptCanonicalIdentity` 复制旧记录身份，再调用 `addLog`。若 `addLog` 抛出异常，旧记录身份已被覆盖但新数据未持久化，存在数据丢失风险。 | Invalidated: current code only mutates the incoming in-memory object before `addLog`; the existing Isar row is not overwritten before a successful write. Same-day mutation concurrency is tracked separately by D15. |
| D12 | High | fixed | Local owner claim - PhotoItem | `claimUnownedRecordsForCurrentUser()` 认领 WorkLog、Subscription、ExpenseEvidence、ExpenseRecord、Project，但未认领本地 `PhotoItem`。未登录时创建的照片在登录后可能因本地账号隔离而不可见。 | Fixed: local-only `PhotoItem.ownerUserId` is claimed during owner migration without adding photo cloud-sync fields or photo sync paths. |
| D13 | High | fixed | Sync - Backup | `restoreFromBackup` 关闭数据库后到重新初始化之间存在状态窗口，期间任何数据库访问都可能失败。`_rebuildDatabaseControllers` 仅删除控制器并依赖懒加载重建。 | Fixed: restore now blocks the UI with a non-dismissible restoring state, prevents concurrent restore calls, deletes DB-backed controllers before closing Isar, and refreshes the app after reinitialization. |
| D14 | High | fixed | Sync - Statistics | `refreshStats()` 使用 `Future.wait` 并发获取 4 个数据源，任一失败则 `catch` 仅记录错误，`_calculateAllStats()` 不执行，可能导致所有统计指标保持陈旧。 | Fixed: each statistics source loads with independent error handling, and full refresh recalculates from successful sources plus existing cached data. |
| D15 | High | fixed | Sync - WorkLog race | `_normalizeDuplicateDays` 与 `saveLog` 均会删除同日重复记录，但 `saveLog` 运行在归一化保护锁之外，可能出现竞态。 | Fixed: duplicate-day normalization and same-day save cleanup now share one serialized mutation gate. |
| D16 | High | fixed | Sync - Subscription | `reorderSubscriptions` 标记 `isDirty=true` 但不显式触发同步，用户关闭应用前排序变更可能丢失。 | Fixed: `SubscriptionRepository.reorderSubscriptions` pushes changed rows when cloud sync is registered. |
| D17 | Medium | fixed | Sync - Project auto-create | `syncRemoteExpenseRecordToLocal` 自动创建缺失 Project 时，设置 `isDirty = false` 且无 `syncId`，该项目不会同步到云端。 | Fixed: remote expense pull auto-created projects now receive a `syncId` and `isDirty = true`. |
| D18 | Medium | fixed | Performance - Index | 多个模型的 `deletedAt` 字段未建立索引，而查询会按 `deletedAt == null` 过滤软删除记录。记录数增长后查询性能可能下降。 | Fixed: added `@Index()` to `deletedAt` for WorkLog, Subscription, Project, ExpenseEvidence, and ExpenseRecord, then regenerated Isar code. |
| D19 | Medium | invalidated | Sync - ExpenseRecord txn | `syncRemoteExpenseRecordToLocal` 在 writeTxn 内嵌套项目创建写入，Isar 事务行为需验证，可能导致不可预期错误。 | Invalidated: current code creates the missing Project with `isar.projects.put()` inside the existing outer transaction; it does not open a nested `writeTxn`. |
| D20 | Medium | invalidated | Validation | `validateExpenseEvidence` 调用 `evidence.projectName.trim()` 时未判空，`projectName` 为 null 时会抛出异常。 | Invalidated: `ExpenseEvidence.projectName` is a non-null `late String` schema field, and the validator intentionally rejects empty strings while defaulting currency. |
| D21 | Medium | fixed | Sync dedup | `syncAll` 复用 `_activeSync` 防重复，但手动下拉刷新等场景无法强制启动新同步。 | Fixed: `syncAll` now supports `forceNew`, and the profile/manual sync path uses it with full refresh. |
| D22 | Medium | fixed | Sync - syncId consistency | `syncId` 分配在不同实体间条件不一致，维护成本高且容易引入行为差异。 | Fixed: sync ID assignment now goes through shared `ensureSyncId`, all syncable save/push paths use the same policy, and regression tests cover missing/blank/existing IDs. |
| D23 | Low | fixed | Sync - RefreshGate loop | `_RefreshGate._runLoop` 在 `_rerun` 被触发时可能长时间循环。 | Fixed: statistics refresh gate caps one drain cycle at 8 reruns and drops excess pending requests with a log entry. |

### UI / Design System

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U41 | Low | fixed | TodayView | `today_view.dart` 中 `TabsController.to.changePage(2)` 为硬编码 Tab 索引。若 Tab 顺序变更，将跳转至错误页面。 | Fixed: added `TabsDestination` constants and replaced hard-coded TodayView tab jumps with destination-based navigation; `TabsView` now observes external tab changes and syncs the `PageView`. |

### Tooling / Configuration

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| T3 | Medium | fixed | CI/CD | `build.yml` 中 Supabase Secret 验证发生在依赖安装、代码生成、分析之后。若 Secret 缺失，前面步骤会白白执行。 | Fixed: Supabase secret validation now runs as the first job step in both release and manual test APK workflows. |
| T4 | Low | fixed | Dependencies | `pubspec.yaml` 中 `get: ^4.6.6` 使用 `^` 范围，未来大版本变化可能带来构建风险。 | Fixed: `get` is pinned to the currently resolved `4.7.3`, matching `pubspec.lock`. |
| T5 | Medium | fixed | Auth | `AuthService` 无显式会话过期处理逻辑。Supabase 会话过期后，应用可能静默进入未登录状态，同步操作无声失败。 | Fixed: Auth and sync errors that look like expired/invalid sessions now clear local auth state, sign out, and redirect to `/login`. |
| T9 | Low | deferred | Tooling | `dart run build_runner build --delete-conflicting-outputs` succeeds but warns that `analyzer 5.13.0` may not fully support the current SDK language version. `flutter pub upgrade analyzer build_runner --dry-run` reports no dependency changes, and local `isar_generator 3.1.0+1` constrains `analyzer` to `>=4.6.0 <6.0.0`. | Deferred: remove the warning by migrating the Isar generator/tooling stack to a version compatible with the current Flutter/Dart SDK, then rerun build_runner without the analyzer language-version warning. |
| T10 | Low | fixed | GitHub APK naming | Release 和手动测试包上传的 APK 文件名沿用 Flutter 默认 `app-...apk`，下载后无法从文件名看出是 LifeLog 应用。 | Fixed: GitHub workflows rename APK assets to `lifelog-...apk` before uploading them. |
| T11 | Medium | fixed | GitHub release dependency drift | `v1.4.8` release 构建中 CI 的 `flutter pub get` 更新了锁定依赖，导致本地验证和 GitHub release 构建使用不同依赖集合，并在 Android release 构建阶段失败。 | Fixed: GitHub workflows now use the same pub / Flutter mirrors as the lockfile and run `flutter pub get --enforce-lockfile` so CI fails fast instead of silently changing dependencies. |
| T12 | Low | fixed | statistics tests | `StatisticsController` 缓存测试使用 2026-05 数据，但依赖控制器默认选中当前月份；进入 2026-06 后测试统计 6 月导致断言失败。 | Fixed: affected tests now set `selectedMonth` to 2026-05 before refresh, keeping the fixture deterministic. |
| T13 | Low | fixed | Flutter web preview | `flutter run -d web-server` is blocked by existing Isar generated `.g.dart` 64-bit integer literals that JavaScript cannot represent exactly, so browser-based UI verification cannot run until web build compatibility is addressed. | Fixed: `main.dart` now conditionally selects a Web-only entry point that does not import the Isar-backed local database startup chain; `flutter build web --no-pub` succeeds and renders a clear unsupported-platform page for Web. |
| T14 | Low | deferred | Flutter WebAssembly preview | After T13, the default Web build succeeds, but Flutter 3.38's wasm dry run still reports dependencies importing `dart:html` or `dart:ffi` (`device_info_plus`, `geolocator_web`, `get_storage`, `isar`, `win32`, `pdfx` interop warnings). This means a future wasm target is still not clean. | Deferred: either disable wasm dry-run for default JS web verification when wasm is not a target, or migrate/conditionalize the incompatible dependencies before enabling Flutter WebAssembly builds. |

### Backup / Restore

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| D24 | Low | fixed | Backup | `restoreFromBackup` 缺少明确警告：备份文件仅含数据库，不含照片、凭证等媒体文件。恢复后用户可能误以为数据完整。 | Fixed: restore confirmation explicitly warns that backups do not include photo or evidence file bodies and missing local files cannot be restored automatically. |

### Telemetry Calc UI Consistency (2026-06-08)

| ID | Severity | Status | Area | Finding | Fix / Acceptance |
| --- | --- | --- | --- | --- | --- |
| U79 | Medium | fixed | UI token | `telemetry_calc_view.dart` 全文 17 处 `BorderRadius.circular(8)` 硬编码，未使用 `AppRadius` 令牌。虽然 `8 == AppRadius.xs`，但脱离令牌体系，无法随全局调整。且统一使用 `xs` 级别，与全局共享组件（AppCard 用 lg=20, AppTextField 用 lg=20）圆角等级不一致。 | Fixed: telemetry calculator containers now use `AppRadius` by layer (`sm` for panes/sections, `xs` for compact inner controls) and regression coverage blocks reintroducing raw `BorderRadius.circular(8)`. |
| U80 | Medium | fixed | UI token | `telemetry_calc_view.dart` 全文 40+ 处间距值为 `.h/.w` 魔数（如 `18.h`, `14.h`, `11.w` 等），未引用 `AppSpacing` 令牌，且多个值在令牌体系中无对应位。 | Fixed: telemetry calculator gaps, padding, grid spacing, and wrap spacing now use `AppSpacing` tokens; remaining `.h/.w` values are fixed dimensions or responsive thresholds, with regression coverage for spacing/padding magic numbers. |
| U81 | Medium | fixed | UI layout | `_CalculationWorkbench` (L794–805) 的 `LayoutBuilder` 始终返回 `Row`，无条件竖屏堆叠逻辑。手机竖屏时输入/输出各约 165dp，极其拥挤；本次 redesign review 已将早先移动端双列选择修正为结果前置单列。 | Fixed: `_CalculationWorkbench` now stacks output above input below the adjusted workbench two-column threshold (`AppBreakpoints.tabletMin - 40`) and keeps a two-column workbench on tablet-width content; widget regression tests cover both widths. |
| U82 | Low | fixed | UI token | `_InfoPill` (L709–737) 重复实现了 `AppPill` 的功能，但使用不同的圆角 (8 vs AppRadius.lg=20) 和排版，视觉风格不一致。 | Fixed: `_InfoPill` now constrains and delegates to shared `AppPill`, inheriting the app pill radius, typography, and motion behavior. |
| U83 | Low | fixed | UI typography | 全文 25+ 处 `FontWeight.w800` 和 15+ 处 `FontWeight.w900`，连 11sp 辅助文本也用 w800/w900，导致所有文字同等视觉重量，层次感消失。主题 `TextTheme` 最重仅 w700。 | Fixed: low-size labels and secondary telemetry text now stay at w700 or below, with w800 reserved for primary detail/value anchors; regression coverage blocks 10/11sp labels from using w800/w900. |
| U84 | Low | fixed | UI style | `_CompactInputShell` 与全局 `AppTextField` 使用不同圆角、填充色透明度和 padding 方案，同一 app 两套输入框风格。 | Fixed: compact input shells now align with app text-field tokens by using `semantic.mutedSurface`, `AppRadius.lg`, `AppSpacing.lg`, and the shared semantic border model; source regression coverage blocks drift. |
| U85 | Low | fixed | UI motion | 计算模块完全无过渡动画，`AppMotion` 令牌未使用。高级参数展开/收起、结果更新均为硬切换，与其他模块（使用 `AnimatedContainer`、`AnimatedSlide` 等）体验不一致。 | Fixed: advanced input expansion now uses `AnimatedSize`, result changes use `AnimatedSwitcher`, and both are driven by `AppMotion` duration/curve tokens with regression coverage. |
| U86 | Low | fixed | UI type safety | `_categoryColor()` (L1970) 参数类型为 `dynamic`，应为 `AppSemanticColors`。 | Fixed: `_categoryColor()` now takes `AppSemanticColors` explicitly, preserving the existing category color behavior while removing the dynamic parameter. |
| U87 | Medium | fixed | UI layout | 计算详情页把公式依据直接放在主滚动内容中，形成 `ListView -> AppCard -> _FormulaPanel -> _FormulaCompactRow -> _FormulaExpression` 的深层嵌套，稀释输入/输出工作台的主任务。 | Fixed: formulas now live behind the AppBar `公式与依据` action and open in a bottom sheet, while the main detail content keeps the result/input workbench focused; widget coverage verifies the drawer path. |
| U88 | Low | fixed | UI discovery | 遥测计算主页（`TelemetryCalcView`）已增至 11 个计算器，但缺乏搜索栏，用户只能先猜分类再浏览卡片。 | Fixed: added a search field above the category chips; non-empty searches match across calculator titles, short titles, subtitles, standards, and category labels, with widget coverage for cross-category search. |
| U89 | Low | fixed | Template management | “最近模板”列表不支持长按删除、重命名或排序管理，只能被动展示最近项目。 | Fixed: recent template cards now support long-press management with rename/delete actions, `TelemetryTemplateStore` can rename templates, and widget coverage verifies rename/delete refresh the module page without regressing template loading. |
| U90 | Low | fixed | UI layout | `_InfoPill` 复用共享 `AppPill` 后，长标准文本在窄输出面板内可能触发横向 `RenderFlex overflow`，说明共享 pill 本身缺少文本省略保护。 | Fixed: `AppPill` now wraps its label in `Flexible` with single-line ellipsis; existing narrow telemetry workbench regression tests cover the long-label overflow path. |
| U91 | Medium | fixed | date grouping | `WorkLog.inMonth()`, `ExpenseEvidence.inMonth()`, and `ExpenseRecord.inMonth()` normalize record dates but compare against the raw target month. A UTC month boundary such as `2026-04-30 16:00Z` is local May 1 in the app timezone but was still treated as April, so monthly work, evidence, and expense totals could miss records. | Fixed: target months are normalized with `dateOnlyLocal()` before comparison, and `date_grouping_test.dart` covers UTC-to-local month-boundary grouping for work logs, evidence, and project expenses. |
| U92 | Medium | fixed | telemetry formula visibility | 公式知识库已有 1205 条目录项，实时计算器只暴露 11 个可运行工作台，其中系统类 3 个；首页和分类标签没有说明这个差异，用户打开新版本时会误以为大量公式没有进入应用。 | Fixed: telemetry home now surfaces formula-catalog count, integrated system-formula count, runnable calculator count, and per-category card counts; regression coverage verifies the summary and system category listing. |
| U93 | High | fixed | telemetry template dialog | 真机保存计算模板时出现 Flutter framework `_dependents.isEmpty` 红屏；保存/重命名模板弹窗在 `showDialog` action 内混用全局 `Get.back`，保存成功后又使用全局 snackbar overlay，存在路由/Inherited 依赖拆卸风险。 | Fixed: template name input is now a local stateful dialog that closes with its own `Navigator` context, detail pages accept injected template stores for regression tests, and save success uses an inline notice instead of a global snackbar overlay. |
| U94 | Medium | fixed | telemetry formula library | 1205 条公式已在文档中分类，但 App 缺少结构化公式库、论文式公式渲染、参数含义/概念/单位说明和公式库入口，导致用户只能看到少数工作台。 | Fixed: generated a local structured formula library from `formula_catalog.md` and `variable_glossary.md`, added domain classification/search/detail UI, rendered formulas with pure Flutter TeX plus fallback text, and added variable explanation coverage. |
