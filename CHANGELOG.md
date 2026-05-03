# Changelog

## [1.3.2] - 2026-05-03

### 🎨 Apple 视觉化与 UI 控件去重

#### 新增 (Added)
- 新增 `AppFloatingActionPill`，统一支出和项目页的底部浮动添加入口。
- 新增 `AppPill`，收敛统计、项目、支出等页面重复的胶囊标签样式。
- 新增 `AppSheetScaffold`，统一底部弹窗的抓手、标题、圆角、内容区和底部操作区。

#### 变更 (Changed)
- 应用版本升级到 `1.3.2+3`。
- 将主色更新为 iOS system blue，并将浅色/深色背景、卡片、边框调整为 Apple grouped 风格。
- 优化 `AppButton`、`AppTextField`、`AppCard`、`AppActionSheet`、`AppConfirmDialog`、`AppSafeBottomBar`、`AppFilterChipBar` 的视觉层级和交互一致性。
- 替换工时、支出、项目、图库、登录、拍照归档、项目选择、开发者页中的重复按钮、输入框、弹窗、底栏和确认框实现。

#### 验证 (Validation)
- `flutter analyze` 通过。
- `flutter test` 未执行：当前项目没有 `test/` 目录。
- Android 模拟器环境已安装到 D 盘并创建 `LifeLog_API36`，但本机硬件虚拟化未启用，模拟器无法启动。

## [1.3.1] - 2026-04-29

### 新增：项目凭证与报销记录

#### 新增 (Added)
- 新增独立的项目凭证模块，用于记录发票、付款截图、购买记录和报销状态。
- “项目资料”页新增“照片 / 凭证”双视图切换，不新增底部导航入口。
- 凭证支持拍摄、相册导入、手动记录、编辑、删除和导出。
- 凭证按项目归档，支持搜索、排序、金额汇总和状态展示。
- 统计页新增“凭证待报销 / 凭证已报销”，并与原出差垫付统计分开，避免重复计算。

#### 同步 (Sync)
- 新增 `expense_evidence` 本地 Isar collection，并接入现有 owner、syncId、version、dirty、soft delete 同步协议。
- 新增 Supabase `expense_evidence` 表迁移和 `evidence-files` Storage bucket 策略。
- 凭证元数据同步到 Supabase，凭证图片上传到 Storage，并支持跨设备下载恢复。

#### 版本 (Release)
- 应用版本升级到 `1.3.1+2`。
- 本版本应通过推送 `v1.3.1` tag 触发 GitHub Actions 自动构建 APK。

## [1.3.0] - 2026-04-27

### 🎨 架构级重构：UI 系统全面现代化升级

将应用 UI 从早期的“各页面独立硬编码样式”全面升级为一套现代、语义化、高一致性的设计体系，并完成了核心业务页面的彻底重构。

#### 新增 (Added)
- **统一 Design Token 系统**：引入了 `AppSemanticColors` (语义化配色)、`AppSpacing`、`AppRadius`、`AppMotion` 和 `AppElevations`。支持深浅色模式平滑切换，彻底告别硬编码色值。
- **纯粹的低耦合基础组件库**：新增 `AppCard`、`AppButton`、`AppTextField`、`AppMetricTile`、`AppConfirmDialog`、`AppFilterChipBar` 等 10+ 基础通用组件，所有公共组件严格遵循**纯 UI 无状态/无 Controller 依赖**原则。
- **响应式布局架构**：实现 `ConstrainedPage` 和 `AppBreakpoints` 容器体系，保证在折叠屏/平板设备上的宽屏体验约束，手机端则保持沉浸式体验。
- **全局格式化工具**：在 `lib/common/utils/formatters.dart` 中统一定义金额等格式化函数，减少各业务面重复定义。
- **开发者 UI 画廊 (Design Gallery)**：在开发者选项新增 UI 画廊入口，供研发实时预览、验证 Design Token 与核心组件库在各主题下的效果。

#### 重构 (Refactored)
- **支出模块 (Subscription)**：
  - 重构列表渲染与数据摘要，新增即时警告卡片 (`AppMetricTile` / `AppCard`)。
  - 实现双维度筛选引擎（支持“按周期过滤”与“按模式排序”解耦，配合双组 `AppFilterChipBar`）。
  - 完善拖拽排序守卫逻辑，仅在特定排序模式开启拖拽，确保状态不乱。
  - 过期未付款账单现支持红色强警告高亮 (`_DueStatus.isSoon = true`)。
- **工时模块 (WorkLog)**：
  - 将日历默认视图切换为“周视图 (`CalendarFormat.week`)”，释放小屏可用空间。
  - 重写了当日日志列表组件 `DayLogList`，现已完美支持同一天内同时展示多条“工作/出差/请假/休息”复合记录。
  - 日志卡片 (`_DayLogCard`) 应用类型化的语义色彩与图标组合，信息辨识度大幅提升；补充了农历及标准空状态界面 (`AppEmptyState`)。
- **统计模块 (Statistics)**：
  - 构建了直观的 2×2 `AppMetricTile` 核心指标网格。
  - 通过轻量化 `LinearProgressIndicator` 开发了双模式 `_ProgressRow` 对比条组件，用极低成本实现了财务与工时的核心图表化表达。
  - 优化 AppBar 右上角交互，以图标按钮和丝滑切页动画 (`AppMotion.fast`) 取代此前冗余文字状态。
- **我的与设置 (Profile)**：
  - 用户选项划分为五大层级分组 (`_SettingsGroup`)，搭配 `AppSectionHeader`，界面清晰易读。
  - 账号卡片信息强化表达（登录、同步、离线提示）；开发者入口层级作了合理的透明度弱化 (`muted: true`)。
- **交互与危险操作统一**：所有删除/登出等破坏性动作已全面接入 `AppConfirmDialog` 并绑定震动触觉反馈 (`HapticFeedback`)。

## [1.2.0] - 2026-04-27

### 🔄 重构：同步协议升级

从简单的 `isDirty` 标记方案全面升级为基于 `syncId`、`version`（乐观锁）和软删除的专业同步协议。

#### 新增 (Added)

- **syncId 全局唯一标识**：每条记录在本地创建时立即分配 UUID v4，替代依赖本地自增 ID 进行合并，解决多设备 ID 冲突问题
- **乐观锁版本控制 (remoteVersion)**：Update 操作带 `version` 条件检查，防止多设备并发覆盖
- **软删除 (deletedAt + pendingDelete)**：删除不再物理移除，先标记 tombstone 确保云端同步后才清理
- **冲突检测与恢复**：Push 冲突时自动从远端重新拉取最新版本刷新本地 `remoteVersion`，下次重推可自动恢复
- **服务端时间游标 (`get_server_time` RPC)**：Pull 使用 Supabase 服务端时间作为增量拉取基准，消除客户端时钟偏差
- **智能增量/全量拉取**：首次同步或无 cursor 时全量拉取，后续自动增量，支持 `forceFullRefresh` 参数手动强制全量
- **Pull cursor 独立于 Push**：`_lastPullCursorKey` 在 Pull 成功后立即写入，不再依赖 Push 结果
- **Supabase 数据库迁移脚本**：新增 3 个 SQL migration 文件用于建表/加列/创建 RPC 函数

#### 变更 (Changed)

- **WorkLog / Subscription Model**：新增 `syncId`、`remoteVersion`、`remoteUpdatedAt`、`deletedAt`、`pendingDelete` 字段，重新生成 Isar Schema (`.g.dart`)
- **SyncService**：完全重写 Push/Pull 逻辑，支持 insert/update/delete 三种操作的独立处理
- **DbService**：
  - `markLogDeleted` / `markSubscriptionDeleted` 改为返回更新后的对象，消除删除流程中的竞态问题
  - `syncRemoteLogToLocal` / `syncRemoteSubscriptionToLocal` 增加 syncId 优先匹配、冲突检测（isDirty 保护）、远端已删除记录的自动清理
  - 新增 `getAllLogsForSync` / `getAllSubscriptionsForSync` 返回包含 tombstone 的完整列表
- **WorkLogRepository / SubscriptionRepository**：
  - `saveLog` / `saveSubscription` 在保存时立即分配 syncId
  - `deleteLog` / `deleteSubscription` 使用 `markLogDeleted` 返回的对象直接发送删除请求，消除旧对象竞态
  - `reorderSubscriptions` 不再逐条推送，只标记 dirty 等待 `syncAll` 批量同步
- **add_log_sheet / add_subscription_sheet**：编辑已有记录时完整拷贝所有同步字段 (`syncId`, `remoteVersion`, `remoteUpdatedAt`, `deletedAt`, `pendingDelete`)
- **_pushUnsyncedData**：推送条件扩展为 `remoteId == null || isDirty || pendingDelete`，确保所有待同步状态都被处理
- **syncAll 防重入**：新增 `_activeSync` future 复用和 2 秒去抖，防止重复触发
- **推送日志增强**：显示 attempted/failed 计数，便于调试

#### 修复 (Fixed)

- 编辑记录后丢失 syncId/remoteVersion 导致重复记录或乐观锁冲突
- 删除流程中使用旧内存对象导致状态不一致
- pendingDelete 记录被推送过滤条件遗漏
- Pull 拉到远端已删除记录后本地 tombstone 不清理导致存储膨胀
- 排序变更触发 N 次网络请求导致卡顿

#### 后端要求 (Backend Requirements)

使用此版本前，需在 Supabase 执行 `supabase/migrations/` 下的迁移脚本：

1. `20260426_sync_identity_version.sql` — 添加 `sync_id`、`version` 列和唯一约束
2. `20260426_soft_delete_sync.sql` — 添加 `deleted_at`、`expenses`、`transport` 等列
3. `20260426_server_time_rpc.sql` — 创建 `get_server_time()` RPC 函数

---

## [1.1.6] - 2026-03-08

### Refactored

* **Architecture Compliance**: Migrated data-access operations across all modules (`WorkLog`, `Subscription`, `Photo`) to the strict Repository Pattern. View controllers no longer orchestrate queries.
* **Photo Module Serialization**: Standardized the Photo workflow. Relegated all path acquisition, target file relocation, and legacy record cleanup functions into `PhotoRepository`.
* **Sync Isolation**: Removed bilateral dependencies between `DbService` and `SyncService`. Cleaned `isDirty`/`remoteId` mapping during create and update transactions to prevent silent duplications.
* **UI/Data Separation in Settings**: Disengaged GetX UI alert invocations from the `BackupService` instance. The Backup/Restore operations strictly utilize Exception throwing to direct feedback on the Presentation layer (`DataManagementView`).
