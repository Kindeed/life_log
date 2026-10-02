# LifeLog v1.4.32 修复与历史回归审查

基线：`503a7e4`（v1.4.31）。本次版本 `1.4.32+38` 将用户认可的柔和三栏设计迁移到真实 Flutter，修复此前重新打开的同步/恢复/冲突问题，并针对实施中发现的缺口增加行为回归。实际缺陷状态以 `BUG_TRACKER.md` 为准。

## 数据与生命周期验收

| 记录 | 已验证的行为 | 主要证据 |
| --- | --- | --- |
| D43、D44、D45、D49 | 延迟 ACK 保留新编辑/删除及同值回退；账号、会话、数据库切换拒绝旧响应；dirty pull 保留基准版本 | `test/db_service_test.dart`、`test/core/sync/sync_run_context_test.dart`、`test/auth_session_epoch_test.dart` |
| D46、D59 | 五类旧行在请求前持久化身份，重试键迁移保留退避；远端已写入后取消 ACK，再次请求使用同一身份 | `test/db_service_test.dart`、`test/core/sync/sync_queue_test.dart` |
| D41、D54、D58 | 五类实体的本地/远端/复制决策实际更新业务数据；账号/版本/编辑竞争失败保持未解决；副本关系、文件和照片边界正确；旧附件不会撤销选择 | `test/features/sync_center/conflict_resolution_test.dart`：34 项真实 Isar 检查；`sync_operation_gate_test.dart` |
| D50、D52、D53、D56 | 下载路径和 Storage owner 边界；uploading 中断重试；旧 ACK/pull 不覆盖新文件；上传父路径继续等待同步 | `test/evidence_storage_policy_test.dart`、真实数据库和冲突用例 |
| D60 | 五类更新/删除的零基准版本仍发送 CAS 谓词并产生冲突；正版本成功后才 ACK | `test/sync_adapter_http_cas_test.dart`：15 项真实本地 HTTP 请求检查 |
| D13、D47、D48、D55、D57、D61 | 已构造服务和 watcher 恢复后继续可用；在线/离线持久恢复标记、游标失效；损坏候选拒绝；双重失败仍保留恢复快照；统计刷新错误不回滚新编辑 | `test/core/db/`：21 项真实数据库、公共 BackupService 和故障注入检查 |
| T31、D51 | Linux/Flutter tester 加载锁定原生 Isar，缺库失败；冲突账号本地字段生成与 schema 诊断一致 | `tool/isar_test_runtime.dart`、原生库和 release metadata 检查 |

原生测试使用锁定的 `isar_community_flutter_libs 3.3.2`，实际 IsarCore `v0.13.8`。未添加生产云端迁移，未修改项目照片模型或将照片加入同步。

## 界面验收

U329–U334 均有真实 widget 回归：三个主页面共用标题、边距和至少 48dp 操作区域；深浅主题与 320/390dp、1x/2x 字体布局通过；日历保留农历、节日、节气、班休、加班和多条记录，并监听异步日期元数据；月份摘要明确显示累计加班。

项目草稿退出、忙碌防重复提交、移除弹层后迟到成功不关闭父页面、按压时禁用后的恢复、系统减少动态效果和切页状态保留均已验证。U120 的 44×46dp 密集 DayCell 复验通过。

实际字体的六张生产 Flutter 截图已目视检查。两个自包含 HTML 原型通过 20 组 Chromium 检查，其中包含 36 个主题/宽度/三栏组合、滚动/搜索/焦点保持、局部刷新、方向动画、持续复用导航指示器和弹窗 300/240ms 进出；U326–U328 已接受。

## 历史记录复查

本轮对相关实现及完整回归测试重新核对：D13、D27/D29、D41，U120、U266、U268、U275、U289、U293、U296、U297、U302、U303。测试继续覆盖账号与未归属本地数据可见性、编辑身份保存、普通工时重用、多条记录保留、项目关系清除、照片保留与原子级联、订阅删除权限、实体变更追加同步及异步旧列表拒绝。

首次全量执行发现三条旧 DAO 源码断言要求直接 DAO 删除，与新事务中的 owner/context 删除保护不符。已修正这些断言，并保留真实行为验证；未为满足旧断言撤销安全检查。历史 U34 的“一天仅一条记录”已按 ADR 0002 修正为 invalidated，保留 U275 的普通工时编辑行为及历史同日记录。

## 完整质量检查

- `flutter pub get --enforce-lockfile`：通过，锁文件无变更。
- `dart format --output=none --set-exit-if-changed lib test tool`：438 个文件，0 个需要修改。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：No issues found。
- `flutter test --no-pub --reporter expanded`：731 项全部通过，完整执行真实原生数据库测试。
- `git diff --check`：通过。

最终完整测试在上述修复和新增 HTTP 回归稳定后执行。21 项恢复、34 项冲突、15 项 HTTP CAS 等分组计数均已包含在 731 项中，不重复累加。

## 验证范围

本轮完整测试与截图在 Linux 使用 Flutter 3.38.5 / Dart 3.10.4 执行，HTTP 用例连接本地测试服务器。没有连接或安装到含用户数据的手机；未测 Android 真机帧率，也未把本地端口/故障测试当作生产 Supabase 端到端结果。

U308（Supabase Auth 泄露密码保护）仍为 open：当前环境无该项目设置的认证访问，未改远端配置。版本构建使用仓库既有 GitHub Actions 正式签名流程；发布产物和远端执行结果由本次任务另行核实。
