# LifeLog v1.4.34 日历与保存回归

工作日期：2026-10-06 至 2026-10-07（UTC）。基线：`90fcce7`（v1.4.33）。用户报告工时日期格呈长椭圆、保存没有成功失败反馈、工时和订阅修改保存缓慢。

工时日期格之前沿用 22dp 卡片圆角与固定 76dp 行高，大字体下行高达到 152dp。现在改用 8dp 圆角，正常字体行高按宽度取 54–64dp；2x 字体为 104–114dp，保留日历信息所需空间。两位日期保持单行并在窄格内缩放，避免大字体换行溢出；农历、节日、假期、记录状态和多条记录标记保留。已用真实 CJK 字体检查浅色、深色 Flutter 截图。

订阅慢保存的明确等待点是本地提交后仍等待整轮 SyncScheduler 云同步。现在保存 Future 只等待本地持久化，后台同步异常被捕获，dirty、远端版本及现有重试协议保留。删除与排序的既有安全流程未改动。工时编辑之前等父页面重新读取才退出，且数据库监听本身已经触发读取；现在提交后立即退出并确认，主工时页由数据库变化刷新。其他调用方的刷新回调独立执行，失败提示明确记录已经保存。

| 缺陷 | 修复与证据 |
| --- | --- |
| U337 / U332 复查 | 实际三栏页面在浅色/深色、320/390dp、1x/2x 字体下检查日期形状和布局。dense DayCell 与完整日历信息测试保留。`soft_tab_ui_test.dart`、`ui_refinement_test.dart`。 |
| U338 | 两个编辑器在底部显示进度、inline 错误；本地提交后关闭并显示三秒成功提示。真实 modal 失败测试确认错误在编辑器内，没有被遮挡的错误 snackbar，重试可保存。`editor_save_responsiveness_test.dart`。 |
| U339 | 本地完成时弹出编辑页与成功提示，父刷新 Future 仍未完成；刷新随后失败时提示“已保存，页面刷新失败”，不改为保存失败。主工时页 watcher 测试验证一次变更只触发一次额外读取。 |
| D64 | 本地写入未完成时保存不返回且不发起同步；本地完成而云请求仍挂起时已返回。云失败/抛异常保留 dirty 与远端版本，本地失败不发云请求。真实订阅编辑页面也验证不等待云完成。 |
| D65 | 保存期间阻止表单点击和草稿变更、禁用保存/删除；Cubit 拒绝重复提交与保存删除重叠，并忽略销毁后的完成。挂起保存、删除和 late-completion 测试通过。 |

历史回归包括订阅跨月日期、结束日期、统计与提醒，工时多条记录、同步 ACK/版本/重试、冲突处理、恢复生命周期、本地照片规则和三栏主题。没有修改模型、数据库 schema、云端迁移或照片同步。

完整质量检查（2026-10-07 UTC）：

- `PUB_HOSTED_URL=https://pub.flutter-io.cn flutter pub get --enforce-lockfile`：通过，锁文件无变更。使用仓库与 CI 的锁定镜像；默认 pub.dev 主机不能满足锁文件的主机约束。
- `flutter test --no-pub --reporter expanded`：781 项全部通过，含 10 项新增保存回归和既有真实 Isar 测试。
- 工时、订阅写入与 UI 专项：126 项通过，已包含在全量测试中。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：No issues found。
- `dart format --output=none --set-exit-if-changed lib test tool`：445 个文件，0 个变更。
- `dart run tool/isar_test_runtime.dart`：Linux x64 真实原生库加载通过。
- `git diff --check`：通过。

测试运行于 Linux、Flutter 3.38.5 / Dart 3.10.4。挂起 Future 的回归证明保存不等待网络请求或父刷新，没有测量 Android 实机毫秒耗时，也未连接生产 Supabase 进行端到端验证；本次没有设备安装。
