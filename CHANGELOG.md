# Changelog

## [1.4.26] - 2026-07-08

### 相机恢复与同日工时修复

#### 新增 (Added)
- 应用版本升级到 `1.4.26+32`。
- 新增项目照片和凭证 `image_picker` lost-data 恢复边界测试，覆盖 Android 外部相机/图库导致 Activity 重建后的回收路径。
- 新增同日工时保存回归测试，覆盖 FAB 打开已有工作记录和 repository 采用既有工作身份的路径。

#### 变更 (Changed)
- 工时页 `记工时` 在当天已有工作记录时改为编辑最新工作记录，不再默认创建第二张同日“工作”卡片。
- WorkLog repository 对新建同日工作保存采用已有工作记录身份，同时继续保留同日请假、出差、报销等不同类型记录。

#### 修复 (Fixed)
- 修复项目内拍照时 Android 外部相机重建 `MainActivity` 后可能黑屏/空白并丢失照片和项目上下文的问题。
- 修复凭证拍摄/图库导入在 Activity 重建后丢失返回图片的问题，恢复后会重新打开凭证编辑器并带回项目和来源上下文。
- 修复凭证编辑器在外部 picker 或异步保存/删除返回前已关闭时，仍可能写入已释放 UI/Cubit 状态的问题。

#### 验证 (Validation)
- `flutter test` 通过，当前环境为 `510 passed`。
- `flutter analyze` 通过。
- `git diff --check` 通过。
- `flutter build apk --debug` 通过。
- Android 模拟器 `LifeLog_API_34_DTool` 验证：新建项目后进入凭证拍摄，系统相机返回正常；在相机打开时杀掉 `com.wzh.lifelog` 后拍照返回，应用重启并恢复到凭证编辑器，crash buffer 为空。

## [1.4.25] - 2026-07-07

### 工时记录与同步数据边界修复

#### 新增 (Added)
- 应用版本升级到 `1.4.25+31`。
- 新增真实 Isar 回归测试，覆盖登录态昨天/今天/未来工时反复保存后仍同时可见。
- 新增跨 owner 远端 pull、远端 tombstone、项目/出差关联、EvidenceAttachment 队列和 sync-id 删除协议回归测试。

#### 变更 (Changed)
- 远端同步 merge 现在按当前账号 owner 精确解析 `syncId`、`remoteId` 和附件 `evidenceSyncId`，不再用全库首条命中。
- EvidenceAttachment 本地 `syncId` 改为非唯一索引，与云端 `(user_id, sync_id)` 唯一身份保持一致。
- 删除入口保留 `remoteId == null` 但仍有 `syncId` 的记录，让同步层先按 `(user_id, sync_id)` 写远端 tombstone。

#### 修复 (Fixed)
- 修复新建工时、订阅、凭证、支出、项目和本地照片使用 `id == 0` 时可能覆盖同一条 Isar 本地记录的问题。
- 修复登录态远端 pull 可能把另一个本地 owner 的同步记录改写、改 owner 或被远端 tombstone 误删的问题。
- 修复 `remoteId` 未落本地但云端 upsert 已成功时，删除同步直接本地 purge 导致云端孤儿记录残留的问题。
- 修复 EvidenceAttachment 队列按 `syncId` / `evidenceSyncId` 全局命中时可能误改或误删另一个 owner 附件的问题。

#### 验证 (Validation)
- `flutter test` 通过，当前环境为 `503 passed`。
- `flutter analyze` 通过。
- `git diff --check` 通过。
- `flutter build apk --debug` 通过。
- Android 模拟器 `emulator-5554` 安装并启动 `com.wzh.lifelog/.MainActivity` 成功，crash buffer 为空。

## [1.4.24] - 2026-07-05

### 工时记录可见性与同步身份修复

#### 新增 (Added)
- 应用版本升级到 `1.4.24+30`。
- 新增登录态工时保存回归测试，覆盖未归属本地记录、当前账号记录和重复日期新增的可见性。

#### 变更 (Changed)
- Today 页的主工时卡片继续使用当天最新一条记录作为摘要。
- Today 页的 `最近工时` 和当前月工时汇总改为基于全部最近/月度工时记录，不再按每天只保留一条折叠展示。
- 登录后保留本地数据时，列表读取允许同时显示当前账号记录和未归属本地记录；待同步读取仍只允许当前账号记录。

#### 修复 (Fixed)
- 修复 Today 页在同一天存在多条工时记录时只展示最新一条，导致较早记录看起来像消失的问题。
- 修复登录态保存/编辑工时、订阅、项目、凭证和支出时可能覆盖已有 owner 或远端同步身份的问题。
- 修复 owner/deleted 过滤仍有部分列表路径留在内存过滤层，导致登录态本地记录可见性边界不一致的问题。

#### 验证 (Validation)
- `flutter analyze` 通过。
- `flutter test` 通过，当前环境为 `490 passed`。
- `git diff --check` 通过。
- `flutter build apk --debug` 通过。

## [1.4.23] - 2026-06-23

### 项目节点、项目费用与工时出差修复

#### 新增 (Added)
- 应用版本升级到 `1.4.23+29`。
- 项目支持自定义节点，项目概览可维护节点列表。
- 出差、凭证和项目费用支持记录可选项目节点，项目时间线会展示节点信息。
- Supabase 增加项目节点和记录节点字段迁移，兼容旧数据的空值场景。

#### 变更 (Changed)
- 项目详情恢复为四栏结构，项目费用合并到 `凭证` 记录视图，避免五栏拥挤。
- 出差事项中的项目关联保留在 `出差` 表单内，普通工作、请假和休息不显示项目选择。
- 项目费用可从未关联出差中选择候选记录，支持后补关联，不强制自动匹配发票。

#### 修复 (Fixed)
- 修复右下角 `记工时` 在当天已有记录时会打开编辑旧记录、导致新增看起来不生效的问题。
- 修复凭证编辑保存时可能丢失已有 `projectSyncId` 的稳定项目关联问题。
- 补充照片 local-only 边界测试，确保照片不进入项目节点或云同步协议。

#### 验证 (Validation)
- `flutter analyze` 通过。
- 工时、项目、费用、凭证、照片 local-only 和 BUG_TRACKER 相关回归测试通过。
- Android 14 模拟器验证：普通工作表单不显示项目关联，出差表单显示项目关联。

## [1.4.22] - 2026-06-23

### 项目费用与出差关联

#### 新增 (Added)
- 应用版本升级到 `1.4.22+28`。
- `工时-出差` 可关联项目，项目详情时间线和概览会显示关联出差。
- 项目费用可选择关联某条出差记录，并通过稳定的 `trip_work_log_sync_id` 同步。
- 项目费用列表按同项目内相同日期、金额和币种提示 `疑似重复`，只提醒不阻止保存。
- 照片导入保存拍摄时间、来源和可选 GPS 信息，GPS 默认隐藏，可在外观设置中打开。

#### 变更 (Changed)
- 项目详情费用入口统一命名为 `项目费用`。
- 项目时间线可按 `事件日期` 或 `导入日期` 排序。
- 删除项目时会解除关联出差记录的项目关系，不删除工时历史。

#### 修复 (Fixed)
- 凭证解析优先使用识别到的发票/票据日期，识别文本可复制。
- 识别出的购方名称和统一社会信用代码会写入本地备注，并校验统一社会信用代码格式/校验位。
- 修复项目删除和项目费用同步中可能丢失稳定关联关系的数据风险。

#### 验证 (Validation)
- `flutter analyze` 通过。
- `flutter test` 通过，当前环境为 `482 passed`。
- `git diff --check` 通过。

## [1.4.21] - 2026-06-23

### 订阅筛选重大回归修复

#### 变更 (Changed)
- 应用版本升级到 `1.4.21+27`。
- 订阅页筛选空结果现在只在列表区域提示，不再切换到整页空状态。
- GitHub Release APK 下载文件名改为带版本号的 `LifeLog-v1.4.21-...` 格式，后续正式发布会自动使用 tag 写入文件名。

#### 修复 (Fixed)
- 修复点击订阅分类里的“一次性”时，如果该分类暂无内容，会误显示“还没有固定支出”并隐藏分类/排序控件的问题。
- 举一反三检查凭证、项目、记录、项目详情等同类筛选/空状态页面，确认它们的搜索或分类无结果不会隐藏筛选入口。
- 修复正式 Release 资产名只显示应用名和 ABI、无法从下载文件名判断版本号的问题。

#### 验证 (Validation)
- `flutter test test\features\subscription\subscription_ui_test.dart test\features\evidence\evidence_cubit_test.dart test\features\photo\photo_cubit_test.dart` 通过，当前环境为 `29 passed`。
- 发布前验证完成：`dart format --set-exit-if-changed .`、`dart run build_runner build --delete-conflicting-outputs`、`flutter analyze --fatal-infos --fatal-warnings`、`flutter test`、`git diff --check`、旧 module/GetX 扫描、照片 local-only 扫描和 `flutter build apk --debug` 均通过；当前环境全量测试为 `469 passed`。

## [1.4.20] - 2026-06-22

### Android 发布与过度设计削减

#### 新增 (Added)
- 应用版本升级到 `1.4.20+26`。
- 新增公式库生成器路径回归测试，防止生成数据再次写入已退休的 `lib/modules/telemetry_calc` 路径。

#### 变更 (Changed)
- 项目发布目标收敛为 Android APK，移除未维护的 iOS、macOS、Linux、Windows 和 Web 模板目录。
- 移除 Web 占位入口，`lib/main.dart` 直接进入移动端应用入口。
- 移除未使用的直接依赖 `permission_handler`、`geolocator`、`http`、`fl_chart`、`image`，保留仍由其他插件传递使用的依赖。
- `flutter_launcher_icons` 只生成 Android 图标，不再声明 iOS 图标输出。
- WorkLog 首屏按月份读取并缓存日历元数据，减少启动后首屏构建压力。
- 主导航和筛选控件继续收敛到更稳定的四栏结构与固定网格布局。

#### 修复 (Fixed)
- 修复 `tool/generate_formula_library.dart` 仍写入旧 module 路径的问题，避免重新生成后运行时公式库数据保持陈旧。
- 修复启动维护任务阻塞首帧的问题，数据库初始化后将数据维护移动到首帧后执行。

#### 验证 (Validation)
- `flutter pub get --enforce-lockfile` 通过。
- `flutter test` 通过，当前环境为 `468 passed`。
- `flutter analyze` 通过。
- `git diff --check` 通过。
- `flutter build apk --debug --no-pub` 通过。

## [1.4.19] - 2026-06-21

### 架构现代化与同步协议重构

#### 新增 (Added)
- 应用版本升级到 `1.4.19+25`。
- 新增 `IsarDatabase`、分 feature DAO、`SyncEngine`、`SyncAdapter`、同步游标、同步队列和本地冲突记录，为后续模块扩展提供统一边界。
- 新增凭证附件队列和 Supabase migration，附件上传、远端记录和删除确认可独立重试。
- 新增本地匿名数据迁移批次模型，登录后不再自动认领匿名数据，后续迁移必须进入显式用户确认流程。
- 新增 `projectSyncId` 关系字段和迁移，消费/凭证通过稳定项目身份关联，不再依赖可变项目名。
- 新增订阅 anchor date、next due date、end date、status、reminder days 等周期字段，支持更稳定的月/年/自定义账期计算。
- 新增共享 UI 页面模板、章节、指标网格、滑动操作和 `AppTypography`，减少页面级重复组件。
- 新增 `Main CI Test APK` 工作流，合并到 `main` 后自动运行 format、fatal analyze、测试、debug APK 构建、包体报告并上传测试包 artifact。

#### 变更 (Changed)
- `DbService` 保留为兼容 facade，但核心查询逐步委托到 feature DAO，owner/deleted 过滤下沉到 Isar 查询边界。
- 云端创建写入改为按 `(user_id, sync_id)` 幂等 upsert，降低网络抖动后重复插入风险。
- 同步 pull cursor 改为每表独立 `(updated_at, id)` 边界，减少跨表耦合和同 timestamp 漏拉风险。
- 工时数据层支持同一天多条真实记录，统计按聚合结果计算，不再静默删除同日原始记录。
- Release、手动测试包和本地质量门禁统一使用 fatal analyzer、全量测试、包体报告和照片 local-only 扫描。

#### 修复 (Fixed)
- 修复登录/启动同步自动认领匿名本地数据的高风险行为。
- 修复凭证附件上传和删除与凭证行写入耦合导致的孤儿文件/状态不一致风险。
- 修复同步冲突只停留在日志或失败返回中、缺少本地可追踪记录的问题。
- 修复 release 缺少签名配置时可能 fallback 到 debug signing 的发布风险。
- 修复 release/debug 日志和诊断导出中 email、userId、文件路径、Supabase URL、Storage path 脱敏不足的问题。
- 修复本机 Isar 测试只检查仓库根目录 `isar.dll` 导致数据库测试被跳过的问题；现在支持 `ISAR_DLL_PATH` 或 `D:\Tool\Isar\isar.dll`。
- 修复 `v1.4.15` 和 `v1.4.16` GitHub Release workflow 在干净 CI 环境中因 Isar 生成代码格式化顺序错误而失败的问题；现在先检查已提交源码格式，再生成并格式化 `.g.dart` 文件供 analyze/test/build 使用。
- 修复 `v1.4.17` GitHub Release workflow 在 UTC 环境中因日期分组测试写死中国时区边界而失败的问题。
- 修复 `v1.4.18` GitHub Release workflow 在 R8 release shrink 阶段因 ML Kit 可选多语种类缺失而失败的问题，同时继续只打包中文 OCR 依赖。

#### 验证 (Validation)
- `tool/quality_gate.ps1` 通过。
- `dart run build_runner build --delete-conflicting-outputs` 已纳入本地质量门禁，生成代码会在 analyze/test/build 前自动格式化。
- `dart format --set-exit-if-changed .` 通过。
- `flutter analyze --fatal-infos --fatal-warnings` 通过。
- `flutter test` 通过，当前环境为 `443 passed`。
- `git diff --check` 通过。
- 旧 `lib/modules` / GetX 运行时扫描通过。
- 照片 local-only 同步字段扫描通过。
- `flutter build apk --debug` 通过。

## [1.4.18] - 2026-06-21

### 被 1.4.19 取代的发布尝试

- `v1.4.18` tag 已推送，main CI debug APK 已成功，但 GitHub Release workflow 在 R8 release 构建阶段失败，未生成正式 Release APK。
- `1.4.19+25` 包含同一批架构现代化改造，并补齐 ML Kit 可选脚本类的 R8 `dontwarn` 规则后重新发布。

## [1.4.17] - 2026-06-21

### 被 1.4.19 取代的发布尝试

- `v1.4.17` tag 已推送，但 GitHub Release workflow 在测试阶段失败，未生成正式 Release APK。
- `1.4.19+25` 包含同一批架构现代化改造，并修正 UTC CI 环境中的日期分组测试 fixture 后重新发布。

## [1.4.16] - 2026-06-21

### 被 1.4.19 取代的发布尝试

- `v1.4.16` tag 已推送，但 GitHub Release workflow 在格式检查阶段失败，未生成正式 Release APK。
- `1.4.19+25` 包含同一批架构现代化改造，并修正 CI 中 Isar 生成代码的格式化顺序后重新发布。

## [1.4.15] - 2026-06-21

### 被 1.4.19 取代的发布尝试

- `v1.4.15` tag 已推送，但 GitHub Release workflow 在格式检查阶段失败，未生成正式 Release APK。
- `1.4.19+25` 包含同一批架构现代化改造，并补齐生成代码格式和本地门禁后重新发布。

## [1.4.14] - 2026-06-20

### 首页与日期选择体验优化

#### 变更 (Changed)
- 应用版本升级到 `1.4.14+20`。
- 首页聚焦今日记录、快捷操作、待处理事项和最近工时，移除与后续总结重复的月度工时/支出指标。
- 应用内日期选择统一为中文本地化、主题化的日期选择器，覆盖工时、支出、订阅和凭证编辑入口。
- 开发者入口聚焦日志、调试和诊断信息，移除内部 UI Gallery 展示页。

#### 修复 (Fixed)
- 修复首页信息密度过高、指标重复和 `h` 单位中英文混排的问题。
- 修复各功能直接调用默认日期选择器导致样式和中文文案不一致的问题。
- 修复开发者页面暴露内部 UI Gallery 且存在英文混排的问题。

#### 验证 (Validation)
- `tool/quality_gate.ps1` 通过。
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过，当前环境为 `381 passed, 3 skipped`；跳过项为缺少 `isar.dll` 的数据库环境限制。
- `flutter build apk --debug` 通过。
- 当前本机未检测到 Android 真机或模拟器，真实设备烟测仍需在连接设备后补做。

## [1.4.13] - 2026-06-20

### 架构迁移与诊断增强

#### 变更 (Changed)
- 应用版本升级到 `1.4.13+19`。
- 生产入口迁移到 GoRouter / GetIt / Cubit / ChangeNotifier 组合，移除旧 GetX 运行时入口。
- 主导航新增“今天”入口，让日常总览页成为第一主入口。
- 新增本地质量门禁脚本 `tool/quality_gate.ps1`，统一执行 analyze、全量测试、架构扫描、照片 local-only 扫描、debug APK 构建和设备检查，并保存日志。
- 调整 Android/CI 仓库解析顺序，优先使用 Flutter artifact 仓库，Aliyun 仅作为 fallback，避免正式 release 构建因镜像 502 失败。

#### 修复 (Fixed)
- 修复迁移后 About 页面和部分生产符号仍显示旧 GetX 栈的问题。
- 修复诊断导出缺少日志级别统计和最近操作上下文的问题。
- 修复 `v1.4.12` tag release 构建中 Aliyun Maven 502 导致 `x86_64_release` Flutter artifact 无法解析的问题。
- 加固照片 local-only 约束，继续禁止 `PhotoItem` 进入云同步字段和 Supabase 同步路径。

#### 验证 (Validation)
- `tool/quality_gate.ps1` 通过。
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过，当前环境为 `376 passed, 3 skipped`；跳过项为缺少 `isar.dll` 的数据库环境限制。
- `flutter build apk --debug` 通过。
- 当前本机未检测到 Android 真机或模拟器，真实设备烟测仍需在连接设备后补做。

## [1.4.11] - 2026-06-02

### 项目凭证与发票识别增强

#### 变更 (Changed)
- 应用版本升级到 `1.4.11+17`。
- 项目凭证列表改为优先显示消费/出行内容，第二行显示发票或票据里的业务日期时间与类型，不再把导入日期作为列表日期展示。
- 凭证详情新增 PDF/图片/文件预览，并将打开、导出、解析、编辑整理为 2x2 操作区。

#### 修复 (Fixed)
- 修复 PDF 等文件凭证导入后缺少打开/导出入口、内容不可见的问题。
- 修复铁路电子客票识别把站点英文拼音当目的地的问题，支持 `广州站 G5133 阳江北站` 这类同一行版式。
- 修复重新解析凭证时旧的自动解析备注不会被替换的问题。
- 修复项目凭证页在窄屏上显示购买方公司名、导入日期和重复摘要导致信息杂乱的问题。
- 修复多个页面 FAB 默认 hero tag 在真机上可能冲突的问题。
- 修复 `v1.4.10` release 构建中 ML Kit 可选文字识别类缺失导致 R8 失败的问题。

#### 验证 (Validation)
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过。
- `flutter build apk --debug` 通过。
- 真机安装并验证项目凭证页显示 `广州 → 阳江北` 与业务日期 `2026-05-21 12:08`。

## [1.4.9] - 2026-05-31

### Release 构建稳定性修复

#### 变更 (Changed)
- 应用版本升级到 `1.4.9+15`。
- GitHub Actions 安装依赖时强制使用 `pubspec.lock`，并固定到与锁文件一致的 pub / Flutter 镜像，避免 CI 依赖漂移。

#### 修复 (Fixed)
- 修复 `v1.4.8` release 构建中 `flutter pub get` 自动更新锁定依赖后，Android release 构建失败的问题。

#### 验证 (Validation)
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过。
- `git diff --check` 通过。

## [1.4.8] - 2026-05-31

### 工时暗色模式与发布包命名修复

#### 变更 (Changed)
- 应用版本升级到 `1.4.8+14`。
- GitHub Release 和手动测试包上传的 APK 文件改为 `lifelog-...apk`，下载后可直接识别应用。

#### 修复 (Fixed)
- 修复工时页暗色模式下日历状态仅靠小号文字颜色区分，工作、出差、请假和休息不够明显的问题。
- 修复工时记录表单在手动输入时键盘弹起会隐藏底部保存按钮的问题。

#### 验证 (Validation)
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过。
- `git diff --check` 通过。

## [1.4.7] - 2026-05-27

### 项目资料交互统一

#### 变更 (Changed)
- 应用版本升级到 `1.4.7+13`。
- 财务页和项目页的主要新增入口统一为右下角 FAB，减少顶部/底部入口混用。
- 项目详情页的新增按钮跟随当前栏目：照片、凭证、支出分别进入对应添加流程。

#### 修复 (Fixed)
- 修复创建第二个项目时输入提示仍显示“第一个项目”的文案问题。
- 修复项目详情照片多选底部操作在窄屏下容易挤压的问题。
- 修复照片多选模式下系统返回/侧滑直接返回上级页面，而不是先退出选择模式的问题。

#### 验证 (Validation)
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过。
- `git diff --check` 通过。
- GitHub Actions `Build Test APK` debug 构建通过。

## [1.4.6] - 2026-05-27

### Release 构建修复

#### 变更 (Changed)
- 应用版本升级到 `1.4.6+12`。
- 保留 `1.4.5` 中的工时默认月视图和冷启动刷新修复。

#### 修复 (Fixed)
- 修复 GitHub Actions release 构建中 Kotlin Gradle 插件 marker 解析失败的问题，改为直接解析 Kotlin Gradle plugin 模块。

#### 验证 (Validation)
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过。
- `git diff --check` 通过。

## [1.4.5] - 2026-05-27

### 工时启动刷新修复

#### 变更 (Changed)
- 应用版本升级到 `1.4.5+11`。
- 工时页默认打开为月视图，同时保留现有月/周切换。

#### 修复 (Fixed)
- 修复冷启动进入工时页时已有记录可能不显示、必须点击页面后才刷新的问题。
- 加固工时启动/watch/save 数据刷新，避免多个异步加载互相覆盖。

#### 验证 (Validation)
- `dart analyze` 通过。
- `flutter analyze --no-fatal-infos` 通过。
- `flutter test` 通过。
- `git diff --check` 通过。

## [1.4.4] - 2026-05-13

### 修正 Release 内容

#### 修复 (Fixed)
- 应用版本升级到 `1.4.4+10`。
- 恢复 `codex/actions-node24-compat` 测试 APK 中已验证的 UI 与业务内容，修正 `v1.4.2` / `v1.4.3` release 只更新版本与工作流、未包含完整 UI 内容的问题。
- 保留照片本地-only 约束；本次恢复不把 `PhotoItem` 接入云同步管线。

## [1.4.3] - 2026-05-13

### Release 同步

#### 变更 (Changed)
- 应用版本升级到 `1.4.3+9`。
- 补回 `BUG_TRACKER.md` 中遗漏的 2026-05-11 审查发现记录，确保 GitHub 默认分支与本地最新记录一致。

## [1.4.2] - 2026-05-12

### 同步协议加固与导航修复

#### 变更 (Changed)
- 应用版本升级到 `1.4.2+8`。
- 合并 GitHub Actions Node 24 兼容更新，确保 CI 构建环境稳定性。
- 强化工作流与 UI 验证逻辑。

## [1.4.1] - 2026-05-10

### CI 稳定性与工作流加固

#### 变更 (Changed)
- 应用版本升级到 `1.4.1+7`。
- GitHub Actions 迁移至 Node 24 运行时，修复 CI 构建兼容性问题。
- 加固 Life Log 工作流与 UI 验证。

## [1.4.0] - 2026-05-08

### UI 重新设计与同步协议完善

#### 新增 (Added)
- 全新 Material 3 视觉风格，基于 `ColorScheme.fromSeed` 的 Apple-inspired 设计语言。
- 统一的 Design Token 体系：`AppColors`、`AppSemanticColors`、`AppSpacing`、`AppRadius`、`AppMotion`、`AppElevations`。
- 公共组件库：`AppButton`、`AppCard`、`AppTextField`、`AppMetricTile`、`AppSheetScaffold`、`AppFloatingActionPill`、`AppPill`、`AppEmptyState`、`AppSkeleton`、`AppActionSheet`、`AppFilterChipBar`、`AppSafeBottomBar`、`AppLoading`。
- `ConstrainedPage` 响应式布局，支持折叠屏/平板宽屏约束。
- 统计页全面重构：核心指标卡片网格、进度条对比组件、双模式切页动画。
- 支出模块：双维度筛选引擎、拖拽排序守卫、过期账单红色警告高亮。
- 工时模块：周视图日历、复合日志卡片（工作/出差/请假/休息）、农历与空状态界面。
- 设置页：五大层级分组、账号卡片信息强化、开发者入口透明度弱化。

#### 修复 (Fixed)
- 修复 Supabase schema migration 兼容性问题。
- 修复 LifeLog 导航与项目财务流程异常。
- 修复关于页版本号显示。

#### 同步 (Sync)
- 完善 Pull-first-then-Push 同步协议，优化冲突检测与恢复逻辑。
- 强化 SyncService 去抖机制与防重入保护。

#### 验证 (Validation)
- `flutter analyze` 通过。
- `flutter build apk --debug` 通过。
- 真机验证本地模式与云配置模式均可正常启动。

## [1.3.3] - 2026-05-06

### 启动稳定性、云配置与 Apple-inspired UI

#### 新增 (Added)
- 新增 `CloudConfigService`，通过 `--dart-define` 读取 Supabase URL 与 publishable key；缺配置时自动进入本地模式。
- 新增早期启动日志、全局 Flutter/Dart 异常捕获、启动状态记录和诊断信息导出。
- 新增本地 `SyncIdGenerator`，让本地记录创建不再依赖云同步服务。

#### 变更 (Changed)
- 应用版本升级到 `1.3.3+4`。
- 无 Supabase 配置时不再阻断启动；Profile 与登录页会明确显示本地模式或云同步未配置。
- Supabase 初始化、AuthService、SyncService 改为仅在云配置完整时注册。
- `GetMaterialApp` 不再被 `Obx` 包裹，主题切换继续由 `Get.changeThemeMode()` 处理，避免根组件重建。
- 启动同步延后到首帧后执行，降低首屏启动阶段阻塞风险。
- 将 `LogColors` 字段改为非空 `Color`，移除 `day_cell.dart` 中的空断言。
- 删除 `TabsController.visitedTabs` 死代码。
- GitHub Actions release/test APK 构建会校验并注入 Supabase secrets。
- 全局视觉升级为 Apple-inspired 风格：更新主题 token、卡片、按钮、输入框、sheet、空状态、chip、底部 Tab、工时首屏和设置页层次。

#### 修复 (Fixed)
- 修复缺少 Supabase 配置时启动黑屏/启动失败风险。
- 修复部分 Repository 在无云配置时仍尝试调用同步服务的问题。
- 修复 `WorkLogController.loadData()` fire-and-forget 导致异常不可见、loading 状态可能悬挂的问题。
- 修复 `TabsView` 在 `Obx` builder 内写响应式状态的隐患。
- 主题扩展访问增加 fallback，降低缺失 ThemeExtension 时的崩溃风险。

#### 仓库整理 (Maintenance)
- 重写 README，补充功能、运行、云配置、构建和发布说明。
- 删除历史调试输出文件：`analyze.txt`、`doctor_output.txt`、`diff*.txt`。
- 删除本地编辑器工作区文件 `life_log.code-workspace`，并更新 `.gitignore` 防止再次提交。

#### 验证 (Validation)
- `flutter analyze` 通过。
- `flutter build apk --debug` 通过。
- 带 Supabase `--dart-define` 的 debug APK 构建通过。
- 真机 `V2307A` 验证本地模式与云配置模式均可启动，无黑屏；首屏 fully drawn 约 1.6 秒。

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
