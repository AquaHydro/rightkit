# App Store 上架资料

商店版（`app.rightkit.mac.store`）在 App Store Connect 里要填的内容。文案里的功能都要能在[功能规格](features.md)里找到出处；功能改了，这里跟着改。

商店描述里不要写「免费」「开源」「GitHub」或官网下载，审核指南 2.3.10 不允许在商店页引导到其他渠道。

## 基本信息

| 项目 | 填写 |
| --- | --- |
| 套装 ID | `app.rightkit.mac.store` |
| SKU | `rightkit-mac` |
| 主要类别 | 工具（Utilities） |
| 次要类别 | 效率（Productivity） |
| 主要语言 | 简体中文，另加英文（美国）本地化 |
| 版权 | `2026 Liao Yiliang` |
| 隐私政策网址 | `https://rightkit.yiliang.app/privacy/`，英文本地化填 `https://rightkit.yiliang.app/en/privacy/` |
| 技术支持网址 | `https://rightkit.yiliang.app/`，英文填 `https://rightkit.yiliang.app/en/` |
| 营销网址 | 同技术支持网址 |
| 价格 | 1 美元（美国区选 1.00 美元的价格点，没有就选 0.99），其他地区按 Apple 自动换算 |

2026-09-25 查询时，Mac App Store 已有两款同类右键工具用了这个名字：「RightKit右键菜单工具」（瑞瑞 宋，2026-07-31 上架）和「RightKit: Right-Click Tools」（泽韦 陈，2026-08-24 上架）。App Store Connect 只拦截完全相同的名称，但同类产品同名容易被判为误导（审核指南 2.3.7、4.1），用户也分不清。

所以商店名用「RightKit: Finder Toolkit」，中文区用「RightKit 访达工具箱」。应用内、图标和官网仍叫 RightKit：审核指南 2.3.8 要求商店名和设备上显示的名称相似，保留 RightKit 前缀就满足。

## 简体中文

**名称**（30 字以内）：RightKit 访达工具箱

**副标题**（30 字以内）：给访达加一个更好用的右键菜单

**推广文本**（170 字以内，随时可改，不用送审）：

右键一下，就办好了。在访达里右键新建文件、把项目复制或移动到常用位置、用终端或编辑器打开，还有 16 个文件小工具。

**关键词**（100 字符以内，逗号分隔，不重复名称）：

```text
右键,右键菜单,访达,新建文件,复制到,移动到,剪切,粘贴,终端,文件工具,图标,哈希,隐藏文件,二维码,效率
```

**描述**：

```text
RightKit 给访达的右键菜单加上新建文件、剪切粘贴、复制到、移动到、用应用打开和一整套文件工具。在哪里右键，就在哪里办好。

新建文件
• 内置 12 种类型：文本、Markdown、RTF、Word、Excel、PowerPoint 等，默认开启常用的几种
• 把任意文件添加为自己的模板
• 重名自动编号，从不覆盖已有文件

剪切、复制到、移动到
• 右键剪切，到另一个文件夹里粘贴，就是移动
• 把常去的文件夹设为「发送到」目标，一步复制或移动过去
• 常用目录直接从右键菜单打开
• 耗时的操作显示进度，随时可以取消

在应用中打开
• 终端打开所在目录，编辑器打开项目本身
• 自动检测终端、Ghostty、Visual Studio Code 和 Xcode，也可以添加其他应用

16 个文件工具
• 拷贝路径、拷贝名称
• 根据文件名新建文件夹、发送替身到桌面、隔空投送、授予写入权限
• 文件信息：MD5、SHA-1、SHA-256、SHA-512
• 隐藏或显示所选项目、隐藏或显示扩展名
• 转换图片（PNG、JPEG、HEIC、TIFF）、生成 macOS 和 iOS 图标集、设为壁纸、设置文件夹图标
• 解散文件夹、彻底删除

不止右键菜单
• 快捷指令和聚焦里也能用常用动作
• 选中文字生成二维码，在本机完成
• 选中文字用 Google 翻译或百度翻译打开

放心用
• 彻底删除前先确认，系统目录和主目录受保护
• 所有操作在你的 Mac 上完成，不收集任何数据
• 运行在 App Sandbox 里，只访问你授权的文件夹
• 右键菜单只在你授权的文件夹里出现

使用前，请在「系统设置 → 通用 → 登录项与扩展」里打开 RightKit 的访达扩展。RightKit 的设置窗口会显示扩展状态，并提供跳转。

支持简体中文和英文，需要 macOS 26 或更高版本。
```

**此版本的新功能**（首发可以不填；需要时）：

```text
RightKit 的第一个 App Store 版本。
```

## English (U.S.)

**Name**: RightKit: Finder Toolkit

**Subtitle**: Better Finder Right-Click Menu

**Promotional Text**:

Right-click. Done. Create files, copy or move items to your favorite folders, open them in Terminal or your editor, and use 16 file tools, right in Finder.

**Keywords**:

```text
right click,context menu,new file,copy to,move to,cut,paste,terminal,hidden files,icon,hash,qr,alias
```

**Description**:

```text
RightKit adds New File, Cut and Paste, Copy To, Move To, Open in App and a full toolbox to the Finder context menu. Right-click where you are, and it's done.

New File
• 12 built-in types, including plain text, Markdown, RTF, Word, Excel and PowerPoint
• Add any file as your own template
• Name conflicts are numbered automatically. Nothing is ever overwritten.

Cut, Copy To, Move To
• Cut with a right-click, then paste in another folder to move
• Pick your go-to folders as Send To targets and copy or move there in one step
• Open favorite folders straight from the context menu
• Long operations show progress and can be canceled

Open in App
• Terminals open the folder, editors open the item itself
• Detects Terminal, Ghostty, Visual Studio Code and Xcode, and you can add other apps

16 file tools
• Copy Path, Copy Name
• New Folder from Name, Make Alias on Desktop, AirDrop, Grant Write Permission
• File Info: MD5, SHA-1, SHA-256, SHA-512
• Hide or show selected items, hide or show file extensions
• Convert images (PNG, JPEG, HEIC, TIFF), make macOS and iOS icon sets, set as wallpaper, set folder icon
• Dissolve Folder, Delete Permanently

Beyond the context menu
• Common actions in Shortcuts and Spotlight
• Make a QR code from selected text, generated on your Mac
• Open selected text in Google Translate or Baidu Translate

Built to be safe
• Delete Permanently asks first. System folders and your home folder are protected.
• Everything happens on your Mac. No data is collected.
• Runs in the App Sandbox and only accesses folders you authorize
• The context menu appears only in folders you authorize

Before you start, turn on the RightKit Finder extension in System Settings > General > Login Items & Extensions. RightKit's Settings window shows the extension's status and takes you there.

English and Simplified Chinese. Requires macOS 26 or later.
```

## App 隐私

- 数据收集：**不收集数据**（Data Not Collected）。
- 依据：商店版没有 `network.client` 权限，不发任何网络请求；翻译只是用浏览器打开网页，由浏览器和翻译网站处理，不算 App 收集。
- 以后接入统计、崩溃上报或任何网络请求，要重新填问卷并更新隐私政策页。

## 年龄分级

所有内容问题都选「无」，也没有无限制网页访问（翻译是在系统浏览器里打开，不是 App 内浏览器），应得到 4+。

## 出口合规

`Info.plist` 已声明 `ITSAppUsesNonExemptEncryption = NO`，上传后不再询问。依据：只用系统提供的哈希算法计算文件摘要，不做加密通信，属于豁免范围。

## 截图

Mac 截图要 16:10，四种尺寸任选其一：1280 × 800、1440 × 900、2560 × 1600、2880 × 1800，最多 10 张，中英文各一套。建议 5 张，按顺序：

1. 右键菜单总览：在访达空白处右键，展开「新建文件」。标题「右键一下，就办好了。」
2. 复制到、移动到：选中文件右键，展开「移动到」，能看到发送到目录。标题「常用的文件夹，一步就到。」
3. 在应用中打开：展开「在应用中打开」，列出终端和编辑器。标题「直接在终端或编辑器里打开。」
4. 工具箱：展开「工具箱」，五组命令都可见。标题「16 个小工具，收在一个子菜单里。」
5. 设置窗口：「通用」页，扩展状态显示「已启用」。标题「状态一目了然。」

用演示账户和测试文件夹截图，不要露出个人文件名。标题文案与官网一致。

## 送审备注（App Review Information → Notes）

审核人员读英文。不需要演示账号，「登录需要」不勾选。

```text
RightKit is a Finder Sync extension that adds file actions (New File, Cut/Paste, Copy To, Move To, Open in App, and a toolbox) to the Finder context menu. No account or network access is needed.

HOW TO TEST
1. Launch RightKit. The Welcome window appears.
2. Click "Authorize…" and choose your home folder (the panel opens there). The context menu only appears inside authorized folders.
3. In the same window, click "Open System Settings". This opens System Settings > General > Login Items & Extensions. Turn on the RightKit Finder extension. The Welcome window's status card updates to show the extension is on.
4. Click "Get Started" to open Settings. If the status says "Finder extension isn’t running", relaunch Finder: hold Option, right-click Finder in the Dock, and choose "Relaunch". The "Restart Finder" button in Settings shows the same instructions.
5. In Finder, open any folder inside your home folder and right-click an empty area. Choose New File > Plain Text. Right-click the new file to try Copy To, Move To, Open in App and Toolbox.

WHY WE NEED FOLDER ACCESS
RightKit runs in the App Sandbox. It creates, copies and moves files only inside folders the user selects in the standard open panel (com.apple.security.files.user-selected.read-write). Access is kept with app-scoped security-scoped bookmarks (com.apple.security.files.bookmarks.app-scope) so the context menu keeps working after a restart. Nothing outside the chosen folders is accessed.

BACKGROUND HELPER
The app bundle contains a small launch agent (registered with SMAppService). It only relays menu commands from the Finder extension to the main app over XPC and does not handle files. It starts on demand when the extension uses it. Launch at login is off by default and only turns on if the user enables it.

PRIVACY
No data is collected. The App Store version makes no network requests. The Translate services only open the translation website in the user's default browser.
```

联系人：Liao Yiliang，邮箱 `contact@yiliang.me`。电话只填在 App Store Connect 里，不写进仓库。

## App 沙盒信息（App Sandbox Information）

商店版没有临时例外，这里不填。0.1.1 (4) 填过的 `com.apple.security.temporary-exception.apple-events` 一行要删掉（审核指南 2.4.5(i) 不批准）。
