# 工程边界

实现 [功能规格](features.md) 时按这里拆分。视觉规则不要写进扩展。

## 目标

最低系统 macOS 26。四个目标：

- `RightKit`：SwiftUI 主程序，`LSUIElement = true`。负责设置、欢迎窗口、确认、哈希和二维码窗口、文件操作、系统服务、App Intents。
- `RightKitFinder`：Finder Sync Extension。只读取当前菜单目标、生成菜单、把动作发给主程序。
- `RightKitAgent`：主程序包内 `Contents/MacOS` 下的命令行程序，签名标识 `app.rightkit.mac.agent`，由 `SMAppService.agent` 注册为 LaunchAgent。只负责持有 XPC 服务名、校验来者并把请求转交主程序，不处理文件。
- `RightKitCore`：Swift package。放菜单规则、命名、保护路径、模板描述和设置模型。不链接 SwiftUI，也不读写磁盘。

开发期 bundle ID 使用 `app.rightkit.mac`，扩展使用 `app.rightkit.mac.finder`，App Group 使用 `group.app.rightkit.mac`。不要改成 `com.rightkit.app`。主程序和扩展都启用 App Groups，所有 target 使用同一个开发团队签名；扩展启用 App Sandbox，主程序和 agent 不启用。

主程序不启用 App Sandbox，因为操作目标是用户在访达里点中的任意项目。扩展按系统要求启用 Sandbox，但不在扩展里改文件。不要另外做一套商店沙盒分支。

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

设置是 App Group 里的一个 JSON 文件，编码使用 `schemaVersion`。当前版本是 `1`。写入要原子替换。读到无法识别的文件时，把原文件留成备份并使用默认值，不要崩溃。

模型包含：主题、语言、三个启动开关、彻底删除确认、五个功能组、监视目录、新建类型、自定义模板、打开工具、常用目录、发送到、工具箱顺序和开关、欢迎窗口是否已显示。

用户选择的文件夹和应用保存 bookmark 或 bundle ID，不保存可能失效后还继续使用的裸路径。监视目录、常用目录和发送到文件夹不见了，按功能规格显示「该文件夹已不存在。」

扩展在自己的初始化里，向 App Group 写心跳：时间和扩展进程号。主程序检查该进程仍在运行且确实是 `RightKitFinder`，以此判断本次登录中扩展是否在运行，区分「已启用」和「未运行」。

主程序修改设置后发出 Darwin 通知 `group.app.rightkit.mac.settings`（不带数据）。扩展收到后重读设置并更新 `directoryURLs`。这只是“设置变了”的提醒，不传命令。

## 通信

普通 App 进程不能自己发布带名字的 XPC 服务，只有 launchd 管理的任务可以。因此由主程序包内的 `RightKitAgent` 通过 LaunchAgent 的 `MachServices` 发布名为 `group.app.rightkit.mac.command` 的本应用专用 XPC 服务。服务名以 App Group 标识符为前缀，沙盒里的扩展可以直接查找。消息包含 schema 版本、请求 ID、发出时间、动作、目标 URL 列表和可选参数。

- 主程序每次启动都注册 agent（已注册时不重复），然后连接 agent，交出一个匿名 `NSXPCListener` 的 endpoint。agent 把扩展的请求原样转交这个 endpoint。
- 主程序没有交出 endpoint 时，agent 用 `NSWorkspace` 启动主程序，最多等 3 秒。
- agent 的监听用 `setConnectionCodeSigningRequirement` 只接受签名标识为 `app.rightkit.mac.finder` 或 `app.rightkit.mac`、且开发团队与 agent 自身一致的进程；主程序的匿名监听只接受 `app.rightkit.mac.agent`。团队标识从自身签名读取，不写死。验证失败立即断开。
- XPC 方法只接收一个编码后的请求信封和一个结果回复。先检查信封大小、版本和字段类型，再解码 URL；不要把不受信任的数据直接当作路径使用。
- 请求 ID 重复时忽略后到的一条。
- 超过 30 秒的请求拒绝执行。
- URL 必须是文件 URL。拒绝之后，主程序显示该动作自己的失败提示。
- 不要用分布式通知接收命令，也不要执行消息里带来的路径字符串。
- 协作式激活下，访达在前台时主程序自己调用 `activate()` 会被拒绝。会弹出窗口或对话框的命令（`Command.presentsUI`），扩展先经 LaunchServices 打开 `rightkit://activate`，再发送命令。这个网址只让系统把主程序带到前台，不携带任何命令或路径。

## 文件操作

重名编号、保护路径判断和「创建前先写临时文件」放在 `RightKitCore` 或主程序的同一处，不要在每个命令里各写一遍。

这些动作必须走同一套编号和失败汇总：新建、自定义模板克隆、复制、移动、粘贴、根据文件名新建文件夹、替身、解散文件夹、图片输出、两种图标集。

永久删除先走保护判断，通过后才删除。保护路径的解析要在删除前完成。

哈希使用流式读取，放在可取消的后台任务里。四个算法的结果类型放在 `RightKitCore`，方便和已知测试向量对照。

图片读取和写出使用 ImageIO。macOS 图标集的 `.icns` 由 `iconutil` 从刚写出的 `.iconset` 生成，参数固定，不把文件名拼进 shell。

不实现 Finder 全局隐藏文件显示开关。`NSSavePanel` 和 `NSOpenPanel` 的隐藏文件选项只影响对应面板，不拿来宣称可以控制 Finder。

内置 Office 模板作为版本控制的资源放在主程序 target 中，不能在运行时从网络下载或依赖机器上安装的 Office 应用生成。测试至少验证包结构、内容类型和不覆盖规则；有对应应用的人工验收再验证打开时不要求修复。

## 系统集成

- 登录项使用 `SMAppService.mainApp`。
- 扩展状态使用 `FIFinderSyncController.isExtensionEnabled`。
- 打开扩展设置使用 `FIFinderSyncController.showExtensionManagementInterface()`。
- 文本服务注册 Google 翻译、百度翻译和生成二维码，输入类型是字符串。
- App Intents 只暴露功能规格里的 9 个动作。

## 发布

在官网直接分发，不上 Mac App Store。用 Developer ID Application 签名，开启强化运行时，经公证后钉票，打成 DMG。`make release` 执行整个流程（`scripts/release/release.sh`），`make release-unsigned` 跳过公证，只用来检查签名。

- 导出方式 `developer-id`，自动签名。App Group 用 `group.` 前缀，所以主程序和扩展必须带 Developer ID 描述文件，并由描述文件授权这个 App Group；`scripts/release/check_signature.sh` 会检查这一点。
- 公证凭据保存在钥匙串的 notarytool 配置 `RightKit` 里，也可以用 `NOTARY_PROFILE` 换成别的名字。App 专用密码、私钥和 API key 都不进仓库。
- 后台项目数据库会记下 agent 注册时的签名约束。换了签名以后，比如从开发签名换到 Developer ID，launchd 会以 `Launch Constraint Violation` 拒绝启动 agent。所以主程序在签到失败或 5 秒内没有签到成功时，先等注销完成，再重新注册一次，然后重新签到。

## 构建与验证入口

第一个实现提交必须包含 Xcode 工程、三个 target 的 entitlements、`RightKitCoreTests` 和一个统一的 `make verify`。该命令至少运行 `xcodebuild test`、`python3 scripts/check_docs.py` 和 `git diff --check`。Finder 真实菜单测试另外记录系统版本、构建提交、监视目录和菜单回调日志，不用单元测试冒充。记录写在 [验收记录](verification-log.md)，可复用的访达脚本在 `scripts/e2e/`。扩展的菜单回调和命令日志用 notice 级别，便于事后取证。
