# LifeLog v1.4.35 同步及前端效率审查

日期：2026-10-07 UTC。基线：`912e380`（v1.4.34）。用户希望学习 Google 的同步机制，并参考 Muse、ChatGPT 等应用改善前端效率、卡顿和视觉体验。

本轮确认的开销包括逐条同步更新触发整批数据重读、缺少旧请求保护、小封面解码原图和搜索重新计算照片分组。它们是可复现的等待、计算或分配来源；没有实机 trace，不能将用户所有卡顿归因于这些问题，也没有整机 FPS 或速度倍数结论。

## 核对的参考与落地

| 官方来源 | 本轮采用的原则与实际变化 |
| --- | --- |
| [Google：Build an offline-first app](https://developer.android.com/topic/architecture/data-layer/offline-first) | 本地数据是读取来源，网络工作更新本地后再通知 UI。保留本地先保存、持久化队列和既有退避；合并通知并避免加载遮挡，使用索引降低队列查找开销。 |
| [OpenAI：UI guidelines](https://developers.openai.com/plugins/concepts/ui-guidelines) | 按标题、说明、操作安排信息层级，使用一致间距与克制表面。三栏标题置顶，项目概览合并，汇总与搜索、日历对齐，保留系统字体缩放与既有柔和配色。这是 ChatGPT 内嵌应用的官方 UI 指南。 |
| [Meta：How We Designed Muse](https://introducing.muse.ai/) / [用户提供的发布页](https://about.fb.com/news/2026/09/introducing-muse-personal-ai-agent/) | 发布页与设计说明在本轮可以读取。借鉴后台工作减少打断、状态可理解的产品原则：刷新保留已有内容，错误与缓存状态明确可见。没有导入 Muse 品牌资产或复制聊天业务。 |
| [Telegram：Android Redesign](https://telegram.org/blog/crafting-android-design-and-more) | 采用清楚的导航与流畅响应方向。修复程序切栏经过中间页时误改选中目的地，保留滑动、快速连点和系统减少动画设置。 |

先前文档里的设计取向与原型属于历史记录。本轮的上述参考已核对到官方文本，并与生产 Flutter 修改对应；没有运行这些第三方手机 App，也没有从宣传图片推断其内部同步实现。

## 缺陷与验收证据

| 缺陷 | 实际行为与证据 |
| --- | --- |
| D66 | generic 完整刷新在已有增量请求后执行，或升级一个既有排队请求；旧请求抛异常不会丢弃新变更；普通请求 runner 的同步抛错被表示为失败 Future。`sync_scheduler_test.dart`。 |
| D67 | 复用 entityKey 索引，再用精确实体名过滤。800 条无关记录加四条目标记录的真实 Isar 测试验证 owner key、实体类型、名称大小写、失败累计、重建后退避与删除隔离。无 schema 变化。 |
| U340 | 六个 Cubit 的 watcher 首条立即读取，120ms 合并窗口内连续变化最多保留一个后续读取；在途 watcher 读取不重叠，期间的变化不会遗漏。背景刷新不反复进入 loading。订阅手动刷新及失败保留已有页面和记录。 |
| D68 | Project/Photo/Evidence/Expense 增加读取序号；旧成功和旧错误不能覆盖最新成功。六个读取器的旧请求、关闭后完成与刷新取消场景均验证。 |
| U341 | 项目列表复用 PhotoState 分组；搜索/排序复用缓存分组，保留元数据与照片条目。只含照片的项目及旧未绑定照片的关联语义保留。单图和四格封面用 cacheWidth 按物理显示宽度解码。真实页面测试检查 ResizeImage 与宽度上限。 |
| U342 | 程序切栏期间锁定用户目标；中间帧不误选，后续连点以最后目标为准，完成后滑动继续正常，减少动画仍直接切换。 |
| U343 / U344 | 三栏标题先于说明；项目支出与项目/照片计数放入一张柔和面板。截图发现卡片按固有宽度收缩后已修正；真实几何检查保证项目概览与搜索同宽、工时概览与日历同宽。 |

构造压力场景：每个 feature 的首次读取完成后连续发送 100 次变更通知，实际触发两次刷新读取（首条与最后快照），在途 watcher 读取峰值为 1。测试验证最后记录仍可见且没有 loading 状态抖动；首次加载读取不计入这两次。这是读取次数证据，不是 Android 实机速度或帧率测量。持续通知不饿死读取，刷新错误后下一次变化仍可处理。

已有同日汇率保留期间人民币金额不跳回零；后台读取不重复请求已具备的当天汇率，手动刷新仍可重新获取。当天更新失败明确标注缓存，换日后获取失败不会用旧日汇率或虚构 1:1 汇率计入金额。

## 回归与边界

完整质量检查（2026-10-07 UTC）：

- `PUB_HOSTED_URL=https://pub.flutter-io.cn flutter pub get --enforce-lockfile`：通过。
- `flutter test --no-pub --reporter expanded`：818 项全部通过，含 37 项新增回归。
- 同步/feature/UI 专项：200 项通过；之后照片与三栏 CJK 专项 28 项通过，包含新增缓存用例。最终几何修正后的 8 项 CJK 三栏布局测试全部通过。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：No issues found。
- `dart format --output=none --set-exit-if-changed lib test tool`：447 个文件，0 个变更。
- `dart run tool/isar_test_runtime.dart`：Linux x64 原生 Isar 验证通过。
- `git diff --check`：通过。

运行于 Linux、Flutter 3.38.5 / Dart 3.10.4。全量回归在最终几何修正后完成，没有用修正前的运行替代最终结果。

保留当地日期与订阅跨月、日历农历/节日/假期/多条记录、保存成功失败反馈、CAS 版本、owner/session/generation 隔离、冲突处理、删除确认、附件及恢复生命周期。本轮没有修改模型、原图、生产 Supabase 配置或设备安装。

运行依赖版本未升级。测试直接声明既有 fake_async 1.3.3；锁文件仅将其从 transitive 改为 direct dev，版本、主机和校验值保留。

Google 文档中的系统级持久后台任务、网络恢复驱动执行与本项目现有应用内调度是不同层次。本轮未新增 WorkManager、常驻服务或进程外执行器；关闭应用后的持续自动同步不属于本次已验证行为。后续性能核对应先用真实 Android profile trace 测量帧时间、数据库读耗时和图片内存，再决定是否引入系统任务与网络约束，而不是通过并行云写或跳过冲突保护追求表面速度。
