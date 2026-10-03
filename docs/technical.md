# 工程边界

实现 [功能规格](features.md) 时按这里拆分。视觉规则不要写进扩展。

## 目标

最低系统 macOS 26。四个目标：

- `RightKit`：SwiftUI 主程序，`LSUIElement = true`。负责设置、欢迎窗口、确认、哈希和二维码窗口、文件操作、系统服务、App Intents。
- `RightKitFinder`：Finder Sync Extension。只读取当前菜单目标、生成菜单、把动作发给主程序。
- `RightKitAgent`：主程序包内 `Contents/MacOS` 下的命令行程序，签名标识是主程序 bundle ID 加 `.agent`，由 `SMAppService.agent` 注册为 LaunchAgent。只负责持有 XPC 服务名、校验来者并把请求转交主程序，不处理文件。
- `RightKitCore`：Swift package。放菜单规则、命名、保护路径、模板描述和设置模型。不链接 SwiftUI，也不读写磁盘。

## 发布渠道与标识

同一份代码构建两个渠道（`F-082`）：官网版和商店版。两者都启用 App Sandbox，功能差异只靠编译条件 `APP_STORE` 区分，不维护两套分支。只有 `F-081` 检查更新和关于弹出层的链接受这个条件影响；其他任何行为出现渠道差异，都要先写进 `F-082`。

| 标识 | 官网版 | 商店版 |
| --- | --- | --- |
| 主程序 | `app.rightkit.mac` | `app.rightkit.mac.store` |
| 访达扩展 | `app.rightkit.mac.finder` | `app.rightkit.mac.store.finder` |
| agent | `app.rightkit.mac.agent` | `app.rightkit.mac.store.agent` |
| App Group | `Q9C87Z9H4G.app.rightkit.mac` | `Q9C87Z9H4G.app.rightkit.mac.store` |
| XPC 服务名 | App Group 加 `.command` | App Group 加 `.command` |
| 设置变化通知 | App Group 加 `.settings` | App Group 加 `.settings` |
| 激活网址 scheme | `rightkit` | `rightkit-store` |
| 构建配置 | `Debug`、`Release` | `Debug-AppStore`、`Release-AppStore`，scheme `RightKit App Store` |

不要改成 `com.rightkit.app`。所有 target 用同一个开发团队签名。App Group 用团队 ID 前缀而不是 `group.` 前缀：agent 是没有 bundle 的命令行程序，无法嵌入描述文件，而 macOS 15 起 `group.` 前缀的 App Group 需要描述文件授权或从商店安装。

这些标识由构建设置 `RK_APP_ID`、`RK_APP_GROUP`、`RK_URL_SCHEME` 按构建配置决定，写进三个 target 的 Info.plist（键 `RKAppBundleID`、`RKAppGroup`、`RKURLScheme`）和 entitlements。代码经 `ServiceNames` 从 Info.plist 读取，Swift 源码里不写死 bundle ID、App Group 或服务名。agent 的 launchd 配置由构建脚本从 `RightKitAgent/LaunchAgent.plist` 模板生成，文件名是 agent 的 bundle ID 加 `.plist`。

0.1 版官网版的设置在旧的 `group.app.rightkit.mac` 容器里，沙盒版读不到，不做迁移，首次启动按新用户处理。

## 沙盒与文件访问

三个 target 都启用 App Sandbox，entitlements 如下：

- 主程序：`app-sandbox`、`application-groups`、`files.user-selected.read-write`、`files.bookmarks.app-scope`，官网版另有只针对 `com.apple.finder` 的 `temporary-exception.apple-events` 和强化运行时要求的 `automation.apple-events`（`F-001` 重启访达）；App Review 不批准这个临时例外，商店版不带这两项。Info.plist 带 `NSAppleEventsUsageDescription`，英文在 `RightKit/Resources/InfoPlist.xcstrings`。官网版另加 `network.client`（`F-081`）。商店版不加网络权限，用单独的 `RightKit/RightKit-AppStore.entitlements`，两份文件除这些项外保持一致。
- 扩展：`app-sandbox`、`application-groups`。扩展不改文件，也不需要文件权限。
- agent：`app-sandbox`、`application-groups`。XPC 服务名必须是 App Group 的直接子名，扩展和主程序才能在沙盒里查找它。

文件访问（`F-080`）：

- 用户加入监视目录、常用目录或发送到列表的文件夹保存为 security-scoped bookmark（`.withSecurityScope`）。主程序启动时解析全部监视目录、常用目录和发送到的 bookmark，并在整个运行期间保持 `startAccessingSecurityScopedResource()`。解析失败或 bookmark 过期又无法刷新时，标为需要重新授权。目录状态读取保留错误类型，只有明确不存在才显示丢失，权限拒绝或无法确认时仍提供重新授权入口。
- 临时文件夹或图片选择不登记到 `FolderAccess`，只用面板返回的 URL 完成当前操作。长期授权只由加入设置列表的操作保存。
- 扩展传来的 URL 只有落在某个已授权文件夹内时才执行，判断放在命令分派入口的同一处，不在每个命令里各写一遍。
- 沙盒里 `homeDirectoryForCurrentUser`、`URL.homeDirectory`、`URL.desktopDirectory` 指向应用容器。真实主目录用 `getpwuid(getuid())` 取得，桌面等位置由它拼出。`F-009` 和 `F-073` 里的「主目录」都指真实主目录。
- 快捷指令的 `IntentFile` 自带对文件本身的访问权；写到源文件旁边前，同样检查所在文件夹是否已授权。开始访问传入的 security-scoped URL 后再检查目录。系统可能通过不同路径提供同一目录（真机发现 `/.nofollow/Users/...`）；路径不匹配时，用 `FileManager.getRelationship` 确认它与已授权目录相同或位于其中，查询失败则拒绝，不通过删除系统前缀猜测授权。这一步只解析父目录的符号链接，授权目录外指向授权目录的链接本身不算授权；`/` 和按路径匹配时一样，不算授权目录。
- 自定义模板、设置、待粘贴列表和心跳都放在 App Group 容器里。

扩展按系统要求启用 Sandbox，但不在扩展里改文件。

## 谁做什么

主程序：

- 读写设置，并注册登录项。
- 执行全部文件、图片、哈希、分享和删除操作。
- 显示确认、失败提示和结果窗口。
- 打开其他应用时使用系统 API，不拼接 shell。

扩展：

- 在菜单回调里只使用当次的目标文件夹和选中项快照。空白处的文件夹和选中的文件不能混用。
- 可以同步读取体积很小的设置快照。不能在菜单回调里打开用户文件、计算哈希或转换图片。
- 点击命令后把意图发给主程序。主程序没运行时由 agent 启动它，最多等 3 秒；仍不可用就放弃这次点击，不要在扩展里代做。agent 本身不可用时，扩展直接打开主程序，由主程序显示「后台服务已关闭」。
- 每个扩展进程启动时都从共享设置读取监视目录，并写入 `FIFinderSyncController.directoryURLs`。不注册 `/`；没有可用监视目录时注册空集合。

`RightKitCore` 必须能在不打开访达的情况下测试菜单表、重名编号、保护路径和模板名。

## 设置

设置是 App Group 里的一个 JSON 文件，编码使用 `schemaVersion`。当前版本是 `2`（沙盒版新增授权状态，`1` 不迁移）。写入要原子替换。读到无法识别的文件时，把原文件留成备份并使用默认值，不要崩溃。

模型包含：主题、语言、三个启动开关、彻底删除确认、五个功能组、监视目录、新建类型、自定义模板、打开工具、常用目录、发送到、工具箱顺序和开关、欢迎窗口是否已显示。

用户选择的文件夹和应用保存 bookmark 或 bundle ID，不保存可能失效后还继续使用的裸路径。监视目录、常用目录和发送到文件夹不见了，按功能规格显示「该文件夹已不存在。」

扩展在自己的初始化里，向 App Group 写心跳：时间和扩展进程号。文件选择面板也会启动扩展实例并写心跳，面板的宿主退出后这个进程号就失效了，所以每个扩展实例每 5 秒检查一次，发现心跳里的进程已不在就用自己的进程号重写。主程序检查该进程仍在运行且确实是 `RightKitFinder`，以此判断本次登录中扩展是否在运行，区分「已启用」和「未运行」。沙盒不允许向其他进程发信号或调用 `proc_name`，所以用 `sysctl` 的 `KERN_PROC_PID` 读进程名。

菜单性能：监视目录在一次规则构建中只标准化一次；复制到和移动到共用当次目标目录的存在性和显示名查询。扩展用 `MenuRenderer` 构建完整菜单，不复用 `NSMenuItem` 或命令数组。SF Symbol 的位图按当前系统浅深色缓存，外观变化时清空；真实文件、文件类型和应用图标只在同次菜单内复用，下次重新向系统查询。工具栏不读取目标、选择或待粘贴列表。

待粘贴状态只在空白处或单个文件夹、且剪切粘贴开启时查询。`PendingPasteState` 每次检查 App Group 中 `pending.json` 的设备、inode、大小和纳秒修改/变更时间；版本未变时复用“是否非空”，不读取整个列表。文件被原子替换、删除或重新创建后重新读取；失败不缓存，后续可以重试。不缓存用户文件的隐藏状态等选择元数据。

扩展的 `menu-performance` 日志记录初始化，以及每次菜单的选择元数据、待粘贴状态、规则和 AppKit 菜单构建耗时，首个回调标记 `first=true`。耗时不含日志输出、Finder 绘制和系统启动扩展前的等待；日志只有计数、类型和耗时，不增加文件路径。可重复的 Release 基准见 `scripts/perf/run_menu.py`。

主程序修改设置后发出 Darwin 通知「App Group 加 `.settings`」（不带数据）。扩展收到后重读设置并更新 `directoryURLs`。这只是“设置变了”的提醒，不传命令。

## 国际化

`AppLanguage` 是共享设置中的稳定语言标识，原有编码不变；语言代码和原生名称由它统一提供。`L10n` 负责系统偏好匹配、选择共享资源 bundle 和格式化，主程序与 Finder 扩展都通过同一入口获取文案。共享的 `Localizable.xcstrings` 包含简体中文、英文、日文和韩文，不在各视图或扩展中维护翻译分支。

主程序的系统资源保持独立：`Localizable.xcstrings` 提供 App Intents 文案，`AppShortcuts.xcstrings` 提供调用短语，`InfoPlist.xcstrings` 提供权限说明，各语言的 `ServicesMenu.strings` 提供系统服务名称。它们跟随 macOS 的应用语言。翻译服务的网站语言代码在 `TranslationService` 中集中映射，不让视图知道网站的编码差异。

官网使用静态四语内容和共享模板，`website/build.py` 统一生成语言路由、链接与 SEO 元数据；独立 `language.js` 只处理浏览器偏好和手动选择，不耦合演示菜单或样式控制器。`make website-test` 校验全部生成页面和语言控制器的失败场景，并纳入 `make verify`。

`python3 scripts/strings.py check` 检查四种语言的全部 catalog、系统服务键和格式占位符，并逐键核对两个渠道构建产物中的 `.strings`；`add` 更新中英文时保留已有日文、韩文翻译。

## 通信

普通 App 进程不能自己发布带名字的 XPC 服务，只有 launchd 管理的任务可以。因此由主程序包内的 `RightKitAgent` 通过 LaunchAgent 的 `MachServices` 发布名为「App Group 加 `.command`」的本应用专用 XPC 服务。服务名是 App Group 的直接子名，沙盒里的扩展和主程序可以直接查找。agent 按需启动，launchd 只在有人查找这个服务时才运行它，不在登录时自动运行。消息包含 schema 版本、请求 ID、发出时间、动作、目标 URL 列表和可选参数。

- 主程序每次启动都注册 agent（已注册时不重复），然后连接 agent，交出一个匿名 `NSXPCListener` 的 endpoint。agent 把扩展的请求原样转交这个 endpoint。
- 主程序没有交出 endpoint 时，agent 启动主程序，最多等 3 秒。
- 沙盒进程启动其他应用时，系统会丢掉启动参数，所以启动原因用本渠道 scheme 的固定网址表达（`AppURLAction`）：`activate` 把主程序带到前台，`background` 表示 agent 在后台拉起、不开设置窗口，`agent-unavailable` 让主程序打开「通用」页。扩展和 agent 都用 `NSWorkspace.open(_:withApplicationAt:configuration:)` 指定打开自己所在的主程序包，不交给 LaunchServices 挑选同 scheme 的其他副本。网址只有这三个动作，不带命令或路径；主程序忽略其他网址。
- agent 的监听用 `setConnectionCodeSigningRequirement` 只接受签名标识为本渠道的扩展或主程序、且开发团队与 agent 自身一致的进程；主程序的匿名监听只接受本渠道的 agent。团队标识从自身签名读取，不写死。商店版由 Apple 重签，叶证书主题里没有团队标识，此时改认 Mac App Store 签名标记（与 Apple 生成的指定要求一致）。验证失败立即断开。主程序签到被拒或中断后至少等 1 秒再重发，不能空转。
- XPC 方法只接收一个编码后的请求信封和一个结果回复。先检查信封大小、版本和字段类型，再解码 URL；不要把不受信任的数据直接当作路径使用。
- 请求 ID 重复时忽略后到的一条。
- 超过 30 秒的请求拒绝执行。
- URL 必须是文件 URL。拒绝之后，主程序显示该动作自己的失败提示。
- 不要用分布式通知接收命令，也不要执行消息里带来的路径字符串。
- 协作式激活下，访达在前台时主程序自己调用 `activate()` 会被拒绝。会弹出窗口或对话框的命令（`Command.presentsUI`），扩展先打开本渠道的 `activate` 网址（如 `rightkit://activate`），再发送命令。

## 文件操作

重名编号、保护路径判断和「创建前先写临时文件」放在 `RightKitCore` 或主程序的同一处，不要在每个命令里各写一遍。

这些动作必须走同一套编号和失败汇总：新建、自定义模板克隆、复制、移动、粘贴、根据文件名新建文件夹、替身、解散文件夹、图片输出、两种图标集。

永久删除先走保护判断，通过后才删除。保护路径的解析要在删除前完成。

哈希使用流式读取，放在可取消的后台任务里。四个算法的结果类型放在 `RightKitCore`，方便和已知测试向量对照。

图片读取和写出使用 ImageIO。macOS 图标集的 `.icns` 由 `iconutil` 从刚写出的 `.iconset` 生成，参数固定，不把文件名拼进 shell。

不实现 Finder 全局隐藏文件显示开关。`NSSavePanel` 和 `NSOpenPanel` 的隐藏文件选项只影响对应面板，不拿来宣称可以控制 Finder。

内置 Office 模板作为版本控制的资源放在主程序 target 中，不能在运行时从网络下载或依赖机器上安装的 Office 应用生成。测试至少验证包结构、内容类型和不覆盖规则；有对应应用的人工验收再验证打开时不要求修复。

## 系统集成

- 登录项使用 `SMAppService.mainApp`，只在用户打开「登录时启动」后注册（`F-005`，商店审核指南 2.4.5(iii)）。
- 重启访达：先在后台调用 `AEDeterminePermissionToAutomateTarget`（退出事件，允许询问用户）确认自动化授权，再用 `NSRunningApplication.terminate()` 让访达正常退出。它通过 Apple Event 完成，所以需要只针对 `com.apple.finder` 的 Apple Events 临时例外和 `NSAppleEventsUsageDescription`。等访达进程结束后，用 `NSWorkspace.openApplication` 按 bundle ID 重新打开访达。`terminate()` 返回失败或几秒内访达没有退出，按 `F-001` 提示。沙盒会拦截 `forceTerminate()` 发出的信号，所以不再使用它。商店版（`APP_STORE`）不编译这段，只显示手动重启说明。
- 扩展状态使用 `FIFinderSyncController.isExtensionEnabled`。
- 打开扩展设置使用 `FIFinderSyncController.showExtensionManagementInterface()`。
- 文本服务注册 Google 翻译、百度翻译和生成二维码，输入类型是字符串。
- App Intents 只暴露功能规格里的 9 个动作。

## 发布

两个渠道都从同一次提交构建，版本号相同。

官网版：

- 用 Developer ID Application 签名，开启强化运行时，经公证后钉票，打成 DMG，上传到 GitHub 仓库 `AquaHydro/rightkit` 的 Release，标签是 `v` 加版本号。官网的下载按钮指向最新 Release。`make release` 执行签名到打包的流程（`scripts/release/release.sh`），`make release-unsigned` 跳过公证，只用来检查签名。
- 导出方式 `developer-id`，自动签名。`scripts/release/check_signature.sh` 检查三个 target 都开了沙盒、entitlements 与上文一致。
- 公证凭据保存在钥匙串的 notarytool 配置 `RightKit` 里，也可以用 `NOTARY_PROFILE` 换成别的名字。App 专用密码、私钥和 API key 都不进仓库。
- `F-081` 读取 `https://api.github.com/repos/AquaHydro/rightkit/releases/latest`。发 Release 时必须是正式版本、标签是 `v` 加三段数字，否则检查更新会当作失败。解析和比较在 `RightKit/Engine/UpdateCheck.swift`，请求和提示在 `RightKit/Services/UpdateChecker.swift`，两者都包在 `#if !APP_STORE` 里。「自动检查更新」开关、上次检查时间和被跳过的版本只有主程序用，存在主程序的 UserDefaults 里，不进共享设置。

商店版：

- 使用编译条件 `APP_STORE` 和商店版标识构建，导出方式 `app-store-connect`，用 Apple Distribution 签名，导出 `.pkg`。Finder 扩展的 Info.plist 声明 `LSUIElement = YES`，满足 App Store Connect 上传校验。`make release-appstore` 执行归档、导出和检查（`scripts/release/release_appstore.sh`），`make upload-appstore` 在检查通过后上传 App Store Connect，使用 Xcode 里登录的账号。
- 二进制里不能有检查更新的代码、GitHub API 或 Release 下载入口和网络权限。反馈按钮打开邮件 `contact@yiliang.me`。`scripts/release/check_signature.sh <app> appstore` 检查这一点，并和官网版共用标识、沙盒、App Group 和 agent 配置的检查。
- 主程序和扩展各带一份 `PrivacyInfo.xcprivacy`：不跟踪、不收集数据；UserDefaults 用于本应用自己的偏好（`CA92.1`），主程序读取用户选中文件的时间戳用于哈希一致性检查（`3B52.1`）。扩展检查共享待粘贴文件的版本，声明 FileTimestamp 的 `C617.1`；使用 `systemUptime` 测量内部阶段耗时，声明 SystemBootTime 的 `35F9.1`。用到新的需声明原因的 API 时同步更新。
- 商店版收费，官网版免费。商店版的应用内文案和链接都不提官网版或免费下载。
- 送审说明要写清：为什么需要用户授权文件夹；怎样在系统设置里打开访达扩展。

持续集成（`.github/workflows/`，runner 是 GitHub 托管的 `xcode-27`）：

- `ci.yml`：每个 PR 和推到 `main` 时跑 `make verify XCODE_FLAGS="CODE_SIGNING_ALLOWED=NO"`，不签名，只编译、测试两个渠道并做各项检查。生成的工程和提交的不一致时给出警告。
- `release.yml`：推 `v` 开头的标签时发布。先用 `scripts/ci/check_version_tag.sh` 确认标签等于 `v` 加 `MARKETING_VERSION`；官网版跑 `make release`，把 DMG 和 SHA-256 发布到这个标签的 GitHub Release；成功后商店版在 `app-store` 环境里跑 `make upload-appstore`。这个环境只允许 `v*` 标签使用；私有仓库的免费方案不能要求手动批准，上传只会在 App Store Connect 多出一个构建版本，提审和发布仍由用户手动完成。在 Actions 里手动运行 Release 是试运行：两个渠道都完整签名、公证和检查，但不发 Release、不传商店，用来验证签名配置。
- CI 签名用临时钥匙串（`scripts/ci/setup_signing.sh`、`cleanup_signing.sh`）和 App Store Connect API key。钥匙串里只导入 Developer ID Application 和 Apple Development 证书；商店版的 Apple Distribution 和 Mac Installer 证书由 Apple 云端代管，xcodebuild 用 API key 取用。设置了 `ASC_KEY_PATH`、`ASC_KEY_ID`、`ASC_ISSUER_ID` 时，两个发布脚本改用 API key 做自动签名和公证；本机不设置，照旧用 Xcode 账号和钥匙串里的 notarytool 配置。证书和 key 只放在 GitHub secrets 里。
- 发布前在 `project.yml` 里改 `MARKETING_VERSION`，并调高 `CURRENT_PROJECT_VERSION`（App Store Connect 不接受重复的构建号），提交后再打标签。

签名变化：

- 后台项目数据库会记下 agent 注册时的签名约束。换了签名以后，比如从开发签名换到 Developer ID，launchd 会以 `Launch Constraint Violation` 拒绝启动 agent。所以主程序在签到失败或 5 秒内没有签到成功时，先等注销完成，再重新注册一次，然后重新签到。

## 构建与验证入口

第一个实现提交必须包含 Xcode 工程、三个 target 的 entitlements、`RightKitCoreTests` 和一个统一的 `make verify`。该命令至少运行 `xcodebuild test`、`python3 scripts/check_docs.py` 和 `git diff --check`。Finder 真实菜单测试另外记录系统版本、构建提交、监视目录和菜单回调日志，不用单元测试冒充。记录写在 [验收记录](verification-log.md)，可复用的访达脚本在 `scripts/e2e/`。扩展的菜单回调和命令日志用 notice 级别，便于事后取证。
