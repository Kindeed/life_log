# LifeLog 代码审查报告

**日期**: 2026-04-29 | **版本**: v1.3.0 | **范围**: lib/ (66 dart) + supabase/migrations/ (3 sql)

> Historical report. Active bug tracking moved to `BUG_TRACKER.md`.
> Any recommendation to add cloud-sync fields or cloud-sync flows to `PhotoItem` is superseded by `AGENTS.md`: photos are local-only and must not enter Supabase sync.

---

## P0 — 关键 (数据泄露 / 数据丢失 / 崩溃)

### 1. PhotoItem 用户隔离缺失；同步字段建议已失效

**文件**: `lib/modules/photo/photo_model.dart:6-24`, `lib/common/db/db_service.dart:244-265`

历史审查同时建议为 `PhotoItem` 增加用户隔离字段和云同步字段。当前架构已明确照片本地-only，因此只有 `ownerUserId` 本地隔离仍然有效；`syncId`、`remoteId`、`isDirty`、`deletedAt`、`pendingDelete`、`remoteVersion` 等云同步字段建议已被 `AGENTS.md` 明确否决。

**当前结论**: 保留并验证本地用户隔离；不得把照片加入 Supabase 同步或为 `PhotoItem` 增加云同步字段。

---

### 2. processAndSavePhoto 中 fileName 与实际文件路径不一致

**文件**: `lib/modules/photo/photo_repository.dart:77-78, 91`

```dart
final fileName = "${filePrefix}_$dateStr.jpg";      // 原始名称
final savePath = await _availablePath(...);           // 可能变成 xxx_1.jpg
// ...
..fileName = fileName    // 存的是原始名，不是 savePath 中的实际文件名
..filePath = savePath
```

`_availablePath()` 在重名时追加 `_1`、`_2` 后缀，但 `fileName` 字段始终存储未追加后缀的原始值。

**影响**: `fileName` 与 `filePath` 中实际文件名不匹配，导出和显示时可能引用错误名称。

---

### 3. LogService 并发写入文件

**文件**: `lib/common/services/log_service.dart:136`

```dart
_logFile?.writeAsString('$logString\n', mode: FileMode.append);
// 没有 await
```

`writeAsString` 返回 `Future` 但未等待。多次快速调用会导致对同一文件发起并发写入。

**影响**: 日志文件内容可能交错损坏。

---

### 4. syncRemoteLogToLocal 无远程数据校验

**文件**: `lib/common/db/db_service.dart:286, 350`

```dart
final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);
log.date = DateTime.parse(data['date']);
```

若 Supabase 返回的 `updated_at` 或 `date` 字段为 null 或格式异常，`DateTime.parse` 抛出异常，整个 `writeTxn` 中断，该条记录之后的远程数据全部丢弃。

---

## P1 — 高风险

### 5. BackupService 硬编码数据库文件名

**文件**: `lib/common/db/backup_service.dart:23`

```dart
final dbPath = p.join(dir.path, 'default.isar');
```

Isar 实际文件名取决于 `Isar.open()` 的 `name` 参数（默认为 `"isar"`）或 schema 名。硬编码 `default.isar` 可能导致备份/恢复操作找不到数据库文件。

---

### 6. SubscriptionController.reorderSub UI 与 DB 状态不同步

**文件**: `lib/modules/subscription/subscription_controller.dart:134-138`

```dart
final item = subs.removeAt(oldIndex);    // 先改 reactive list
subs.insert(newIndex, item);
await SubscriptionRepository.to.reorderSubscriptions(subs);  // 再写 DB
```

若 `reorderSubscriptions` 失败，`subs` 列表已变更但 DB 未更新。虽然 DB watch stream 最终会通过 `loadData()` 纠正，但存在短暂的不一致窗口。

---

### 7. ProfileController 退出登录后 widget 未保护

**文件**: `lib/modules/profile/profile_controller.dart:31-33`

```dart
Future<void> logout() async {
  await authService.signOut();
}
```

退出登录后未调用 `Get.offAllNamed('/login')` 跳转登录页，也未清空当前页面状态。用户退出后仍停留在 Profile 页面，界面状态与认证状态不一致，直到手动刷新。

---

### 8. LoginView 注册缺少密码确认字段

**文件**: `lib/modules/profile/views/login_view.dart:37-46`

注册表单只有单个密码输入框，无"确认密码"字段。用户输错密码无法在客户端纠正，只能通过 Supabase 密码重置流程恢复。

---

## P2 — 中等

### 9. catch (e) 静默吞掉错误

**文件**: `lib/modules/work_log/work_log_repository.dart:36`, `lib/modules/subscription/subscription_repository.dart:36`

```dart
} catch (e) {
  LogService.to.error(...);
  // 未 rethrow，调用方无感知
}
```

同步失败仅记录日志，UI 层无法区分"保存成功"和"保存到本地但同步失败"。

---

### 10. AddLogSheet 保存时无内容校验

**文件**: `lib/modules/work_log/add_log_sheet.dart:338-403`

出差模式下 `_tripCityController.text` 直接作为 `location`，可为空字符串；`_expenseController.text` 通过 `double.tryParse` 静默转为 null。用户可能不知晓输入了无效数据。

---

### 11. SyncService 特定边界条件可能丢同步信号

**文件**: `lib/common/services/sync_service.dart:400-410`

`_activeSync` 复用（第400行）优先于 2 秒去重（第406行）。若首次 `syncAll` 已完成（`_activeSync = null`）但 `_lastSyncStartedAt` 在 2 秒内，新的 `syncAll` 被跳过返回 true，但实际未执行任何同步。

---

### 12. AuthService.onInit 未检查错误状态

**文件**: `lib/common/services/auth_service.dart:10-29`

`onAuthStateChange.listen` 仅处理 `signedIn` / `signedOut` 事件。Supabase 可能触发 `tokenRefreshed`、`userUpdated`、`passwordRecovery` 等事件，当前未处理。

---

## P3 — 低风险 / 改进建议

### 13. 无测试覆盖

**文件**: `test/` 目录

仅 1 个测试文件 (`formatters_test.dart`)。核心同步逻辑、DbService CRUD、认证流程均无测试。

### 14. main() 中环境变量硬失败

**文件**: `lib/main.dart:26-31`

`String.fromEnvironment('SUPABASE_URL')` 未设置时抛出 `StateError`，App 直接崩溃。虽为有意设计，但缺少更友好的错误页面提示。

### 15. 照片删除无事务保护

**文件**: `lib/modules/photo/photo_repository.dart:101-110`

```dart
await file.delete();       // 先删文件
await DbService.to.deletePhoto(photo.id);  // 再删 DB
```

若应用在两步之间崩溃：文件已删除但 DB 记录残留（幽灵记录）。

---

## 总结

| 级别 | 数量 | 核心问题 |
|------|------|---------|
| P0 关键 | 4 | 照片本地隔离、fileName 不一致、日志竞态写入、远程数据无校验 |
| P1 高风险 | 4 | 备份文件名、UI/DB 不同步、退出登录状态、注册缺确认密码 |
| P2 中等 | 4 | 异常吞掉、输入无校验、同步去重边界、Auth 事件遗漏 |
| P3 低 | 3 | 无测试、环境变量 crash、照片删除无事务 |

**最优先修复（已按当前架构修正）**: P0-1 只允许补齐/验证 `PhotoItem.ownerUserId` 本地隔离；任何为 `PhotoItem` 添加云同步字段或同步流程的建议均已失效。

## 2026-05-10 UI 参考与回顾

本次入口改造参考了这些 Flutter 开源项目的交互方式：

- [Flow](https://github.com/flow-mn/flow)
- [Sossoldi](https://github.com/RIP-Comm/sossoldi)
- [Planka App](https://github.com/LouisHDev/planka_app)
- [Taskly](https://github.com/IMGIITRoorkee/Taskly)

回顾结论：

- 底部中心入口已改为按当前页切换动作。
- 工时入口直接分流到工时 / 出差 / 请假 / 休息。
- 页切换与入口按钮动画已改为更缓的节奏。
- `flutter analyze` 与 `flutter test` 通过。
