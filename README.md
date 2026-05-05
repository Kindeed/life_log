# LifeLog

LifeLog 是一个本地优先的 Flutter 生活记录应用，用于管理工时、订阅/一次性支出、项目照片、凭证与统计面板。应用默认可以离线运行；配置 Supabase 后启用账号登录与云同步。

## 功能概览

- 工时记录：工作、出差、请假、休息，支持农历、节气和周/月日历视图。
- 支出管理：订阅和一次性支出，支持扣费提醒、筛选、排序和拖拽排序。
- 项目资料：项目照片归档、凭证记录、报销状态和项目级汇总。
- 数据面板：工时、订阅、出差垫付、项目凭证等核心指标。
- 本地优先：无云配置时自动进入本地模式，不影响本地记录。
- 云同步：通过 Supabase publishable key 注入启用登录、同步和远端合并。
- 开发者诊断：应用内日志、启动状态、云配置状态和诊断信息导出。

## 技术栈

- Flutter 3.38.5 / Dart 3.10
- GetX：路由、依赖注入和状态管理
- Isar：本地数据库
- Supabase：认证、远端数据同步和 Storage
- GitHub Actions：测试包和发布 APK 构建

## 本地运行

无云配置，本地模式：

```bash
flutter pub get
flutter run -d 10ADBE34P2001PF
```

启用 Supabase 云同步：

```bash
flutter run -d 10ADBE34P2001PF \
  --dart-define=SUPABASE_URL=https://ikaoktfmytsnximtijjg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

客户端 key 不写入源码。CI 构建需要在 GitHub Secrets 配置：

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 常用命令

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release --split-per-abi
```

带云配置构建：

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://ikaoktfmytsnximtijjg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

## 数据与同步

应用启动时会先初始化本地存储、日志服务、Isar 数据库和主题服务。只有在 `SUPABASE_URL` 与 `SUPABASE_ANON_KEY` 都存在时才初始化 Supabase，并注册认证与同步服务。

同步协议使用本地 `syncId`、远端版本、软删除和拉取游标处理多设备合并。相关数据库变更在 `supabase/migrations/` 下维护。

## 发布

- `build.yml`：推送 `v*` tag 后构建 release APK 并上传 GitHub Release。
- `test-apk.yml`：手动触发测试 APK 构建。
- 两个 workflow 默认要求 Supabase secrets 存在，避免产出无法登录同步的云版本 APK。

## 维护说明

- 不提交本地诊断输出、diff 临时文件、构建产物和签名文件。
- Isar `.g.dart` 文件由 `build_runner` 生成，只有模型变更时才应更新。
- 视觉系统集中在 `lib/common/theme/` 和 `lib/common/widgets/`，页面应优先复用公共组件。
