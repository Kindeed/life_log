# Telegram 公开源码与 LifeLog 优化审查

日期：2026-10-07 UTC。基线：LifeLog v1.4.35（`6626fda`）。目标版本：v1.4.36+42。

## 调研范围

从 [Telegram 官方应用及源码目录](https://telegram.org/apps) 开始，核对 Android / X、iOS、macOS、Desktop、Web A / K、TDLib，补查 Bot API Server、MTProxy、历史 Web / React / Windows Phone。本轮核对 13 个仓库的身份、默认分支与提交；对其中 10 个仓库读取递归源码目录，检查 14 个相关代码文件及 4 个 README。下表将重点入口固定到当时的提交，便于复核。

这是广泛目录核对和针对性能路径的源码阅读，未声称通读所有仓库、所有文件或所有第三方 fork。Telegram 的中央聊天服务端源码未发布（[官方 FAQ](https://telegram.org/faq#q-can-i-get-telegrams-server-side-code)）；公开 Bot API Server 和 MTProxy 是不同组件。没有对不可见服务端的数据库分片、缓存或一致性作实现结论。

| 范围 | 仓库 | 核对的源码 / 提交 | 观察 |
| --- | --- | --- | --- |
| Android | [DrKLO/Telegram](https://github.com/DrKLO/Telegram) | [ImageLoader.java](https://github.com/DrKLO/Telegram/blob/f2908b14133bbffbf7ab04f641ecb5bfaf533242/TMessagesProj/src/main/java/org/telegram/messenger/ImageLoader.java) · `f2908b14133b` | 小图分级缓存、采样解码、专门加载队列；另核对 ButtonBounce 的按压/释放动画。 |
| Android X | [TGX-Android/Telegram-X](https://github.com/TGX-Android/Telegram-X) | [ImageCache.java](https://github.com/TGX-Android/Telegram-X/blob/51a2ba25d3be54b656e4fcf5eea484fdab5820b1/app/src/main/java/org/thunderdog/challegram/loader/ImageCache.java) · `51a2ba25d3be` | 按 bitmap 字节统计 LRU，占用有界。 |
| iOS | [TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS) | [ChatMessageThrottledProcessingManager.swift](https://github.com/TelegramMessenger/Telegram-iOS/blob/6ad963e5b62d354da79040f388ae2b9132fb17b8/submodules/TelegramUI/Sources/ChatMessageThrottledProcessingManager.swift) · `6ad963e5b62d` | 缓存事件 ID、定时合并处理、限制去重集合。 |
| macOS | [overtake/TelegramSwift](https://github.com/overtake/TelegramSwift) | [TableView.swift](https://github.com/overtake/TelegramSwift/blob/579cebbf0c01fd41b712eff3647fa7f69db9665d/packages/TGUIKit/Sources/TableView.swift) · `579cebbf0c01` | 可见区更新与插入/删除/更新的稳定表格状态。 |
| Desktop | [telegramdesktop/tdesktop](https://github.com/telegramdesktop/tdesktop) | [file_download.cpp](https://github.com/telegramdesktop/tdesktop/blob/f23c37857220eb84f8559f0901ea26fb304b564b/Telegram/SourceFiles/storage/file_download.cpp) · `f23c37857220` | 加载生命周期、缓存边界、持有字节的安全性。 |
| Web A | [Ajaxy/telegram-tt](https://github.com/Ajaxy/telegram-tt) | [heavyAnimation.ts](https://github.com/Ajaxy/telegram-tt/blob/28ffcf710b15571e5a2f7bb3bdce3fc90fc8ec80/src/lib/teact/heavyAnimation.ts) · `28ffcf710b15` | 重动画期间推迟非必要工作；另核对 useConnectionStatus 的简洁状态展示。 |
| Web K | [morethanwords/tweb](https://github.com/morethanwords/tweb) | [lazyLoadQueueBase.ts](https://github.com/morethanwords/tweb/blob/125a31da7665d5ee09ceb9c5de66e2615e3276b6/src/components/lazyLoadQueueBase.ts) · `125a31da7665` | 媒体加载并发上限、失效任务清理；另核对 connectionStatus 的状态缓冲与可访问提示。 |
| TDLib | [tdlib/td](https://github.com/tdlib/td) | [NetQueryDelayer.cpp](https://github.com/tdlib/td/blob/42e6a5259551178d1dab54a22ad96d14bd906e20/td/telegram/net/NetQueryDelayer.cpp) · `42e6a5259551` | 指数退避、服务端等待提示、总等待预算与结束时释放任务；另核对 ConnectionStateManager 的去重状态通知。 |
| Bot API Server | [tdlib/telegram-bot-api](https://github.com/tdlib/telegram-bot-api) | [ClientManager.cpp](https://github.com/tdlib/telegram-bot-api/blob/e3e9dd8e5b3d7ab8537cd5a10dc31d5ffa8f82d1/telegram-bot-api/ClientManager.cpp) · `e3e9dd8e5b3d` | 客户端创建限流、retry-after、队列/数据库生命周期。 |
| MTProxy | [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy) | [net-timers.c](https://github.com/TelegramMessenger/MTProxy/blob/f36d8af769ffaeac36978d38c2c0f6d1104c2137/net/net-timers.c) · `f36d8af769ff` | 按截止时间组织的定时器堆；同时核对 README 的代理定位。 |
| 历史 Web | [zhukov/webogram](https://github.com/zhukov/webogram) | [README.md](https://github.com/zhukov/webogram/blob/928731935f36b15a1a886e4be1f3fdec81b6fe7f/README.md) · `928731935f36` | README 明确弃用并指向 Web A/K；仅作为历史目录核对。 |
| 实验 React | [evgeny-nadymov/telegram-react](https://github.com/evgeny-nadymov/telegram-react) | [README.md](https://github.com/evgeny-nadymov/telegram-react/blob/2f372ab6f4bf0495cf1cd56ed8350d64a897d95d/README.md) · `2f372ab6f4bf` | React + TDLib/WASM 的实验客户端；未移植其框架。 |
| 历史 WP | [evgeny-nadymov/telegram-wp](https://github.com/evgeny-nadymov/telegram-wp) | [README.md](https://github.com/evgeny-nadymov/telegram-wp/blob/fd98ac6d18637019218679b81cb92d983019014b/README.md) · `fd98ac6d1863` | 核对仓库身份与提交；README 只有标题，未据此推断实现。 |

所阅读的 GPL/Boost 等项目仅作为机制参考。本轮 Dart 修改自行实现，没有复制第三方源码、品牌资产，或将 Telegram 协议库加入 LifeLog。

## 本轮落地

| 缺陷 | 修改与目的 | 验证路径 |
| --- | --- | --- |
| D69 | 项目保存 / 关联项目确保、费用保存和凭证保存先完成本地提交，再在后台请求现有串行同步。凭证文件复制仍必须先完成；本地失败不能宣告成功。 | `local_save_cloud_latency_test.dart`：延迟本地提交、永不立即完成的云 Future、云失败 / 抛错、本地失败、真实项目 linker 链与附件复制门控。 |
| D70 | 今日工时、今日订阅也使用首条立即 + 窗口合并 watcher；今日工时增加请求序号。后台更新保留内容；旧成功和旧错误均不能替换新快照。 | `sync_refresh_efficiency_test.dart` 增加两个 dashboard，验证通知突发、读取序列、关闭及最终数据。已有订阅换日测试继续执行。 |
| D71 | 订阅批量排序本地提交后只触发一次实体变更同步，由现有 engine 枚举完整 dirty 批次。避免按每条排序记录重复完整 pull/push。 | 100 条修改、一个后台同步调度请求；本地完成不等待云端，失败保留所有 dirty 行，空批次不发请求。 |
| U345 | 项目详情及兼容相册使用共用本地缩略图，按实际 cell 约束与 pixel ratio 解码，fit 策略保持宽高比并限制解码尺寸。全屏放大继续用原图。 | 真实项目照片 Tab 检查 provider；缩略图测试检查两种 cell 尺寸与 3x 密度、源文件字节保持一致。 |
| U346 | 同步状态列表按可见区域惰性构建，队列/冲突稳定 key；刷新保留列表与滚动位置，出错保留最后快照并提供重试。处理中冲突保持 alive，滚走后回来仍禁止重复提交。 | 1000 条任务、刷新失败 / 重试、初次失败、退出后完成、冲突操作滚动回归、深浅色与小屏大字体真实页面测试。 |
| U347 | 轻微按压动画使用 pointer 身份；移动超过系统 touch slop 时释放，不再缩着卡片滚动。其他触点抬起不会错误结束当前按压。 | 滚动继续响应、无误触点击、双触点 / cancel、正常 tap、禁用与减少动画。 |
| U348 | 同步任务用中文实体标题呈现，协议编号和冲突代码保留在显式详情对话框。 | 主列表标题、编号不占首屏、详情信息可查看与选择。 |
| D72 | 真实页面测试复现旧版刷新表达式 callback 返回 Future，触发 Flutter setState 断言；改为同步 void block。 | 初始重试、带记录刷新、冲突成功后的刷新均验证。 |
| U349 | 窄屏大字体汇总改成纵向行；重试时间允许完整换行，信息不再挤在单行省略号后。 | 320px / 2x 深浅色真实截图，状态段落 didExceedMaxLines 为 false。 |

## 参考原则如何对应实现

- Android / X：先限制图片解码和缓存成本，让相册滚动不必为小格子解码整张高分辨率照片。LifeLog 原图和项目照片仍在本地。
- iOS 的批量事件处理：复用 v1.4.35 的串行合并器覆盖遗漏的 dashboard，不让每次 ACK 启动一个完整读取。
- Web A / K 的状态与资源调度：前台交互不等待整轮后台工作；同步状态刷新保持可理解，不用整页空白遮挡。没有照搬其并行媒体请求去并行云端业务写入。
- macOS 表格：让长列表只创建可见项，使用稳定 identity 保留正在处理的冲突状态。
- TDLib / Bot API / MTProxy：请求应去重、限流、按期限等待并有清晰生命周期。LifeLog 已有持久化队列、指数退避和 owner/session fencing；这轮减少重复的完整同步调度，保留这些约束。

## 验证与边界

最终质量检查（Linux，Flutter 3.38.5 / Dart 3.10.4）：

- `flutter test --no-pub --reporter expanded`：851 项全部通过，新增 33 项。本轮最终生产布局修正后重新执行了全量回归。
- 本轮保存、读取、真实 UI 与项目详情专项：63 项通过；最终 CJK / 几何布局修正后四项截图测试通过。正常字号验证三个汇总列等距，大字号验证状态段落没有被截断。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：No issues found。
- `dart format --output=none --set-exit-if-changed lib test tool`：450 个文件，0 个变更。
- 锁定依赖 `flutter pub get --enforce-lockfile`、原生 Isar Linux x64 运行时与 `git diff --check`：通过。

运行全量测试时将 Flutter SDK 的 bin 加入 PATH，让原生测试 resolver 的 `dart` 子进程使用同一 SDK；初次缺少 PATH 的未完成运行没有计作验收或跳过数据库用例。

真实页面截图保存在任务工作区，未将机器生成的截图或下载的 Telegram 源码放进项目。

读次数、调度次数和 widget 构建数量是构造场景证据，不是 Android 实机 FPS / 延迟 / 内存基准。没有运行第三方手机 App 或 LifeLog 实机 profile，没有调用生产 Supabase 写入或部署迁移。

本轮无数据库模型/schema、云端迁移、运行依赖或协议变化。删除仍按远端确认后清理，附件文件复制仍属于本地提交，项目照片仍排除云同步。CAS、旧 ACK、新修改、账号隔离、恢复和冲突保护继续走既有回归。

未引入常驻服务 / WorkManager，因此不新增关闭 App 后持续同步的保证。SyncCenter 的 widget 构建已惰性化，快照读取仍为现有完整队列/冲突读取；未来若实际账户积压很多，应先量化本地查询和分页需要，再改变其应用层契约。
