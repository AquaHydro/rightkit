---
version: alpha
name: RightKit
description: macOS 访达右键菜单增强工具的设计规范。最低系统 macOS 26，界面交给系统绘制，品牌只保留图标与珊瑚色。
colors:
  primary: "#ff7973"
  primary-start: "#ff8f6c"
  primary-end: "#ff5175"
  on-primary: "#ffffff"
  accent: "#007aff"
  on-accent: "#ffffff"
  surface: "#ffffff"
  surface-dark: "#1e1e1e"
  surface-sunken: "#f6f6f6"
  surface-sunken-dark: "#282828"
  on-surface: "rgba(0, 0, 0, 0.85)"
  on-surface-dark: "rgba(255, 255, 255, 0.85)"
  on-surface-secondary: "rgba(0, 0, 0, 0.50)"
  on-surface-secondary-dark: "rgba(255, 255, 255, 0.55)"
  separator: "rgba(0, 0, 0, 0.10)"
  separator-dark: "rgba(255, 255, 255, 0.10)"
  error: "#ff383c"
  error-dark: "#ff4245"
  success: "#34c759"
  success-dark: "#30d158"
  warning: "#ff8d28"
  warning-dark: "#ff9230"
  neutral: "#8e8e93"
  neutral-dark: "#98989d"
  ink: "#2a2b31"
typography:
  headline-display:
    fontFamily: SF Pro, PingFang SC
    fontSize: 26px
    fontWeight: 600
    lineHeight: 32px
  headline-lg:
    fontFamily: SF Pro, PingFang SC
    fontSize: 22px
    fontWeight: 600
    lineHeight: 26px
  headline-md:
    fontFamily: SF Pro, PingFang SC
    fontSize: 15px
    fontWeight: 600
    lineHeight: 20px
  row-title:
    fontFamily: SF Pro, PingFang SC
    fontSize: 13px
    fontWeight: 400
    lineHeight: 16px
  label-lg:
    fontFamily: SF Pro, PingFang SC
    fontSize: 13px
    fontWeight: 700
    lineHeight: 16px
  avatar:
    rounded: 9999px
  body-md:
    fontFamily: SF Pro, PingFang SC
    fontSize: 13px
    fontWeight: 400
    lineHeight: 16px
  body-sm:
    fontFamily: SF Pro, PingFang SC
    fontSize: 11px
    fontWeight: 400
    lineHeight: 14px
  label-sm:
    fontFamily: SF Pro, PingFang SC
    fontSize: 10px
    fontWeight: 500
    lineHeight: 13px
  mono-md:
    fontFamily: SF Mono
    fontSize: 12px
    fontWeight: 400
    lineHeight: 16px
rounded:
  sm: 6px
  md: 10px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 20px
  xl: 32px
components:
  button-prominent:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.on-accent}"
    typography: "{typography.body-md}"
    rounded: "{rounded.full}"
  settings-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.row-title}"
    height: 36px
  settings-row-icon:
    rounded: 6px
    size: 24px
  settings-row-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.on-surface-dark}"
  settings-row-caption:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-secondary}"
    typography: "{typography.body-sm}"
  settings-row-caption-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.on-surface-secondary-dark}"
  hash-value:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.mono-md}"
  welcome-title:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.headline-display}"
---

# RightKit 设计规范

本文件遵循 [DESIGN.md 格式](https://github.com/google-labs-code/design.md)：YAML 前置区是给工具和代理读的 token，正文解释为什么这样用。产品行为以 [功能规格](docs/features.md) 为准。资料查阅日期 2026-09-23，来源见文末。

## Overview

RightKit 是一个常驻后台的 macOS 工具：用户几乎只在访达右键菜单里用它，设置窗口一个月打开一两次。设计目标因此只有三条：

1. **菜单快而准。** 右键弹出不能等，只在用户配置的监视目录内出现与当前选择相关的命令。
2. **像系统自带的一样。** 设置、菜单栏、对话框全部用系统组件，让 Liquid Glass、深色模式、强调色、“减少透明度”“增强对比度”、macOS 27 的玻璃透明度滑块都自动生效，不写一行适配代码。
3. **品牌只在该出现的地方出现。** 珊瑚色不进入任何控件。角色 Riko 的立绘只出现在欢迎窗口、扩展状态卡片和「没有监视目录」空状态；关于弹出层用应用图标（Q 版 Riko）。

基线：**最低 macOS 26**，不为更早系统保留回退路径。macOS 27 专属 API（例如 `.reorderable()`、`.confirmationDialog(item:)`）等最低版本提升后再用，在此之前不写 `#available` 分支。

## Colors

**所有界面颜色来自系统语义色**，代码里用 `Color(nsColor: .labelColor)`、`.secondary`、`.separator` 这类语义名，不写色值。前置区的色值是浅色和深色外观下的 sRGB 预览，只用于文档和对比度检查。深色值以 `-dark` 后缀给出。

- **Primary（珊瑚）** `primary` `#ff7973`，渐变从 `primary-start` `#ff8f6c` 到 `primary-end` `#ff5175`。这是品牌色，也是角色的发色，只用于应用图标、欢迎窗口、关于弹出层和对外物料，**不进入任何控件**。
- **Ink（炭灰）** `ink` `#2a2b31`：应用图标底色，也是官网深色区块的 `--ink`。只用于图标、角色头像的底和对外物料，界面背景仍用系统色。对外物料的角色立绘见[品牌角色设定](docs/design/brand-character.md)。
- **Accent（强调色）** 不在 Asset Catalog 里设置 AccentColor。控件用 `Color.accentColor`，跟随用户的系统强调色；前置区的 `accent` `#007aff` 只是“多色”默认下的预览占位。
  - 为什么不用珊瑚当强调色：HIG 允许单色界面把品牌色设为强调色，但白字要在按钮上达到 4.5:1，珊瑚需要压到约 `#e2123d`，这已经和 `systemRed` 几乎相同，而红色在本产品里专指“彻底删除”。同一颜色表达两种意思违反 HIG 的颜色一致性原则。
  - 另外，App 强调色只在用户选“多色”时生效，用户选了别的颜色会被覆盖，自定义强调色的收益本来就小。
- **状态色** 都用系统色，并且永远配文字或符号，不单靠颜色表达：
  - `success` 绿：扩展已启用。
  - `neutral` 灰：扩展未启用或未运行。
  - `warning` 橙：受保护位置提示的符号。
  - `error` 红：只用于失败状态的符号。彻底删除按钮不染红，原因见 Components 的对话框规则。
- **设置行图标块**：每个设置行前一个 24 pt、圆角 6 pt 的实色块，底色是意图色的 `.gradient`，SF Symbol 是白色，和系统设置一样，在浅色和深色下都清楚。意图色与访达菜单同一套（[菜单设计系统](docs/design/menu-system.html)）：创建绿、前往橙、拷贝蓝、移动与发送青、查看灰、外观紫、危险红，代码里是 `Color.intentCreate` 等系统色别名。文件夹、应用、文件类型行直接用访达里的真实图标，不加色块。颜色只是辅助，行标题永远写清含义。
- **对比度**：主文字 `on-surface` 在两种外观下都高于 4.5:1。突出按钮的白字在默认蓝 `#007aff` 上约 4.0:1，这是 Apple 自己的组合，保持原样，由系统在“增强对比度”下处理。`on-surface-secondary` 是 Apple 原值，浅色下约 3.9:1，只用于 11 px 以上的辅助说明，不再调淡。系统色在“增强对比度”下会自动加深，这是不自定义颜色的另一个理由。

## Typography

只用系统字体，代码里用文本样式而不是字号：`.font(.largeTitle)`、`.title2`、`.headline`、`.body`、`.callout`、`.caption`，中文自动落到苹方。前置区的像素值是 macOS 文本样式的标称值，只用于预览。

| Token | SwiftUI | 用途 |
| --- | --- | --- |
| `headline-display` | `.largeTitle` 加 `.semibold` | 欢迎窗口标题 |
| `headline-lg` | `.title2` 加 `.semibold` | 关于弹出层产品名 |
| `headline-md` | `.headline`（对话框标题由系统排版） | 窗口内小节标题 |
| `row-title` | `.body` | 设置行标题，和系统设置同一字号 |
| `label-lg` | `.headline` | 扩展状态卡片标题 |
| `body-md` | `.body` | 设置项、菜单项、按钮 |
| `body-sm` | `.callout` 加 `.secondary` | 设置行说明、分组脚注、路径（`.callout.monospaced()`） |
| `label-sm` | `.caption` | 版本号、文件大小、算法名 |
| `mono-md` | `.body.monospaced()` | 哈希、路径、文件名 |

- 需要逐字核对的内容（哈希、路径）一律等宽并 `.textSelection(.enabled)`。
- 数字变化用 `.monospacedDigit()`，避免跳动。
- 中文不用斜体、不调字距。

## Layout

布局由 `Form(.grouped)`、`List`、系统窗口决定，下面的间距只在极少数自绘位置使用（欢迎窗口、哈希窗口内部）。

- `xs` 4 px：符号与文字；`sm` 8 px：行内元素；`md` 12 px：带边框控件周围的最小留白（HIG 建议约 12 pt）；`lg` 20 px：窗口内容边距；`xl` 32 px：欢迎窗口大块留白。
- **设置窗口**：普通 `Window` 场景，可自由缩放。最小 420 × 360，理想 640 × 620，`.windowResizability(.contentMinSize)`；内容超出时 `Form` 自己滚动，标题栏固定。窗口窄时工具栏放不下的项目由系统收进溢出菜单，不自己做换行。
- **小窗口**（哈希、二维码、欢迎）：`Window` 或 `WindowGroup(for:)`，`.windowResizability(.contentSize)`，内容决定尺寸。不写死窗口尺寸。
- macOS 27 起窗口圆角更紧、工具栏统一在顶部、侧栏延伸到窗口边缘。全部使用系统容器即可自动获得，不要自己画窗口边框或圆角。

## Elevation & Depth

macOS 26 用 **Liquid Glass** 把“功能层”（工具栏、侧栏、菜单、弹出层）浮在“内容层”之上。RightKit 的规则：

- **只用系统组件自带的玻璃。** 设置窗口工具栏、菜单栏菜单、访达菜单都由系统绘制，自动带玻璃。
- **内容层不用玻璃。** `Form`、列表、哈希结果都在标准背景上。HIG 明确说不要在内容层用 Liquid Glass；开关、滑块在被按住时会短暂变成玻璃，这是系统行为，不需要干预。
- **不写自定义 `.glassEffect()`。** 本产品没有悬浮在图片或视频上的控件，也就没有使用 clear 变体的场景。确有需要时用 regular 变体，多个相邻玻璃元素放进同一个 `GlassEffectContainer`，不做玻璃叠玻璃。
- **不提供表面材质开关。** 用户用系统设置里的“减少透明度”，以及 macOS 27 的玻璃透明度滑块自行调整，系统组件会跟着变。
- **不自定义阴影。** 窗口、菜单、弹出层阴影全部由系统绘制；层级靠材质和分组，不靠投影。

## Shapes

- 圆角由系统决定。macOS 26 的控件、分组、窗口圆角彼此同心，自绘形状需要贴合容器时用 `ConcentricRectangle` 或 `.containerShape(_:)`，不要手写半径。
- 前置区的 `rounded` 只给预览用：`sm` 6 px 近似小控件，`md` 10 px 近似分组卡片，`full` 表示胶囊形（macOS 26 的突出按钮）。

## Components

每个组件先写 SwiftUI 原语，再写 RightKit 的规则。能用系统组件表达的，一律不自绘。

### 设置窗口

- 布局参考 magpie 主界面：标题栏左侧是系统红绿灯和标题「RightKit」，中间是分段标签，右侧是图标按钮；下面是一张张分组卡片。全部用系统组件实现：`Window` 加 `.windowToolbarStyle(.unified)`，分段标签是 `ToolbarItem(placement: .principal)` 里的 `Picker(.segmented)`，玻璃由系统绘制。
- 分栏只有五个，窄窗口也放得下：通用、新建文件、打开方式、目录（常用目录和发送到两个分组）、工具箱。「关于」是右上角 `info.circle` 按钮打开的弹出层，不占分栏。
- 窗口标题固定为「RightKit」；重新打开时回到上次的分栏（`@AppStorage` 记住选中项）。
- 每个分栏内是 `Form { Section { … } }.formStyle(.grouped)`：一个分组一张卡片，行间发丝线，分组标题在卡片外。
- 「通用」页自上而下：扩展状态卡片、监视目录、功能、外观（主题、语言、在菜单项中显示图标）、启动与菜单栏（登录时启动、显示菜单栏图标，官网版另有自动检查更新）。决定菜单出不出现的两项放最上面。
- 分组里的按钮位置统一：添加类按钮（添加文件夹…、添加模板…、检测已安装工具、添加应用…）放在分组标题右侧；「恢复默认」放在分组脚注右侧。
- 「重启访达」放在「通用」的扩展状态卡片。「退出 RightKit」只放在菜单栏菜单。设置窗口只放设置。
- RightKit 是 `LSUIElement` 应用，没有 App 菜单，所以打开设置统一走 `openWindow(id: "settings")`，并先激活应用，否则窗口会出现在其他应用后面。用户再次从访达或启动台打开 RightKit 时，直接打开设置窗口。
- 「通用」还显示监视目录列表。首次启动时为空，用户在欢迎窗口授权后才有（功能规格 `F-080`）；用户可添加或移除目录，不能添加 `/` 或系统目录。需要重新授权的行用 `questionmark.folder` 图标和「需要重新授权。」说明，行尾是「重新授权…」。说明文字是「RightKit 仅在这些文件夹及其子文件夹的访达菜单中显示。」

### 设置行

- 行标签统一用 `RowLabel(title:caption:symbol:tint:)`：图标块、`row-title` 标题、可选的 `.callout` 说明。放在 `Toggle`、`Picker` 的标签位置，控件由 `Form` 放在右侧。
- 开关：`Toggle(isOn:) { RowLabel(title: "登录时启动", caption: "让 RightKit 随登录运行，右键操作即点即用。", symbol: "power", tint: .intentCreate) }`。
- 选项：`Picker` 默认菜单样式（主题、语言），和 magpie 的下拉框一致，窄窗口下不会被挤压。分段样式只用于标题栏的分栏。
- 菜单栏菜单里的同一组开关不带图标块，保持系统菜单的样子。
- 可排序列表（新建类型、工具箱）：macOS 26 用 `List` 加 `.onMove`；最低版本提升到 27 后换成 `.reorderable()`。拖动把手、动画都由系统提供。
- 工具箱按访达菜单的五组分成五个分组（拷贝、文件、显示与隐藏、图片与图标、解散与删除），只能组内拖动，设置里的结构就是菜单的结构。
- 空状态：「没有监视目录」时放 Q 版 Riko（资源 `EmptyFolders`，高 96 pt，来自 `feature-empty-error.png`）、说明和「添加文件夹…」。其他空列表只用一行次要文字。
- 禁用：`.disabled(true)`，文字和控件同时变灰；功能组关闭时，其下属设置整体禁用而不是隐藏。

### 扩展状态

- 是否启用只读 `FIFinderSyncController.isExtensionEnabled`，打开设置用 `FIFinderSyncController.showExtensionManagementInterface()`，登录启动用 `SMAppService.mainApp`。已启用和未运行用扩展心跳区分，规则见功能规格。
- 组件 `ExtensionStatusCard`，设置「通用」页和欢迎窗口共用：左侧 56 pt Riko 圆形头像，右侧 `.headline` 状态和 `.callout` 说明，最右一个按钮。
- 头像随状态换表情：已启用 `StatusReady`（比 OK）、未运行 `StatusSleepy`（犯困）、未启用和后台服务已关闭 `StatusPuzzled`（疑惑）。提示词见[品牌角色设定](docs/design/brand-character.md)第 6 条。头像对读屏隐藏，含义全部由文字表达。
- 切换状态时头像淡入淡出（`.transition(.opacity)` 加 `.animation(.default)`），减少动态效果下系统自动收敛。
- 按钮：需要系统设置时是“打开系统设置”，设置页里用 `.borderedProminent`，欢迎窗口里用普通样式（突出样式留给“开始使用”）；其他状态设置页里是“重启访达”，欢迎窗口里不放按钮。

### 菜单栏菜单

- `MenuBarExtra("RightKit", systemImage: …)` 使用默认的菜单样式，不用 `.window` 面板。HIG 要求菜单栏项点开显示菜单而不是弹出面板，除非功能复杂到菜单放不下，RightKit 不属于这种情况。
- 内容自上而下：扩展状态（不可点的文字行）；分隔线；五个功能组开关（`Toggle`，在菜单里显示为勾选项）；分隔线；“设置…”⌘,；“退出 RightKit”⌘Q。
- 是否显示由用户决定。首次启动的欢迎窗口里提供这个开关。菜单栏项随时可能被系统隐藏，任何功能都不能只依赖它。
- 图标用单色模板图像（光标加三条线，来自应用图标发卡层 `badge.png` 的图形），24 pt 菜单栏高度内居中，系统负责着色。

### 访达右键菜单

这是产品的主界面，规则写在 [Finder 菜单](#finder-菜单) 一节。

### 确认对话框

- `.alert` 或 `.confirmationDialog`；对话框外观由系统决定。
- **彻底删除**：标题写清对象和后果（“彻底删除“报告.pdf”？”，多项时“彻底删除 3 个项目？”），正文“此操作无法撤销。”按钮“彻底删除”和“取消”。
  - 用户是主动从菜单选了“彻底删除”，按 HIG，对本来就想执行的破坏性动作**不加 destructive 样式**。
  - 但右键菜单容易误点且不可撤销，所以**不设默认按钮**，让用户必须读完再点；Esc 取消。
  - 确认开关关闭时不弹此对话框。
- **受保护的位置**：这是纯告知，不能继续。标题「受保护的位置」，正文「系统目录与个人主目录无法通过 RightKit 删除。」按钮「好」。
- 可撤销的普通操作（复制到、移动到、新建）不弹确认。
- 按钮文字一到两个词，是动词，不加标点，不解释按钮。

### 哈希窗口

- 从访达触发时 RightKit 没有前台窗口，不能用 sheet。用 `WindowGroup(for: URL.self)` 按文件打开一个小窗口，同一文件重复触发时复用。
- 计算中：`ProgressView` 加“正在计算哈希…”；完成后用 `.animation(.default)` 平滑换成结果，不跳窗口。
- 结果：文件名与大小一行，下面四行 `LabeledContent("SHA-256") { Text(value).monospaced().textSelection(.enabled) }`，顺序固定 MD5、SHA-1、SHA-256、SHA-512，每行一个 `.bordered` 的“拷贝”按钮，点后短暂显示“已拷贝”。
- 计算在主程序后台流式进行、可取消；扩展只发意图。

### 欢迎窗口

- 首次启动时打开一个普通窗口（没有父窗口，所以也不是 sheet），单页，不做多步向导。
- 内容自上而下：Riko 主立绘 160 pt（`CharacterAvatar`：图片自带 `ink` 底色，裁成圆形，外加一圈 `.separator` 发丝线，浅色窗口里圆形底部的白色外套也有边界）；“欢迎使用 RightKit”、一句说明；扩展状态卡片；文件夹授权行；登录时启动和显示菜单栏图标两个开关；“稍后设置”与 `.borderedProminent` 的“开始使用”。
- 文件夹授权行和两个开关放在同一个 `Form(.grouped)` 分组里，用设置行的 `RowLabel`。授权行右侧是普通样式的「授权…」，授权后说明换成文件夹名加「已授权」，按钮换成「更改…」。文案见功能规格 `F-080`。
- 登录时启动开关初始为关，必须由用户自己打开（功能规格 `F-005`）。
- 立绘是静态图，资源 `WelcomeCharacter`（1x 160 px、2x 320 px，从 `website/assets/character/welcome.png` 导出，提示词见[品牌角色设定](docs/design/brand-character.md)第 5 条），不做浮动动画。
- 扩展状态卡片见上文「扩展状态」，放在浅色圆角底上。

### 关于弹出层

- 应用图标 96 pt（`NSApp.applicationIconImage`，即 Q 版 Riko，自动取当前外观的分层图标）、「RightKit」、版本号、标语「右键一下，就办好了。」、一句说明，最下面是链接行。
- 官网版链接行是 GitHub 和「反馈问题」，下面再放一个普通样式的「检查更新…」按钮；商店版链接行只有指向官网的「反馈问题」，没有按钮（功能规格 `F-082`）。
- 之后的功能提示交给 TipKit，不再回到欢迎窗口。

## Finder 菜单

依据 HIG 的菜单与子菜单规则。显示哪些命令见 [功能规格](docs/features.md)。Finder Sync 只在监视目录及其子目录内提供上下文菜单；范围外不插入菜单项。工具栏始终只提供“设置…”。

- **只出现相关命令。** 菜单内容由当前选择决定，不要把全部命令一直摆出来。
- **子菜单只一层。** HIG 建议子菜单超过约五项时考虑拆分。工具箱有 16 个命令，用分隔线分成五组，危险操作永远在最后一组：
  1. 拷贝路径、拷贝名称
  2. 根据文件名新建文件夹、发送替身到桌面、隔空投送、授予写入权限、文件信息（哈希）…
  3. 隐藏 / 显示所选、显示 / 隐藏扩展名
  4. 转换图片…、生成 macOS 图标集、生成 iOS 图标集、设为壁纸、设置文件夹图标…
  5. 解散文件夹、彻底删除…
- **具体事物用真实图标。** 菜单项指向访达里看得到的东西时用它自己的彩色图标：应用用应用图标，新建文件用该文档类型的图标（装了 Office 时 .docx 是 Word 图标），常用目录和复制/移动目标用文件夹在访达里的图标。动作和子菜单标题用 SF Symbol。彩色图标统一 16 pt。
- **外观交给系统。** 访达菜单永远跟随系统外观，应用内「主题」不影响它。菜单项只设 `title`，不用 `attributedTitle` 改颜色；SF Symbol 会被访达压成位图，所以扩展先按当前系统外观（全局 `AppleInterfaceStyle`）涂成菜单文字色，再标记为模板，深色下不会显示成黑色；彩色图标不随浅色 / 深色变化，跟随系统「图标与小组件样式」，与访达里同一文件一致，不自己换图或加底板。
- **图标同组一致。** 一组里要么都有 SF Symbol，要么都没有；“在菜单项中显示图标”关闭时全部隐藏，文字必须自足。
- **命名。** 叶子项用动词短语（拷贝路径），子菜单用名词（工具箱）；需要进一步输入的项加“…”（选择文件夹…、文件信息（哈希）…、彻底删除…）。
- **语言一致。** 模板的菜单名跟随应用界面语言。用户自己命名的模板和文件夹使用用户写的名称。
- **性能。** `menu(for:)` 里只读取 `targetedURL` 和 `selectedItemURLs` 的快照并同步构建菜单，任何文件 I/O、哈希、图片处理都交给主程序。

## Iconography

- **应用图标**：用 Icon Composer 维护。底色是纯色 `ink`，上面两个玻璃图层：角色层 `character.png`（[品牌角色](docs/design/brand-character.md)的 Q 版头像）和发卡层 `badge.png`（光标加三条珊瑚短线）。图层方形、无遮罩，不预先烘焙高光或圆角，阴影和 Liquid Glass 由系统生成。
  - 待办：`icon.json` 还没有深色、Clear、Tinted 外观的专门配置，角色层是全彩位图，需要在 Icon Composer 和真机上检查这几种外观，以及 16、32 px 下发卡是否清晰。
- **界面符号**：全部 SF Symbols。常见动作用系统同款符号（拷贝用 `doc.on.doc`，删除用 `trash`），状态变化用 `.symbolEffect`。
- 不用 emoji，不画自定义图标，除非 SF Symbols 里确实没有对应概念。

## Motion

- 只用系统动画：`.animation(.default)`、`.contentTransition`、`.symbolEffect`。不写自定义弹簧参数。
- 用户开启“减少动态效果”时，系统组件自动收敛；自绘动画需读 `accessibilityReduceMotion` 并改为淡入淡出。
- 菜单弹出不加任何动画或延迟。

## Content & Voice

- 界面语言简体中文优先，English 第二，两套文案同等维护。系统名词沿用 Apple 中文本地化：访达、隔空投送、替身、拷贝、废纸篓。
- 剪贴板动作用“拷贝”，文件传输用“复制到 / 移动到”，不混用。
- 标题、按钮、菜单项不加标点；说明和提示以句号结尾。
- 错误用“无法 + 动作。”：“无法创建文件夹。”对话框标题要具体，不写“错误”。
- 进行中用“正在 + 动作…”：“正在计算哈希…”。省略号用单字符“…”。
- 指引系统设置时逐级写路径：“系统设置 → 通用 → 登录项与扩展”。
- 中英文之间空一格；不用 em dash、感叹号和 emoji。

## System Integration

- **App Intents**：macOS 26 起聚焦可直接执行 App Intents，快捷指令也能用。首批暴露拷贝路径、拷贝名称、新建文件、文件哈希、转换图片、生成 macOS / iOS 图标集、生成二维码、在应用中打开。HIG 限定每个应用最多 10 个 App Shortcuts，按使用频率挑选。彻底删除、解散文件夹不做 Intent，避免绕过确认。
- **文本服务**：翻译和生成二维码注册为系统服务。结果窗口按“哈希窗口”的规则做：没有父窗口时用独立窗口。
- **访达扩展管理**：macOS 15 起访达扩展开关移到“系统设置 → 通用 → 登录项与扩展”，引导文案必须和当前系统路径一致。
- **隐藏文件显示**：不提供 Finder 的全局隐藏文件开关。公开的 Open/Save Panel 配置只影响该面板，不能作为 Finder 全局状态的替代。

## Accessibility

- 使用系统颜色、文本样式和组件，“增强对比度”“减少透明度”“减少动态效果”和 macOS 27 的玻璃透明度滑块都能自动生效。
- 状态永远有文字，不只靠颜色。
- 所有功能可只用键盘完成（完全键盘访问）；不覆盖系统快捷键。
- 角色头像和插画是装饰，对读屏隐藏；它们表达的状态必须同时写成文字。
- 在浅色、深色、增强对比度三种外观下各检查一次设置窗口和哈希窗口；设置窗口还要在最小尺寸和拉宽后各检查一次。

## Do's and Don'ts

- Do 用系统组件，让 Liquid Glass、深色、强调色自动生效。
- Do 让菜单只显示与当前选择相关的命令，并把危险操作放在最后一组。
- Do 给彻底删除确认写清对象和后果，不设默认按钮。
- Do 把珊瑚色和 Riko 留给图标、欢迎窗口、扩展状态卡片、关于弹出层和「没有监视目录」空状态。
- Don't 设置自定义 AccentColor，也不要把珊瑚色用在按钮或开关上。
- Don't 在内容层或列表上加 `.glassEffect()`，不做玻璃叠玻璃。
- Don't 提供表面材质开关，也不为 macOS 26 以前的系统写回退。
- Don't 在访达扩展的菜单回调里做文件 I/O 或计算。
- Don't 把菜单栏做成弹出面板，也不要让任何功能只能从菜单栏进入。
- Don't 在对话框里用“好”确认一个动作，或用“是 / 否”作按钮。

## Sources

- Apple HIG：[Materials](https://developer.apple.com/design/human-interface-guidelines/materials)、[Color](https://developer.apple.com/design/human-interface-guidelines/color)、[The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)、[Menus](https://developer.apple.com/design/human-interface-guidelines/menus)、[Settings](https://developer.apple.com/design/human-interface-guidelines/settings)、[Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)、[App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)、[App Shortcuts](https://developer.apple.com/design/human-interface-guidelines/app-shortcuts)
- [WWDC26 SwiftUI guide](https://developer.apple.com/wwdc26/guides/swiftui/)，[WWDC26 SwiftUI 新特性整理](https://dev.to/arshtechpro/wwdc26-whats-new-in-swiftui-a-developers-breakdown-1333)
- macOS 27 界面变化：[ANI News](https://www.aninews.in/news/tech/mobile/apple-announces-macos-27-golden-gate-at-wwdc-2026-with-liquid-glass-design-changes-and-more20260609002106/)（二手报道，未在官方文档核实）
- [Develop for Shortcuts and Spotlight with App Intents（WWDC25）](https://developer.apple.com/videos/play/wwdc2025/260/)
- [Finder Sync Extensions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)，[directoryURLs](https://developer.apple.com/documentation/findersync/fifindersynccontroller/directoryurls)
- [App Groups Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.application-groups)，[Using the Open and Save Panels](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/UsingtheOpenandSavePanels/UsingtheOpenandSavePanels.html)
- [Finder Sync 扩展在 Sequoia 的设置变化](https://mjtsai.com/blog/2024/10/03/finder-sync-extensions-removed-from-system-settings-in-sequoia/)
- [DESIGN.md 格式规范](https://github.com/google-labs-code/design.md/blob/main/docs/spec.md)
