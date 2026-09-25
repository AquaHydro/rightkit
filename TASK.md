# 待办

需要人工配合、或者只能在真机上完成的事项。完成后勾选；整组做完就删掉那一节。编号含义见[功能规格](docs/features.md)和[验收](docs/verification.md)。

## 上架前必须完成

- [ ] 提交重新生成的 `RightKit.xcodeproj`：`make generate` 后提交。仓库里的工程还是双渠道改造之前的版本，直接打开会找不到文件。
- [ ] 官网域名：定下后替换 `website/site.json` 的 `url` 和 `download`，以及 `RightKit/Views/Settings/AboutPane.swift` 里商店版「反馈问题」的占位地址 `https://rightkit.example`。
- [ ] 证书：钥匙串里要有 Apple Distribution 和 Mac Installer Distribution 证书（Xcode → Settings → Accounts → Manage Certificates）。
- [ ] 在 App Store Connect 新建 App：bundle ID `app.rightkit.mac.store`，类别「工具」，定价，中英文简介、关键词和截图，隐私问卷（不收集数据；翻译只是打开浏览器），年龄分级。
- [ ] 送审备注：为什么需要授权文件夹；只针对访达的 Apple Events 例外只用于用户确认后重启访达，让扩展生效；怎样在「系统设置 → 通用 → 登录项与扩展」里打开访达扩展；审核人员的演示步骤。
- [ ] `make upload-appstore` 上传，确认通过 App Store Connect 的自动校验。

## 真机验收

- [ ] `V-002`：默认值改过（登录时启动、监视目录、常用目录），需要重跑。
- [ ] `V-004`：欢迎窗口新增了授权行和登录时启动。
- [ ] `V-006`：重启访达，官网版和商店版各一次，包括拒绝自动化授权的情况。
- [ ] `V-080`：文件夹授权，包括重启主程序、重新登录后仍能访问，以及授权失效后的「重新授权…」。
- [ ] `V-081`：发布第一个正式 Release 后，在官网版里确认「有新版本」和「已是最新」两种提示。
- [ ] `V-082`：`make release` 和 `make release-appstore` 的签名检查都通过；两个版本同时安装时设置互不影响。
- [ ] `V-083`：沙盒回归，包括替身、壁纸、文件夹图标、快捷指令、agent 签名校验、后台拉起不开窗口、扩展状态和 `iconutil`。
- [ ] 在 macOS 26 上跑一遍。验收记录里还没有 26 的环境；做不到的话，考虑把最低系统提到 27。

## 官网版发布

- [ ] 第一个 GitHub Release：标签是 `v` 加三段数字（如 `v0.2.0`），不要勾选预发布，上传 `make release` 生成的 DMG。
- [ ] 官网下载按钮指向 `https://github.com/AquaHydro/rightkit/releases/latest`；商店版上架后，旁边放商店链接。

## 已知问题

- [ ] 两个版本同时安装时，系统服务（翻译、二维码）的 `NSPortName` 都是 `RightKit`，可能互相冲突。需要真机确认，必要时按渠道区分。
- [ ] 系统服务的菜单名只写了中文（Info.plist 的 `NSServices`），英文系统下也显示中文。
- [ ] 扩展读取全局 `AppleInterfaceStyle` 判断深浅色，隐私清单按 `CA92.1` 声明。如果审核对此有疑问，改用其他方式取外观。
