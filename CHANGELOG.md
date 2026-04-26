# Changelog

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
