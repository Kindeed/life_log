# LifeLog v1.4.33 订阅跨月回归

完成日期：2026-10-06。基线：`de1b117`（v1.4.32）。用户确认的症状是“列表一直显示已到期，没有下个月扣费提醒”。原月付费用仍逐月统计，列表和提醒却直接使用历史 `nextPaymentDate`，造成下一期未出现。

本次引入共享纯日历计算，按有效状态、周期、开始与结束日期推导下一次扣费日；展示、提醒及排序使用这一结果，保留原始条目供编辑、删除及排序保存使用。没有日期回写、自动付款、数据库 schema 变化或云端迁移。

| 记录 | 行为与证据 |
| --- | --- |
| U335 | 月付跨月、跨年及多年未打开仍可推导下一期；短月与年付闰年保留 anchor；提醒包含当地当日、遵守每条提醒窗口及派生日期排序；手工提前当期扣费后不会在同月/同年再次出现锚点扣费。`subscription_rollover_test.dart`、`subscription_cubit_test.dart`。 |
| U336 | 已挂载页面每分钟前台检查日期，恢复前台立即检查；同日不重复读取，后台暂停，销毁取消 timer/observer。跨月保存筛选、排序、汇率、加载与失败状态。`subscription_date_refresh_test.dart`、两个 Cubit 测试及实际页面 `subscription_rollover_ui_test.dart`。 |
| D62 / D32 复查 | 包括手工改期在内，月内扣费日期越过 endDate 时不计费；结束日当天仍计费；domain 与 legacy 统计共用计算，避免页面和统计出现不同金额。已暂停/取消/归档、真实结束及一次性/自定义记录不会产生虚构续期。`subscription_rollover_test.dart`。 |
| D63 / U303 复查 | Today 用请求序号拒绝旧成功/旧失败；新日请求完成后，旧日慢读取无法覆盖提醒；系统日期回退时也会使异日在途请求失效。主 SubscriptionCubit 既有读取序号继续生效。`subscription_today_cubit_test.dart`、`subscription_cubit_test.dart`。 |
| U310 / U312 / U322 复查 | 逐条 reminderDays、原币金额与人民币汇率规则、深浅主题和 320dp/2x 字体布局保留；卡片与展开提醒展示新日期，状态文案不将暂停项描述成待扣费。订阅 feature 测试、`ui_refinement_test.dart`、实际跨月 UI 测试。 |

实际 Flutter 页面验证：9 月 1 日的月付订阅，在 9 月 30 日展示“明天扣费”及“10月1日”提醒；已挂载页面跨到 10 月 1 日自动展示“今天扣费”及 10 月预计；10 月 2 日恢复前台后展示 11 月 1 日。验证全过程仓库写操作为零，原始 nextPaymentDate 保持 9 月 1 日。

完整质量检查（2026-10-06）：

- `flutter pub get --enforce-lockfile`：通过，`pubspec.lock` 无变更。
- `flutter test --no-pub --reporter expanded`：771 项全部通过，含 40 项新增回归和真实 Isar 测试。
- 订阅 feature、Today 边界和 UI 专项：114 项通过，已包含在全量测试中。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：No issues found。
- `dart format --output=none --set-exit-if-changed lib test tool`：443 个文件，0 个变更。
- `dart run tool/isar_test_runtime.dart`：Linux x64 真实原生库加载通过。
- `git diff --check`：通过。

测试在 Linux、Flutter 3.38.5 / Dart 3.10.4 执行；没有在含用户数据的设备上安装，也未执行生产 Supabase 端到端检查。
