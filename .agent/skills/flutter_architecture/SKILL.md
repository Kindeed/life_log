---
name: Life Log Flutter Architecture Guide
description: |
  Life Log 项目的架构规范和设计约定。所有代码修改必须遵守本规范。
  本文件是项目的"架构宪法"，任何 AI 助手在修改代码前必须阅读并严格遵守。
---

# Life Log Flutter Architecture Guide

> **⚠️ 重要：所有 AI 助手在修改本项目代码前，必须阅读并遵守本规范。违反规范的修改将导致架构退化。**

---

## 1. 技术栈（锁定版本）

| 技术 | 版本 | 用途 | 🔒 禁止替代 |
| ------ | ------ | ------ | ------------- |
| Flutter | SDK ^3.10.4 | UI 框架 | — |
| **GetX** | ^4.6.6 | 状态管理 + 路由 + 依赖注入 | 🚫 禁止引入 Provider / Riverpod / BLoC |
| **Isar** | ^3.1.0 | 本地数据库 | 🚫 禁止引入 sqflite / drift / hive |
| Supabase | ^2.12.0 | 云端同步 + 认证 | — |
| GetStorage | ^2.1.1 | 轻量级 KV 存储 | — |
| flutter_screenutil | ^5.9.0 | 屏幕适配 | — |

---

## 2. 项目目录结构

```text
lib/
├── main.dart                           # 入口：初始化服务 + 注册控制器
├── common/                             # 🏛️ 通用基础设施（跨模块共享）
│   ├── db/
│   │   ├── db_service.dart             #   唯一的数据库访问层（Isar CRUD）
│   │   └── backup_service.dart         #   数据库备份/恢复（纯静态工具类）
│   ├── services/
│   │   ├── auth_service.dart           #   认证服务（Supabase Auth）
│   │   ├── sync_service.dart           #   云端同步服务（push/pull）
│   │   ├── log_service.dart            #   日志服务
│   │   └── event_bus.dart              #   事件总线（模块间解耦通信）
│   └── theme/
│       ├── app_colors.dart             #   颜色常量
│       ├── app_theme.dart              #   主题配置（Light / Dark）
│       ├── custom_colors.dart          #   ThemeExtension 自定义颜色
│       └── theme_controller.dart       #   主题切换控制器
│
└── modules/                            # 📦 功能模块（每个 Tab 一个模块）
    ├── tabs/                           #   App Shell（导航框架）
    ├── work_log/                       #   📅 工时模块
    ├── subscription/                   #   💳 订阅管理模块
    ├── photo/                          #   📷 项目文件管理模块
    ├── statistics/                     #   📊 统计面板模块
    └── profile/                        #   👤 个人中心模块
```

### 2.1 模块内部标准结构

每个功能模块应遵循以下结构：

```text
modules/xxx/
├── xxx_model.dart              # 数据模型（@collection）
├── xxx_model.g.dart            # Isar 自动生成（禁止手动编辑）
├── xxx_controller.dart         # 业务逻辑控制器
├── xxx_view.dart               # 模块主视图
├── add_xxx_sheet.dart          # 添加/编辑底部弹窗（如有）
└── widgets/                    # 子组件目录（拆分出的小组件）
    ├── xxx_header.dart
    └── xxx_card.dart
```

### 2.2 命名约定

| 类型 | 文件命名 | 类命名 | 示例 |
| ------ | ---------- | -------- | ------ |
| 数据模型 | `xxx_model.dart` | `XxxModel` 或业务名 | `work_log_model.dart` → `WorkLog` |
| 控制器 | `xxx_controller.dart` | `XxxController` | `work_log_controller.dart` → `WorkLogController` |
| 主视图 | `xxx_view.dart` | `XxxView` | `work_log_view.dart` → `WorkLogView` |
| 底部弹窗 | `add_xxx_sheet.dart` | `AddXxxSheet` | `add_log_sheet.dart` → `AddLogSheet` |
| 子组件 | `widgets/xxx_yyy.dart` | `XxxYyy` | `widgets/calendar_header.dart` → `CalendarHeader` |
| 事件 | 集中在 `event_bus.dart` | `XxxChangedEvent` | `WorkLogChangedEvent` |
| Service | `xxx_service.dart` | `XxxService` | `sync_service.dart` → `SyncService` |

> **已知不一致（历史遗留，后续迭代时修正）：**
>
> - `log_model.dart` 应为 `work_log_model.dart`（类是 `WorkLog`）
> - `PhotoItem` 的 `Item` 后缀与其他模型不一致
> - `capture_dialog.dart` 和 `project_picker.dart` 是顶层函数而非 Widget 类

---

## 3. 分层架构（核心规则）

```text
┌───────── View 层 ─────────┐
│ StatelessWidget            │ 
│ 只负责渲染, 不含业务逻辑     │
│ 通过 Get.find<>() 获取控制器 │
└──────────┬────────────────┘
           │ 调用
┌──────────▼────────────────┐
│ Controller 层              │
│ GetxController             │
│ 管理状态(.obs) + 业务逻辑   │
│ 调用 DbService 做数据操作   │
│ 通过 EventBus 发布跨模块事件 │
└──────────┬────────────────┘
           │ 调用
┌──────────▼────────────────┐
│ Service 层                 │
│ DbService: 唯一数据库入口   │
│ SyncService: 云端同步       │
│ AuthService: 认证           │
│ LogService: 日志            │
│ EventBus: 事件通信          │
└──────────┬────────────────┘
           │ 操作
┌──────────▼────────────────┐
│ Data 层                    │
│ Isar @collection 数据类    │
│ 纯数据结构, 无逻辑          │
└───────────────────────────┘
```

### 3.1 层级依赖规则

| 调用方向 | 允许? | 说明 |
| ---------- | ------- | ------ |
| View → Controller | ✅ | 唯一获取数据和触发操作的方式 |
| View → DbService | 🚫 | **禁止！** |
| View → SyncService | 🚫 | **禁止！** |
| View → Supabase | 🚫 | **禁止！** |
| Controller → DbService | ✅ | 通过 DbService 做数据操作 |
| Controller → Supabase | 🚫 | **禁止！** 必须通过 SyncService |
| Controller → 其他模块 Controller | 🚫 | **禁止！** 使用 EventBus |
| DbService → SyncService | ✅ | 数据写入后触发同步 (fire-and-forget) |
| SyncService → Supabase | ✅ | 唯一操作 Supabase 的入口 |

---

## 4. 模块隔离原则（防止新增模块影响现有模块）

### 4.1 核心原则：新增不修改

> **开放封闭原则（OCP）：对扩展开放，对修改封闭。**
> 新增模块时，应尽量只"添加"新代码，不修改现有模块的代码。

### 4.2 模块边界规则

```text
┌──────────────┐   EventBus    ┌──────────────┐
│  work_log    │ ◄────────────►│  statistics  │
│  模块        │   事件通信     │  模块        │
│              │               │              │
│ Controller   │               │ Controller   │
│ View         │               │ View         │
│ Model        │               │ Model        │
└──────┬───────┘               └──────┬───────┘
       │                              │
       │ 调用                          │ 调用
       ▼                              ▼
  ┌─────────────────────────────────────────┐
  │           common/ (共享层)               │
  │   DbService | SyncService | EventBus    │
  └─────────────────────────────────────────┘
```

1. **模块之间 100% 隔离** — 模块 A 的代码不得 `import` 模块 B 的任何文件
   - ✅ `work_log/` 可以 import `common/`
   - 🚫 `work_log/` 不得 import `subscription/`、`photo/` 等
   - **唯一例外**：`statistics/` 模块作为聚合面板，可以 import 其他模块的 **Model**（数据类型），但不得 import 其他模块的 Controller 或 View
   - **唯一例外**：`tabs/` 模块负责组装 App Shell，可以 import 各模块的主 View

2. **新增模块不修改现有模块** — 添加新模块只需修改以下文件：
   - `main.dart`：注册控制器
   - `tabs_view.dart`：添加 Tab（如果需要）
   - `event_bus.dart`：添加新事件类型
   - `db_service.dart`：添加新的 CRUD 方法
   - `sync_service.dart`：添加新的同步方法
   - **不得修改** 其他已有模块的 Controller / View / Model

3. **跨模块通信只能用 EventBus** — 示例：

   ```dart
   // ✅ 正确：work_log 模块发布事件
   EventBus.instance.fire(const WorkLogChangedEvent());
   
   // ✅ 正确：statistics 模块监听事件
   EventBus.instance.on<WorkLogChangedEvent>((event) => refreshStats());
   
   // 🚫 错误：statistics 直接调用 work_log 的控制器
   Get.find<WorkLogController>().loadData(); // 禁止！
   ```

### 4.3 新增模块安全检查清单

在添加新功能模块时，按以下步骤操作，每一步都确认不影响现有模块：

#### 第一阶段：建模型（不影响任何现有代码）

- [ ] 1. 在 `modules/xxx/` 下创建 `xxx_model.dart`
- [ ] 2. 添加 `@collection` 注解和同步字段（`remoteId`, `syncedAt`, `isDirty`）
- [ ] 3. 运行 `dart run build_runner build` 生成 `.g.dart`

#### 第二阶段：扩展共享层（仅在 `common/` 下添加方法）

- [ ] 4. 在 `DbService` 中**添加** CRUD 方法（`addXxx`, `getXxx`, `deleteXxx`）
- [ ] 5. **每个写入方法都必须触发 SyncService 对应的同步方法**
- [ ] 6. 在 `SyncService` 中**添加** `pushXxx()`, `deleteXxx()` 方法
- [ ] 7. 在 `SyncService._pullAll()` 和 `_pushUnsyncedData()` 中**添加**新模型处理
- [ ] 8. 在 `event_bus.dart` 中**添加**新事件类型 `XxxChangedEvent`

#### 第三阶段：建控制器和视图（完全独立，不影响其他模块）

- [ ] 9. 创建 `xxx_controller.dart`，继承 `GetxController`
- [ ] 10. 创建 `xxx_view.dart`，使用 `StatelessWidget`
- [ ] 11. 使用 `Obx()` 做数据绑定，颜色用 `Theme.of(context)` / `AppColors`

#### 第四阶段：注册和装配（极少修改点）

- [ ] 12. 在 `main.dart` 中添加 `Get.lazyPut(() => XxxController(), fenix: true)`
- [ ] 13. 在 `tabs_view.dart` 中添加 Tab（如需要）
- [ ] 14. 在 `DbService.init()` 注册新的 Schema（`XxxSchema`）

#### 第五阶段：验证隔离性

- [ ] 15. **确认新代码没有 import 任何其他模块的文件**（`common/` 除外）
- [ ] 16. **确认没有修改任何现有模块的 Controller / View 文件**
- [ ] 17. 确认 Light/Dark 模式都正常
- [ ] 18. 确认使用了 `flutter_screenutil` 做屏幕适配

### 4.4 DbService / SyncService 扩展模式

当为新模块添加数据操作时，遵循现有的"同步模板"：

```dart
// DbService 中的写入方法模板
Future<void> addXxx(XxxModel item) async {
  await isar.writeTxn(() async {
    await isar.xxxModels.put(item);
  });
  // ⚠️ 必须！Fire-and-forget 同步
  try {
    SyncService.to.pushXxx(item);
  } catch (_) {}
}

// DbService 中的删除方法模板
Future<void> deleteXxx(int id) async {
  final item = await isar.xxxModels.get(id);
  final remoteId = item?.remoteId;
  
  await isar.writeTxn(() async {
    await isar.xxxModels.delete(id);
  });
  
  // 同步删除到云端
  if (remoteId != null) {
    try {
      SyncService.to.deleteXxx(remoteId);
    } catch (_) {}
  }
}
```

---

## 5. GetX 使用规范

### 5.1 服务注册（main.dart）

```dart
// 1. 核心服务 — 立即初始化（GetxService，生命周期 = App）
await Get.putAsync(() => DbService().init());
Get.put(ThemeController());
await Get.putAsync(() => LogService().init());
Get.put(AuthService());
Get.put(SyncService());

// 2. 模块控制器 — 懒加载 + fenix 自动重建
Get.lazyPut(() => WorkLogController(), fenix: true);
Get.lazyPut(() => PhotoController(), fenix: true);
Get.lazyPut(() => SubscriptionController(), fenix: true);
```

### 5.2 规则

| 规则 | 说明 |
| ------ | ------ |
| Service 继承 `GetxService` | 生命周期 = App |
| Controller 继承 `GetxController` | 可被回收重建 |
| Service 单例用 `static get to` | `static XxxService get to => Get.find()` |
| Controller 单例用 `static get to` | 如需全局访问，提供 `static XxxController get to => Get.find()` |
| 响应式变量用 `.obs` | 所有 UI 需要监听的状态 |
| View 统一用 `StatelessWidget` | 不用 `StatefulWidget`（除非需要动画控制器等 mixin） |
| 响应式绑定用 `Obx()` | 🚫 不用 `GetBuilder` |
| 底部弹窗可用 `StatefulWidget` | `AddLogSheet` 等表单类可用 `StatefulWidget` 管理表单状态 |

---

## 6. 数据同步模式

### 6.1 Local-First 写入流程

```text
用户操作 → Controller.addXxx()
         → DbService.addXxx()        // 1. 先写本地
         → SyncService.pushXxx()     // 2. fire-and-forget 推云端
         → Controller.loadData()     // 3. 刷新视图
         → EventBus.fire(XxxChangedEvent())  // 4. 通知其他模块
```

### 6.2 同步字段模板

所有需要云端同步的数据模型必须包含：

```dart
@collection
class XxxModel {
  Id id = Isar.autoIncrement;

  // 同步字段（必须）
  int? remoteId;       // Supabase 远程 ID
  DateTime? syncedAt;  // 最后同步时间
  bool isDirty = false; // 是否有未同步的修改

  // ... 业务字段
}
```

---

## 7. 主题/颜色规范

### 7.1 颜色使用规则

| 场景 | 正确做法 | 错误做法 |
| ------ | ---------- | ---------- |
| 品牌色 | `AppColors.primaryBlue` | `Color(0xFF1A73E8)` |
| 背景色 | `theme.scaffoldBackgroundColor` | 硬编码颜色值 |
| 卡片色 | `theme.cardColor` | `Colors.white` |
| 文字主色 | `AppColors.lightTextPrimary` / `darkTextPrimary` | `Colors.black` |
| 分割线 | `theme.dividerColor` | `Colors.grey` |
| 日志类型色 | `Theme.of(context).extension<LogColors>()` | 硬编码 |
| 错误色 | `theme.colorScheme.error` | `Colors.red` |
| 成功色 | `AppColors.successGreen` | `Colors.green` |

### 7.2 深色模式支持

- **所有页面必须同时支持 Light 和 Dark 模式**
- 在 View 中通过 `Theme.of(context)` 获取主题，**不要用 `Get.isDarkMode`**：

  ```dart
  // ✅ 正确
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  // 🚫 错误（不在 Widget 树中时可能不准确）
  Get.isDarkMode
  ```

- **禁止** 在 View 中硬编码颜色值（**当前 `capture_dialog.dart` 和 `project_picker.dart` 违反此规则，待修正**）

### 7.3 屏幕适配

使用 `flutter_screenutil`：

- 宽度/水平间距：`16.w`
- 高度/垂直间距：`24.h`
- 字体大小：`14.sp`
- 设计稿基准：`375 x 812`

### 7.4 圆角和阴影标准

```dart
const double kRadius = 24.0;

BoxShadow(
  color: isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.03),
  blurRadius: 20,
  offset: const Offset(0, 8),
)
```

---

## 8. 模块间通信

### 8.1 事件定义

所有事件集中在 `event_bus.dart`：

```dart
abstract class AppEvent { const AppEvent(); }

class WorkLogChangedEvent extends AppEvent { const WorkLogChangedEvent(); }
class SubscriptionChangedEvent extends AppEvent { const SubscriptionChangedEvent(); }
// 新增模块在这里添加事件
```

### 8.2 使用模式

```dart
// 发布（在 Controller 中）
EventBus.instance.fire(const WorkLogChangedEvent());

// 订阅（在另一个 Controller 的 onInit 中）
_logSub = EventBus.instance.on<WorkLogChangedEvent>((event) {
  refreshStats();
});

// 清理（在 onClose 中）
_logSub?.cancel();
```

---

## 9. 已知技术问题（后续迭代修正清单）

以下是已修正的技术问题记录（全部已于 2026-02-12 修复）：

| # | 问题 | 状态 | 修正内容 |
| --- | ------ | ------ | ---------- |
| 1 | 文件名 `log_model.dart` 应为 `work_log_model.dart` | ✅ 已修复 | 重命名文件并更新所有引用，重新生成 `.g.dart` |
| 2 | 空目录 `common/utils/` 和 `work_log/views/` | ✅ 已修复 | 已删除空目录 |
| 3 | `capture_dialog.dart` 和 `project_picker.dart` 使用全局函数而非 Widget | ✅ 已修复 | 用 `Builder` 包装获取 `BuildContext` |
| 4 | `capture_dialog.dart` 和 `project_picker.dart` 使用 `Get.isDarkMode` + 硬编码颜色 | ✅ 已修复 | 改用 `Theme.of(context)` + `AppColors` |
| 5 | `PhotoView` 使用 `GetView` 而非 `StatelessWidget` | ✅ 已修复 | 改为 `StatelessWidget` + `Get.find()` |
| 6 | `SubscriptionController` 缺少 `static get to` | ✅ 已修复 | 添加 `static SubscriptionController get to => Get.find()` |
| 7 | `BackupService` 是纯静态类而非 `GetxService` | ✅ 已修复 | 保持静态工具类，添加注释说明设计意图 |

---

## 10. 🚫 绝对禁止事项

1. **禁止在 View 层直接操作 Isar 数据库**
2. **禁止在 View 层或 Controller 层直接操作 Supabase**
3. **禁止硬编码颜色值**（必须使用 `AppColors` 或 `Theme`）
4. **禁止使用 `setState`**（GetX 项目用 `.obs` + `Obx()`；表单弹窗中允许 `StatefulWidget`）
5. **禁止手动编辑 `.g.dart` 文件**
6. **禁止在 DbService 的写入方法中遗漏 SyncService 调用**
7. **禁止模块间直接 import 对方的 Controller / View**（使用 EventBus）
8. **禁止引入新的状态管理框架**（Provider / Riverpod / BLoC）
9. **禁止引入新的数据库框架**（sqflite / drift / hive）
10. **禁止在非 `common/theme/` 路径下定义颜色常量**
11. **禁止使用 `exit(0)` 退出应用**
12. **禁止新增模块时修改已有模块的 Controller / View 文件**（除非是 bug 修复）
