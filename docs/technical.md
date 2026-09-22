# 技术调研与复刻方案

调研日期：2026-09-22。安装包事实与新实现建议分别记录。当前尚无恢复的源码，也未创建可运行的新应用。

## 已确认的旧版结构

| 项目 | 证据与结论 |
| --- | --- |
| 主程序 | `com.rightkit.app`，1.0.0 (1)，arm64，最低 macOS 14，`LSUIElement=true` |
| Finder 扩展 | 内嵌 `RightKitFinder.appex`，`com.rightkit.app.finder`，扩展点 `com.apple.FinderSync`，入口 `RightKitFinder.FinderSync` |
| UI / 系统依赖 | 动态链接 SwiftUI、AppKit、FinderSync、ServiceManagement、CryptoKit、CoreImage、ImageIO 等，不能仅凭链接断言某函数如何实现 |
| 主程序权限 | 签名声明 Apple Events automation；未声明 App Sandbox |
| 扩展权限 | 声明 App Sandbox；本次导出的 entitlement 未见 App Groups |
| 签名 | ad hoc，runtime 标志，TeamIdentifier 未设置；注册开发者账号不会自动改变已有安装包签名 |
| 文本服务 | Info.plist 注册 Google 翻译、百度翻译、生成二维码三个 NSStringPboardType 服务 |
| 本地资源 | 中英文文案、12 类模板。未把旧版图标或 Office 模板复制为新版资产 |
| 通信线索 | 二进制含 NSDistributedNotificationCenter、`com.rightkit.ipc.config/command/hello`；这是静态线索，消息结构、验证机制和实际调用尚不明 |

原始导出见 [evidence](evidence/host-info.json)、[权限](evidence/host-entitlements.txt)、[扩展权限](evidence/finder-entitlements.txt)、[链接库](evidence/linked-frameworks.txt)、[通信线索](evidence/ipc-clues.txt)。

## 建议的实现边界（未批准的最终架构）

采用 Xcode 的 macOS App + Finder Sync Extension targets；设置界面使用 SwiftUI，系统窗口、菜单、剪贴板、共享面板等窄范围接入 AppKit。纯数据模型和可测试逻辑放独立 Swift package。最低版本暂以旧版 macOS 14 为基线，玻璃效果通过可用性检查回退。

- **Host**：设置、模板管理、长任务、用户确认、操作结果与权限交互。
- **Finder Extension**：读取当次菜单上下文、生成轻量菜单、发出操作意图。不得在菜单回调中计算哈希或执行大文件 I/O。
- **Core**：菜单可用性、模板描述、操作参数、名称冲突策略、哈希与结果模型。
- **Platform adapters**：文件系统、应用启动、剪贴板、权限、共享和图片处理。

Finder 的 `targetedURL` 与 `selectedItemURLs` 有回调时机限制，应在合法菜单回调或菜单动作中取得快照。不能把空白区域目标目录和选中文件混为一谈。[Apple API](https://developer.apple.com/documentation/findersync/fifindersynccontroller/selecteditemurls())、[Finder Sync 指南](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)。指南为归档资料，当前 SDK 需再次编译验证。

## 第一项技术验证：签名后的扩展通信

先验证正式开发签名的最小闭环：启用扩展 → 在隔离目录生成菜单 → 点击只读命令 → 主程序展示收到的路径 → 设置更改传播回扩展。需要覆盖主程序未运行、扩展重启、旧版同时安装、命令重复、消息过期及权限拒绝。

共享设置优先评估 App Groups；命令传输评估有明确身份边界的 XPC 等机制，必须在实际沙盒和签名条件下验证可行性。不要仅因旧版字符串存在就照搬通知广播，更不能把任意进程发来的路径当作已授权操作。消息应有版本、请求 ID、动作枚举、目标快照、结果和超时。设置持久化要有 schema 版本、原子写入和迁移策略。

## 文件与工具行为设计要求

这些是新实现验收建议，并非已经证明的旧版行为：

| 能力 | 实现方向 | 必须明确的边界 |
| --- | --- | --- |
| 新建 | 克隆有效模板，原子落盘 | 重名、空名称、扩展名、只读目录、自定义模板失效 |
| 剪切 / 复制 / 移动 | 显式操作状态与逐项结果 | 跨卷、重复粘贴、同目录、符号链接、多选部分失败、不静默覆盖 |
| 删除 / 解散文件夹 | 独立确认与受保护位置校验 | 解析真实路径、拒绝危险目标、冲突处理，不能用真实资料试验 |
| 应用打开 | 基于应用标识与 URL 的系统 API；终端适配单独处理 | 应用卸载、空格/引号/换行路径，禁止拼接可执行 shell 命令 |
| 哈希 | 流式读取、后台任务、可取消 | 空文件、大文件、文件变化、无权限；MD5/SHA1仅兼容校验展示 |
| 图片 / 图标 | ImageIO/CoreImage 等候选；对照旧版输出再定规格 | 支持格式、尺寸、透明度、色彩、输出目录待验证 |
| 权限 | 最小权限、明确错误 | “授予写入权限”具体改变哪些位尚未确认，不默认递归提权 |
| 翻译 | 系统文本服务，外部浏览器方案待实测 | 提供方 URL、编码、目标语言及用户文本外发提示待定 |
| 二维码 | 本地生成与 PNG 导出候选 | 空文本、Unicode、长文本、尺寸与容错等级待实测 |

## Apple 开发者账号与发布

开发账号已注册来自用户陈述；未登录或检查证书、Team ID、设备或权限。新 App / extension 的 bundle ID 和显示名应与旧版隔离，保留旧版作为对照。

若选择站外分发，需要 Developer ID 签名、公证和发行包验证；公证不同于 App Review。[Apple 公证说明](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)。若选择 Mac App Store，则需独立验证沙盒权限与功能可行性，不能承诺两条渠道功能天然相同。[Apple 分发签名](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/)。

发布渠道尚未决定。下一阶段先做本地开发签名 PoC；不创建证书、不上传公证、不发布商店、不覆盖 `/Applications/RightKit.app`。确认渠道后再补 entitlements、CI secret 与发布流程。证书私钥、API key、Team 个人配置不得提交 Git。
