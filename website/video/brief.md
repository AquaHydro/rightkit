# RightKit 产品介绍视频 Brief

给 [guizang-product-video-skill](https://github.com/op7418/guizang-product-video-skill) 用的制作要求。skill 第 1 步要问的问题在下面都已经定好，直接按这份执行，不要再问一遍。只有遇到这里没写到的决定才停下来问。

## 1. 已确定的决定

| 项目 | 决定 |
| --- | --- |
| 仓库 | 本仓库（`AquaHydro/rightkit`），开始前按 `AGENTS.md` 读完它列出的文档 |
| 类型 | **全量产品介绍**，不是版本更新片。RightKit 0.1.1 是第一个公开版本，没有「以前怎样、现在怎样」的对比 |
| `plan.scope` | `{"versions": "0.1.1", "platforms": ["macos-desktop"]}` |
| 平台面 | 只有 macOS 桌面：访达右键菜单（Finder Sync 扩展）加主程序。没有 CLI、移动端和服务端，交付时写明「只展示 macOS 访达里的用法」 |
| 风格 | `repo`：沿用官网的设计（见第 4 节），不用默认的暖白、炭黑样式 |
| 画幅与时长 | 横版 16:9，1920 × 1080，60fps，50 到 60 秒 |
| 语言 | 先做中文版。标题按 skill 的规则，英文短标题和中文标题各一个 span。中文版定稿后，再用 `website/content.json` 里的 `en` 文案做一版英文 |
| 旁白 | 不做，只有配乐和音效。`audioExceptionReason` 不需要填，音乐和音效照常入轨 |
| 结尾链接 | 官网域名还是占位值（`website/site.json` 里的 `rightkit.example`），画面上**不出现网址**。结尾写「免费 · 开源 · 需要 macOS 26 或更高版本」 |
| 工程目录 | `website/video/film/`。用 `--style repo --repo .` 初始化。`node_modules/` 和各类渲染产物加进 `.gitignore`。源码、`plan.json`、`evidence/` 和定稿的成片 MP4（`renders/rightkit-intro-*.mp4`）提交 |

## 2. 产品一句话

RightKit 给 macOS 访达的右键菜单加上新建文件、复制到、移动到、用应用打开，还有一整套文件工具。免费、开源，需要 macOS 26 或更高版本。

标语：**Right-click. Done. / 右键一下，就办好了。**

## 3. 功能事实（feature-evidence）

行为一律以 `docs/features.md` 为准，官网文案在 `website/content.json`。每项都已实现并随 0.1.1 发布。**不要写规格里没有的功能。** `F-003`、`F-052` 明确不做，不要出现。

| 组 | 功能 | 用户得到什么 | 出处 |
| --- | --- | --- | --- |
| 新建 | 在空白处右键，从「新建文件」里选类型，直接在当前文件夹创建 | 不用先开应用再存到这里 | `F-010`、`F-061` |
| 新建 | 内置 12 种类型（默认开 txt、md、rtf、docx、xlsx、pptx），可以把任意文件存成自己的模板 | 常用格式一步建好 | `F-010`、`F-011`、`F-014` |
| 新建 | 重名自动编号，从不覆盖 | 不会误伤已有文件 | `docs/features.md`「新建」一节的重名规则 |
| 复制与移动 | 「复制到」「移动到」列出自己设定的文件夹，最后一项是「选择文件夹…」 | 常用目标一步就到 | `F-031`、`F-032` |
| 复制与移动 | 「常用目录」一键在访达里打开 | 少翻几层文件夹 | `F-030` |
| 复制与移动 | 超过 1 秒的操作显示进度窗口，可以取消 | 大文件也心里有数 | `F-075` |
| 在应用中打开 | 终端打开所在目录，编辑器打开项目本身；首次启动自动找到终端、Ghostty、Visual Studio Code、Xcode | 右键直接进终端或编辑器 | `F-020` 到 `F-023` |
| 工具箱 | 16 个命令收在一个子菜单，只显示和当前选择有关的：选图片时出现转换和图标集，选文件夹时出现解散文件夹 | 菜单不臃肿 | `F-040` 到 `F-057`、`F-061` |
| 放心用 | 彻底删除前先确认 | 误点也来得及 | `F-051` |
| 放心用 | 系统目录受保护 | 不会删坏系统 | `F-073` |
| 放心用 | 只在监视目录里出现（默认是用户主目录） | 不打扰别处 | `F-009`、`F-060` |
| 更多入口 | 聚焦和快捷指令里也能用：拷贝路径、新建文件、文件哈希、转换图片等 9 个动作 | 不止右键 | `F-074` |

编号细节有疑问时回到 `docs/features.md` 核对，不要猜。

## 4. 设计来源（style-audit 的输入）

- **颜色和版式**：`docs/design/website.md` 的「视觉」一节，代码在 `website/src/styles.css`。深色 `--ink #2A2B31`、米白 `--paper #FAF7F5`、品牌珊瑚 `--coral #FF7973`，珊瑚渐变 `#FF8F6C → #FF5175` 只用于大色块和强调。红色只表示「彻底删除」，不拿来装饰。
- **动效**：全片只用一条主曲线 `cubic-bezier(0.16, 1, 0.3, 1)`。进场是上升 24px 加淡入，同组错开 60 到 70ms。菜单展开从光标位置缩放 0.96 到 1，0.18 秒。
- **字体**：英文标题 Nunito 900（`website/public/fonts/nunito-latin.woff2`，OFL，许可证在同目录）。中文用苹方 PingFang SC，在 Mac 上渲染。标签、文件名、快捷键用 Geist Mono（同目录）。每节开头的小标签写成 `// 01  新建` 的样子，编号用珊瑚色。
- **菜单外观**：`docs/design/menu-system.html` 是访达菜单的设计系统。动作用单色线性图标，文件类型、文件夹、应用用彩色小图标。
- **品牌**：应用图标用 `website/public/img/app-icon-512.png`，源文件在 `RightKit/Resources/AppIcon.icon`。
- **角色 Riko**：设定在 `docs/design/brand-character.md`，立绘在 `website/assets/character/`。
  - 开场或首个功能镜头用 `hero-character.png`（她的手指向左，适合指着菜单），结尾用 `cta-character.png`。功能镜头可以小尺寸配 `feature-*.png` 插画。
  - 发色、呆毛、光标菜单发卡三处不能改。**不要水平翻转立绘**，否则发卡方向和小白鼠的珊瑚色右耳会反过来。
  - Riko 的头发和珊瑚底几乎同色，不要把她放在珊瑚色块上，放在深色底加珊瑚光晕上。

## 5. 组件接入：已授权的替代方式

RightKit 是 SwiftUI 主程序加 Finder Sync 扩展，访达的右键菜单由系统绘制，没法在浏览器里导入原组件。按 skill「组件接入」第 5 步，下面的替代方式**已经得到授权**，直接照做，并在 `evidence/component-usage.json` 里逐镜头写明：

1. **访达窗口和右键菜单**：复用仓库里已经实现的网页版本，不要另外手写一套。
   - 结构：`website/src/index.html` 里 `.hero-stage` 下的 `.finder` 窗口
   - 样式：`website/src/styles.css`（`.finder`、`.menu`、`.mi`、`.ric`、`.file`、`.toast`、`.fake-cursor`）
   - 行为：`website/src/main.js` 的 `buildMenu()` 按 `F-061` 生成菜单，`act` 里是各动作的效果（新建进入重命名样式、复制移动时图标飞向侧栏、状态条提示）
   - 演示数据：`website/content.json` 的 `demo` 部分（文件「笔记.md」「季度报告.docx」「封面.png」「项目资料」，侧栏「下载」「桌面」「文稿」）
   - `reuseMode` 写 `website-adapter`，并注明「网页模拟的访达菜单，外观按 menu-system.html」。
2. **设置窗口、进度窗口、哈希窗口**：只能用真实录屏，**不要用网页手绘 SwiftUI 窗口**。我会在 Mac 上录好放进 `website/video/film/recordings/`。没有录屏时先跳过这些镜头，在交付说明里列出来。
3. **不要修改** `website/src/`、`website/assets/` 和应用源码。需要改的样式放在视频工程里覆盖。

## 6. 分镜建议

这是起点，按 skill 的阅读时间和节拍调整。中文说明控制在每秒 6 到 9 个字以内。

| # | 时间 | 类型 | 英文 / 中文标题 | 中文说明 | 画面与动作 | 声音 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 到 3.5s | 品牌 | Right-click. Done. / 右键一下，就办好了。 | | 图标放大出现，外面扩散白色和珊瑚色两圈波纹，字标 `RightKit.` 和标语依次上升 | 开场和弦，图标出现时轻响 |
| 2 | 3.5 到 6s | 字卡 | Your Finder, upgraded / 访达的右键菜单，多了一套工具 | 新建、复制、移动、打开，都在右键里 | 大字卡，深色底 | 转场 whoosh |
| 3 | 6 到 16s | 新建 | New File / 在哪里右键，就在哪里新建 | 在空白处右键，选好类型，文件就建在这个文件夹里 | Riko 在右侧指向窗口。光标右键，进入「新建文件」，点「Markdown」，出现「未命名.md」并进入重命名样式。接着一排 12 种类型标签，再演示重名时自动变成「未命名 2.md」 | 右键 click，菜单展开 tick，新文件 pop |
| 4 | 16 到 26s | 复制与移动 | Copy To · Move To / 常用的文件夹，一步就到 | 选中文件，右键「复制到」，选一个常用文件夹就完成 | 选中「季度报告.docx」，右键「复制到」，选「文稿」，图标飞向侧栏的「文稿」，状态条显示结果。有进度窗口录屏时接一个 2 秒特写 | click，飞行 whoosh，完成 ding |
| 5 | 26 到 34s | 在应用中打开 | Open in App / 直接在终端或编辑器里打开 | 终端打开所在的目录，编辑器打开项目本身 | 选中「项目资料」，右键「在应用中打开」，子菜单里有终端和 Visual Studio Code。旁边一排四个应用图标（`website/assets/apps/`，按 `SOURCES.md` 注明来源） | click，toggle |
| 6 | 34 到 44s | 工具箱 | Toolbox / 16 个小工具，只显示用得上的 | 选图片时出现转换和图标集，选文件夹时出现解散文件夹 | 先选「封面.png」打开「工具箱」，再选「项目资料」打开，对比两份菜单的差别 | 两次 click，切换 sweep |
| 7 | 44 到 50s | 放心用 | Safe by default / 右键很快，也很稳 | 彻底删除前会先确认，系统目录受保护，重名从不覆盖 | 3 张小卡片依次进场，米白底 | 轻柔 resolve |
| 8 | 50 到 56s | 结尾 | Right-click. Done. / 右键，就办好了。 | 免费 · 开源 · 需要 macOS 26 或更高版本 | 与官网下载区相同的布局：左边图标、字标、标语和下载按钮样式，右边 `cta-character.png` 跳起挥手，深色底加珊瑚光晕 | 音乐收束 |

「更多入口」（`F-074`）时长够就在第 7 镜后面加 3 秒，不够就不放。

## 7. 声音

- 配乐按 skill 代码原创，116 到 120 BPM。明亮、温暖、轻快，可爱但不幼稚，和 Riko「开朗、手快、靠得住」的性格一致。主动作贴重拍：右键、新文件出现、飞向侧栏。
- 音效优先贴合 macOS 的质感：干净短促的点击、柔和的菜单展开、有弹性的 pop。不用卡通音效，也不用电子故障音。
- 关键音效出现时压低音乐，最终响度按 skill 的混音规则。

## 8. 约束

- 遵守 `AGENTS.md`：不要读写 `/Applications/RightKit.app` 和已安装 RightKit 的配置；测试和录屏只用临时目录里自己建的文件。
- 画面上的文案不要用 em dash（—）。
- 菜单项名称和应用里的 `Localizable.xcstrings`、`website/content.json` 保持一致，不要自己改写。
- 演示里不出现真实的个人文件名、用户名和路径。演示用户是 `riko`（`/Users/riko/Desktop`），和官网一致。
- 字体只用上面列出的。系统字体只用于在 Mac 上渲染，不打包进仓库。

## 9. 交付

1. `website/video/film/renders/rightkit-intro-zh.mp4`（中文版）
2. 3 到 6 张关键静帧拼成的联系表
3. `plan.json`、`evidence/`（包括 `feature-evidence`、`style-audit.md`、`copy-review.md`、`component-usage.json`、混音报告）
4. 交付说明：哪些已自动检查，哪些实际看过、听过；跳过了哪些镜头及原因（比如缺录屏）；未覆盖的平台面

中文版确认后再做英文版和竖版（9:16）。
