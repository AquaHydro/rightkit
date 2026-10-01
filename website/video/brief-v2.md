# RightKit 产品视频 v2 Brief

给 [guizang-product-video-skill](https://github.com/op7418/guizang-product-video-skill) 用的第二版制作要求。第一版的要求见 [brief.md](brief.md)，成片是 `film/renders/rightkit-intro-zh.mp4`。

这份只写和第一版**不同**的地方。没提到的项目（设计来源、组件接入的替代方式、声音、约束、Riko 的规则）照 [brief.md](brief.md) 第 4、5、7、8 节执行。

## 1. 这一版要做什么

| 项目 | 决定 |
| --- | --- |
| 类型 | 全量产品介绍，配合上架 Mac App Store 发布。仍然不是版本更新片 |
| 版本 | `0.1.2`，官网版与商店版（商店名「RightKit 右键工具箱」/ `RightKit: Context Menu Toolkit`） |
| 画幅与时长 | 横版 1920 × 1080，60fps，55 到 65 秒 |
| 新手法 | 用 Medio Gen 生成的 AI 镜头做角色动画和氛围空镜，界面镜头仍用代码动画（见第 3 节分工） |
| 工程目录 | 沿用 `website/video/film/`，AI 素材放 `film/ai-clips/`（只提交成片用到的 mp4，其余只留提示词和联系表） |
| 结尾网址 | 可以出现：`rightkit.yiliang.app` |

## 2. 比第一版多出来的内容

都已实现，行为以 `docs/features.md` 为准。

| 内容 | 用户得到什么 | 出处 |
| --- | --- | --- |
| 上架 Mac App Store | 两种拿法：官网免费开源，商店版中文区 ¥8、自动更新 | `F-082`、`website/content.json` 的 pricing |
| 欢迎窗口与文件夹授权 | 只碰你授权过的文件夹，重启后依然有效 | `F-080`、`V-004` |
| 二维码 | 本机生成，不上传文本 | `F-070` |
| 翻译服务 | 选中文字，用 Google 或百度翻译打开 | `F-071` |
| 聚焦与快捷指令 | 9 个动作，不止右键 | `F-074` |
| 两个渠道都在 App Sandbox 里 | 安全感 | `F-080`、`F-082` |

`F-081` 检查更新只在官网版有，片中不单独展示。

## 3. AI 镜头与代码镜头的分工

**界面一律不用 AI 生成。** AI 视频会把菜单文字、文件名画错，也不符合商店对真实展示的要求。

| 镜头 | 做法 |
| --- | --- |
| 访达菜单、设置、欢迎窗口、进度窗口、二维码窗口 | 代码动画或真实录屏，照 brief.md 第 5 节 |
| Riko 出场、指向、结尾挥手 | Medio Gen 图生视频，首帧用现有立绘 |
| 开场空镜、转场、安全感意象 | Medio Gen 先生图再图生视频 |
| 品牌落版、结尾文字 | 代码 |

AI 只生成 Riko，不生成场景、光效和界面。成片里有 AI 动画的镜头：开场 Q 版按右键 4 秒、新建镜头里 Riko 指向 6 秒、放心用里 Q 版抱文件夹 5 秒，都和真实界面或文案同屏。

### 第二轮结论：画风要从官方素材出发（2026-09-26）

第一轮的写实光标和玻璃护盾空镜被否掉了，原因是和项目画风违和。可行的做法是两步走：

1. 用 gpt-image 的改图（`edit_image`）生成新插画：提示词用 `docs/design/brand-character.md` 的固定风格段落加 Q 版模板，参考图固定带 `RightKit/Resources/AppIcon.icon/Assets/character.png` 和两张现有 Q 版插画，透明底，1024 × 1536。
2. 把插画合成到 `#2A2B31` 的 16:9 底上，再交给 Grok 图生视频。提示词写明 `Flat 2D chibi anime animation ... Keep the exact same flat vector-like art style ... Static camera, no zoom, no lighting change, no glow, no 3D, no new objects, no text.`

Grok 能守住扁平 Q 版的画风和角色特征，但守不住画面里的小图标（会变形）。带图标的插画只用静态图加代码动画。

### 已验证的 Grok 图生视频规律（2026-09-26 试片）

- **输出比例跟随首帧，`aspect_ratio` 参数被忽略。** 直接用竖版立绘会得到 1248 × 1664 的竖片。要 16:9，先把立绘合成到 1920 × 1080 的 `#2A2B31` 底上再生成：
  ```sh
  ffmpeg -f lavfi -i color=c=0x2A2B31:s=1920x1080 -i ../../../assets/character/hero-character.png \
    -filter_complex "[1]scale=-1:1000[c];[0][c]overlay=W-w-80:H-h" -frames:v 1 frame-point-16x9.png
  ```
- 输出是 1920 × 1088、24fps、带一条无用的音轨。剪辑时裁到 1080，去掉音轨。
- 首帧是纯色底时，底色能基本保住（`#2A2B31` 变成约 `#20212A`，略暗）。成片里给外层容器加 `mix-blend-mode: lighten`，更暗的底色自动消失，舞台的网格照样透出来。注意混合模式要加在带遮罩或位移的外层元素上，加在里面的 `<video>` 上会被隔离、不起作用。首帧是白底时，模型会自己换成近黑的 `#171213`，不要这样做。
- 角色设计（发卡、呆毛、小白鼠、铅笔）在 6 秒内保持稳定。写提示词时要写 `keep her outfit, hair color and hair clip exactly the same`。
- 给首帧留出空白区域，并在提示词里写 `keep the left side of the frame empty`，空白区能保住，可以直接叠菜单。

### 素材清单

| 文件 | 首帧 | 状态 |
| --- | --- | --- |
| `ai-clips/riko-point-16x9.mp4` | `frame-point-16x9.png`（hero 立绘在右，左侧留白） | 用于新建镜头，已入库 |
| `ai-clips/chibi/shield.mp4` | `chibi/frame-shield-16x9.png` | 用于放心用，已入库 |
| `ai-clips/chibi/press.mp4` | `chibi/frame-press-a.png` | 开场按右键，只用前 1.85 秒，已入库。首尾帧模式 Grok 返回 400，`press-b.png` 未用 |
| `ai-clips/riko-wave-flat.mp4` | `frame-wave-16x9.png` | 结尾挥手，已入库 |
| `ai-clips/chibi/juggle.png` | 更多入口的静态插画 | 已用 |

写实空镜（光标、护盾）、竖版和方形的 Riko、带光晕的挥手、Q 版按鼠标初版、抛接动画都已否掉并删除，只留下联系表 `*-sheet.png` 作为记录。

### 提示词

所有提示词都用英文，结尾都带 `no text`。

**Riko 指向（已用，图生视频）**
```
The anime girl on the right smiles and points to the left with a light, cheerful bounce, her hair sways softly and the small white mouse on her shoulder blinks. Keep the flat dark charcoal background exactly as it is, keep the left side of the frame empty. Static camera. Smooth clean 2D anime animation, no text, no extra objects. Keep her outfit, hair color and hair clip exactly the same.
```

**Riko 结尾挥手（图生视频，首帧：cta 立绘放在 16:9 深色底右侧）**
```
The character on the right waves goodbye cheerfully and gives a small nod, gentle hair movement, a soft coral glow slowly appears behind her. Keep the flat dark charcoal background, keep the left side of the frame empty. Static camera. Smooth clean 2D anime animation, no text. Keep her design exactly the same.
```

**开场空镜关键帧（文生图）**
```
A minimalist dark charcoal scene (#2A2B31), a single glowing coral mouse cursor floating in the center, soft volumetric coral light spreading from the cursor, fine dust particles, cinematic shallow depth of field, premium product film style, no text, no UI windows. 16:9.
```
接着用它做图生视频：
```
The coral cursor slowly pulses and a soft ripple of light expands outward, as if clicked. Particles drift. Very slow camera dolly forward. Calm, premium, no text.
```

**复制与移动的转场（文生图，再图生视频）**
```
Stylized 3D paper document icons flying in an elegant arc into softly glowing folders, dark charcoal background, coral and warm white accent light, smooth motion, clean Apple-style product render, no text, no logos.
```

**安全感意象（文生图，再图生视频）**
```
A translucent glass shield gently forming around a small stack of folders, soft coral glow, dark minimalist background, calm and reassuring mood, clean 3D render, no text.
```

## 4. 分镜建议

中文说明每秒 6 到 9 个字。

| # | 时间 | 类型 | 英文 / 中文标题 | 中文说明 | 画面 | 做法 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 到 4s | 开场 | | | 深色底，一个珊瑚色光标亮起，点击一下，光的涟漪扩散 | AI 空镜 |
| 2 | 4 到 7s | 品牌 | Right-click. Done. / 右键一下，就办好了。 | | 涟漪收成应用图标，字标和标语上升 | 代码 |
| 3 | 7 到 17s | 新建 | New File / 在哪里右键，就在哪里新建 | 选好类型，文件就建在这个文件夹里 | Riko 在右边指向左边，左侧访达窗口里右键新建「未命名.md」，再演示重名变成「未命名 2.md」 | AI 角色 + 代码界面叠加 |
| 4 | 17 到 26s | 复制与移动 | Copy To · Move To / 常用的文件夹，一步就到 | 右键「复制到」，选一个常用文件夹 | 同第一版第 4 镜，文件飞向侧栏时可切 1.5 秒 AI 转场 | 代码，可选 AI 转场 |
| 5 | 26 到 33s | 在应用中打开 | Open in App / 直接在终端或编辑器里打开 | 终端打开目录，编辑器打开项目 | 同第一版第 5 镜 | 代码 |
| 6 | 33 到 41s | 工具箱 | Toolbox / 16 个小工具，只显示用得上的 | 选图片和选文件夹，菜单不一样 | 同第一版第 6 镜 | 代码 |
| 7 | 41 到 46s | 不止右键 | More ways in / 聚焦、快捷指令、系统服务 | 二维码在本机生成，选中文字就能翻译 | 快捷指令动作列表和二维码窗口 | 录屏 |
| 8 | 46 到 52s | 放心用 | Safe by default / 只碰你授权的文件夹 | 运行在沙盒里，删除先确认，系统目录受保护 | 1.5 秒 AI 护盾空镜，接欢迎窗口授权行的录屏，再接 3 张小卡片 | AI + 录屏 + 代码 |
| 9 | 52 到 60s | 结尾 | Right-click. Done. / 右键，就办好了。 | 官网免费开源 · Mac App Store ¥8 · 需要 macOS 26 | 左边图标、字标、两个按钮样式（官网下载 / App Store），下方 `rightkit.yiliang.app`；右边 Riko 挥手 | 代码 + AI 角色 |

**结尾**：商店版已于 2026-10-01 发布，结尾用 Apple 官方「Mac App Store 下载」中文徽章（`film/assets/badges/`，来自 toolbox.marketingtools.apple.com，未改动）。

## 5. 需要录屏的镜头

AGENTS.md 规定录屏只用临时目录里自己建的文件，演示用户用 `riko`。

- 欢迎窗口（浅色），停在文件夹授权那一行
- 快捷指令 App 里 RightKit 的动作列表
- 二维码窗口，输入 `rightkit.yiliang.app` 后预览出现
- 进度窗口（第一版就缺，这次补上）

放进 `film/recordings/`。缺哪个就跳过对应镜头，在交付说明里列出来。

## 6. 交付

1. `film/renders/rightkit-intro-v2-zh.mp4`
2. 联系表，AI 镜头和代码镜头都要有
3. `plan.json`、`evidence/`（`component-usage.json` 里 AI 镜头的 `reuseMode` 写 `ai-generated`，注明模型 `grok-imagine-video-1.5` 和首帧来源）
4. 交付说明：哪些已自动检查，哪些实际看过、听过；AI 镜头各生成了几次、为什么选这一条

中文版确认后再做英文版和竖版。竖版可以直接用竖版立绘生成的 AI 片段。
