# 品牌角色设定

用于官网、社交媒体等对外物料的角色立绘。App 里 Riko 的立绘出现在欢迎窗口、设置「通用」页的扩展状态卡片（按状态换表情），以及「没有监视目录」的空状态；关于弹出层用应用图标里的 Q 版 Riko；普通设置行、菜单栏和访达菜单都不放角色。具体规则以 [DESIGN.md](../../DESIGN.md) 为准。

## 角色来源

角色就是应用图标里的 Q 版女孩（`RightKit/Resources/AppIcon.icon/Assets/character.png`），立绘是她的完整版，不另起新角色。

名字暂定 **Riko**（Right 加一个常见的名字尾音），定稿前可以换。

## 不能改的特征

下面三处在任何物料里都必须和图标一致，别人靠这三处认出是同一个角色：

1. **发色**：从根部 `#FF8F6C` 渐变到发梢 `#FF5175`，就是品牌珊瑚渐变。
2. **呆毛**：头顶一缕卷起的头发，是图标轮廓的一部分。
3. **光标菜单发卡**：戴在刘海右侧的白色圆角小卡片，上面是带白描边的黑色箭头和三条珊瑚色短横线。箭头朝左上，三条线在右下，和图标图层 `badge.png` 一致。

## 其他设定

| 项目 | 设定 |
| --- | --- |
| 性格 | 开朗、手快、靠得住的小帮手，可爱但不幼稚 |
| 年龄感 | 二十出头 |
| 发型 | 蓬松的层次短发，长度到肩，碎发略乱 |
| 眼睛 | 深红棕色瞳孔，带亮高光，脸颊有粉色腮红。Q 版用图标里的竖条眼 |
| 服装 | 奶白色宽松连帽外套，帽檐和袖口有炭灰 `#2A2B31` 滚边；胸前小口袋插一支铅笔和一张折角文件卡 |
| 伙伴 | 一只圆滚滚的小白鼠，只有画面右侧那只耳朵是珊瑚色，暗指「鼠标右键」 |
| 画风 | 干净的现代动画风：线条清爽，赛璐璐上色加柔和渐变，珊瑚色轮廓光。介于图标的扁平 Q 版和精致插画之间 |

## 用色

| 用途 | 颜色 |
| --- | --- |
| 发色渐变 | `#FF8F6C` → `#FF5175` |
| 深色背景 | `#2A2B31`（图标底色） |
| 浅色背景 | `#FAF7F5` |
| 轮廓光 | 珊瑚色，不用蓝红撞色 |
| 画面里的菜单项 | 用[菜单设计系统](menu-system.html)的意图色：创建绿、前往橙、拷贝蓝、移动青、外观紫 |

危险红只表示彻底删除，不作为画面装饰色。

## 生图规则

- 模型：GPT-image。提示词用英文，遵循度更稳。
- 每次生成都上传图标图层 `character.png` 作为参考。设定表定稿后，也把设定表一起上传。
- 图里不生成文字、字母和 Logo。标题、标语在网页上用 HTML 排版，方便改文案和做中英双语。
- 不出现苹果 Logo 或访达笑脸图标，文件夹画成普通蓝色文件夹。
- 立绘和小插图要透明背景：API 设 `background: "transparent"`，在 ChatGPT 里直接说要透明 PNG。
- 透明素材不画地面阴影，阴影由网页用 CSS 画，否则浅色阴影在深色背景上会变成光圈。
- 同一组 Q 版小插图用同一尺寸画布（1024 × 1536），头顶和脚底位置对齐。
- 发卡和手指最容易画崩，用局部编辑修，修完对照图标检查箭头方向和三条横线。

## 提示词

### 固定风格段落

每条提示词开头都加这一段，外形才能保持一致。

```text
Character: "Riko", the mascot of RightKit, a macOS right-click menu utility.
A cheerful, quick-handed young woman, early 20s, friendly and capable.
Hair: fluffy shoulder-length layered bob with soft messy strands, coral gradient from peach-coral #FF8F6C at the roots to rose-pink #FF5175 at the tips, one big curled ahoge on top of the head.
Signature hair clip on the right side of the bangs: a small white rounded-square clip showing a black mouse cursor arrow with a white outline, next to three short coral horizontal lines like a context menu.
Eyes: deep reddish-brown eyes with bright highlights, soft pink blush on the cheeks, small warm smile.
Outfit: oversized ivory-white hoodie with charcoal #2A2B31 trim on the hood edge and cuffs, a small chest pocket holding a pencil and a folded-corner file card.
Companion: a tiny round white mouse (the animal) with only the ear on the viewer's right side colored coral, sitting on her shoulder.
Art style: clean modern anime illustration, crisp lineart, cel shading with soft gradients, gentle coral rim light, polished key-visual quality, cute but not childish. Keep the hair shape, hair color and hair clip exactly as in the reference image.
No text, no letters, no logos, no watermark.
```

### 1. 角色设定表

最先生成，定稿后作为之后所有图的基准，不再改设计。

```text
[固定风格段落]
Character reference sheet on a plain light warm-gray background: full-body front view, 3/4 view, and back view standing side by side, plus a row of 4 facial expression close-ups (happy, focused, surprised, proud wink), a close-up detail of the cursor-menu hair clip, and the white mouse companion shown front and side. Consistent proportions across all views, even studio lighting, clean layout with generous spacing.
```

### 2. 主立绘

透明背景，用于应用欢迎窗口、官网和头像。

```text
[固定风格段落]
Bust-up portrait, body turned slightly left, head tilted toward the viewer with a confident friendly smile, one hand raised near her face with the index finger pointing up as if about to click. The white mouse peeks out from her right shoulder. Hair gently lifted by a light breeze, a few strands flying. Soft coral rim light on the hair edges.
Transparent background, isolated character, clean edges, no background elements, no shadow on the ground. Square 1:1 composition with some empty space around the figure.
```

### 3. 官网 Hero 横幅

左侧留空放 HTML 标题。菜单行只画图标和空白条，不画文字。

```text
[固定风格段落]
Wide cinematic key visual, 21:9. Dark charcoal background #2A2B31 with subtle dotted grid and faint glowing particles. The character is placed on the right third of the frame, waist-up, turning toward the viewer, one hand reaching out and lightly tapping a floating translucent frosted-glass context menu panel. The menu has 5 rows, each row is a small colored rounded icon plus a blank gray bar (no text): green plus-document icon, orange arrow icon, blue copy icon, teal folder-move icon, purple sparkle icon. A few tiny blank file cards and a generic blue folder float around her. Coral rim light from behind, soft coral glow in the lower right.
The left 55% of the image is calm empty dark space for headline text. No text anywhere.
```

浅色版把背景那一句换成：

```text
Soft warm off-white background #FAF7F5 with a very faint coral radial glow behind her, subtle paper texture, light and airy.
```

### 4. 功能分区小插图

Q 版，风格贴近图标，透明背景。把 `{场景}` 换成下表中的一条。

```text
[固定风格段落]
Chibi version of the character (2.5 head-body ratio), matching the app icon style: simple vertical-line eyes, round blush. Full body, transparent background.
Scene: {场景}
Soft flat shading, clean vector-like look, no ground shadow (the website draws it).
```

| 分区 | 场景 |
| --- | --- |
| 新建文件 | `she pulls a fresh blank document out of her hoodie pocket like a magic trick, sparkles around it, a small green plus badge floats above` |
| 拷贝、移动到常用位置 | `she carries a stack of file cards and tosses one into a floating blue folder portal, motion trail behind the card` |
| 用指定应用打开 | `she holds a big key-shaped cursor and unlocks a floating app window` |
| 工具箱 | `she opens a small coral toolbox full of tiny tools (ruler, magnifier, tag, hash symbol block), the white mouse helps from inside the box` |
| 空状态、出错 | `she sits on a folder looking puzzled, the white mouse holds a tiny question-mark sign` |

### 5. 应用欢迎窗口

用在 App 首次启动的欢迎窗口，显示成 160 pt 的圆形头像。和官网素材不同，这张**不要透明背景**，直接画在图标底色上：透明图里的白色外套放进浅色窗口会没有轮廓，而圆形炭灰底和应用图标是同一个样子。

参考图（按顺序上传）：

1. `RightKit/Resources/AppIcon.icon/Assets/character.png`：发色、呆毛、发卡的基准。
2. `website/assets/character/sheet.png`：设定表，服装和小白鼠。
3. `website/assets/character/main.png`：画风和脸型，新图要和它像同一个画师画的，但动作不同。

```text
[固定风格段落]
Welcome greeting avatar for the app's first-launch window. Bust-up portrait, facing the viewer, head slightly tilted, warm welcoming smile with eyes open, one hand raised beside her face in a small friendly wave (palm toward viewer, five clear fingers). The white mouse sits on her shoulder on the viewer's left and also waves one tiny paw.
Solid flat charcoal background #2A2B31 filling the whole canvas, with a very soft coral glow behind her head. Soft coral rim light on hair and hoodie edges so the white hoodie separates clearly from the dark background.
Composition for a circular crop: square 1:1, 1024 x 1024, face centered slightly above the middle, the whole head including the ahoge and the hair clip inside the central circle with at least 8% margin, waving hand and mouse also inside the circle. Nothing important in the four corners.
No text, no letters, no logos, no UI elements, no watermark.
```

检查：

- 发卡在观者右侧的刘海上，箭头朝左上，三条珊瑚线在右下。
- 挥手的那只手是五根手指。
- 在 160 px 圆形裁切下，呆毛、发卡、小白鼠都没有被切掉，脸在圆心略偏上。
- 背景是纯色 `#2A2B31`，没有渐变色带，边缘和 App 里的圆形底色能接上。
- 定稿后放到 `website/assets/character/welcome.png`，再导出 160 和 320 px 替换 `RightKit/Resources/Assets.xcassets/WelcomeCharacter.imageset`。

### 6. 扩展状态表情头像

用在设置「通用」页顶部的扩展状态卡片，显示成 56 pt 的圆形头像，表情跟着状态变。三张是一组，构图、背景、光线和[第 5 条](#5-应用欢迎窗口)欢迎图完全一致，只改表情和手势，切换时才不会跳。

参考图（按顺序上传）：

1. `website/assets/character/welcome.png`：构图、背景、光线、画风的基准，三张都以它为底。
2. `RightKit/Resources/AppIcon.icon/Assets/character.png`：发色、呆毛、发卡。
3. `website/assets/character/sheet.png`：服装和小白鼠。

共用段落（接在固定风格段落后面）：

```text
Status avatar, one of a set of three expression variants based on the attached welcome image. Keep EXACTLY the same framing, camera distance, head position and size, hair shape, outfit, lighting and background as the welcome image; only the facial expression, the raised hand gesture and the mouse's pose change.
Tighter head-and-shoulders crop than the welcome image is NOT allowed; the face must stay in the same place so the three variants can crossfade without jumping.
It will be displayed very small (56 pt circle), so the expression must read clearly at that size: bold, simple, exaggerated facial expression, clear eye shapes, readable hand silhouette.
Solid flat charcoal background #2A2B31 filling the whole canvas, very soft coral glow behind her head, soft coral rim light on hair and hoodie edges.
Square 1:1, 1024 x 1024, face centered slightly above the middle, head with ahoge and hair clip, the raised hand and the mouse all inside the central circle with at least 8% margin. Nothing important in the four corners.
No text, no letters, no logos, no UI elements, no watermark.
```

| 文件 | 状态 | 表情段落 |
| --- | --- | --- |
| `status-ready.png` | 已启用 | `Expression: bright confident smile, eyes closed in happy upturned arcs, cheeks blushing. Gesture: her raised hand makes a clear OK sign (thumb and index finger forming a circle, other three fingers up). The mouse gives a tiny thumbs-up with its paw, small sparkle next to it.` |
| `status-sleepy.png` | 未运行 | `Expression: drowsy and sleepy, half-closed droopy eyes, small yawn with mouth slightly open, one tiny tear at the corner of the eye. Gesture: her raised hand gently rubs one eye with a loose fist. The mouse is curled up asleep on her shoulder with a small "zz" bubble drawn as simple shapes, not letters.` |
| `status-puzzled.png` | 未启用、后台服务已关闭 | `Expression: puzzled and slightly worried, eyebrows raised and tilted, eyes wide, small wavy closed mouth, head tilted a bit more. Gesture: her raised index finger touches her cheek in a thinking pose. The mouse holds up a tiny white sign with a coral question mark shape on it.` |

检查：

- 三张叠在一起来回切换，脸、头发轮廓和发卡位置不跳。
- 缩到 56 px 圆形时，三种表情一眼能分清。
- 发卡在观者右侧刘海上，箭头朝左上，三条珊瑚线在右下；手指数目正确。
- 「zz」和问号只画成图形，不出现字母；小白鼠只有观者右侧那只耳朵是珊瑚色。
- 定稿后放到 `website/assets/character/`，导出 56、112、168 px 三档放进 App（`StatusReady`、`StatusSleepy`、`StatusPuzzled`）。

### 7. 官网价格卡和循环视频

官网价格区的三张 2:3 插画卡，hover 时播放循环视频（见[官网设计](website.md#价格卡)）。和其他官网素材不同，这几张**不要透明背景**：视频不支持透明，画面直接画在卡片底色上。

参考图（按顺序上传）：`RightKit/Resources/AppIcon.icon/Assets/character.png`、`website/assets/character/main.png`。用 `gpt-image` 系列，尺寸 1024 × 1536，画质 high。

共用段落（接在固定风格段落后面）：

```text
Vertical pricing-card key visual, 2:3 portrait. {画面}
The lower 40% of the frame fades smoothly into plain flat {底色} with nothing in it, reserved for text. No text, no letters, no numbers, no dollar signs, no logos, no watermark.
```

| 文件 | 底色 | 画面 |
| --- | --- | --- |
| `pricing-free.png`（官网版） | charcoal `#2A2B31` | `Close-up bust portrait filling the upper 60% of the frame: Riko looks at the viewer with a relaxed, warm, slightly playful smile, chin resting lightly on one hand, the white mouse sitting on top of her head. Hair gently lifted by a breeze. Solid charcoal background #2A2B31 with a soft coral glow behind her head and a few tiny floating blank file cards.` |
| `pricing-store.png`（商店版） | off-white `#FAF7F5` | `Theme: thanking a supporter. Waist-up in the upper 60% of the frame: Riko smiles warmly at the viewer, holding a warm coral ceramic coffee mug with both hands close to her chest, a thin curl of steam rising from it shaped softly like a heart. The white mouse sits on her shoulder hugging a tiny shiny gold coin with a small heart embossed on it. Soft warm off-white background #FAF7F5 with a faint coral radial glow behind her, a few tiny sparkles.` |
| `pricing-oss.png`（开源） | off-white `#FAF7F5` | `Riko sits cross-legged, seen from slightly above, happily building something with small wooden blocks shaped like folder and document icons, a small wrench in one hand; the white mouse stands on a block handing her a tiny screw. A few blank sticky notes and puzzle pieces around. Soft warm off-white background #FAF7F5 with a very faint coral radial glow, light and airy.` |

视频用 Grok 图生视频，把定稿图**同时当首帧和尾帧**上传，6 秒、720p。动作只写小幅度的：眨眼、头发飘动、小白鼠动一动、背景小物件浮动。提示词里要写明头、脸和发卡全程不动：

```text
Very subtle living-portrait loop, locked camera, no cuts, no zoom. {小动作}. Her head, face and the white cursor hair clip on her bangs stay exactly in place and unchanged the whole time. Ends in the same pose as the start. No text.
```

检查：

- 视频模型最容易让发卡漂移、变形，或者凭空多出道具。每张图至少生成两条，每 12 帧抽一张放大发卡区域，挑全程不变的一条。
- 首帧和末帧要接得上，否则循环时会跳。接不上时用 ffmpeg 把视频正放加倒放拼成一条（`split`、`reverse`、`concat`）。
- 蒸汽、光效不能挡住脸。
- 画面里有道具时，提示词加一句 `Only the objects already in the frame, no new tools or objects appear.`，否则容易多出扳手、蝴蝶结之类的东西。
- 小白鼠只有观者右侧那只耳朵是珊瑚色；不对就先用局部编辑修图，再生成视频。
- 定稿后图片放到 `website/assets/character/`，原片放到 `website/assets/video/`，文件名和图片一致，再运行 `website/tools/export_images.py`。

### 8. ak-ui 风格版本

官网 ak-ui 风格（`/ak/`）用的全套角色图。每张都以对应的经典版为底重画，只换服装，构图、姿势、道具和画布位置不变，所以网页版式不用改。

参考图（按顺序上传）：对应的经典版原图、`website/assets/character/hero-character-ak.png`（服装基准；它本身用 `hero-character.png` 和图标 `character.png` 生成）。用 `gpt-image` 系列，画质 high，尺寸和透明设置与经典版相同。

```text
Redraw the character from the first image with the exact same composition, pose, framing, canvas position and props. Keep her face, the coral gradient hair, the curled ahoge and the white hair clip with a black cursor arrow and three coral lines exactly. Only change her outfit to the tactical 'operator' field jacket from the second image: ivory-white technical jacket with high collar, charcoal #2A2B31 structural panels on shoulders and cuffs, thin coral signal stripes, slim black chest harness strap with a small buckle, charcoal armband with a coral chevron, black headset around the neck. {补充}
No text, no letters, no numbers, no logos, no watermark.
```

- Q 版补充：`chibi proportions (2.5 heads tall, simple vertical-line eyes, round blush), black shorts, chunky white-and-charcoal sneakers, clean vector-like cel shading, transparent background, no ground shadow`。道具可以加切角，但颜色和含义不变（工具箱变成珊瑚色硬壳装备箱）。
- 价格卡补充：底色不变，加 `a very faint thin line grid and a few small coral corner brackets`，下方 40% 仍然渐变成纯底色。
- 价格卡视频照[第 7 条](#7-官网价格卡和循环视频)生成。Grok 常常回不到首帧，导出脚本对 `-ak` 视频统一做正放加倒放。

### 9. ak-ui 档案全身立绘和首屏 PV

档案区使用四张透明全身立绘：`profile-riko-stand-ak.png`、`profile-riko-ok-ak.png`、`profile-riko-wave-ak.png` 和 `profile-riko-file-ak.png`。站姿版先用 `hero-character-ak.png` 与应用图标的 `character.png` 生成；其余三张以定稿的 `profile-riko-stand-ak.png` 为第一张参考图，只改姿势，这样造型才一致。使用 OpenAI 图片编辑通道，透明 PNG。站姿版本要求自然正面站立，OK 版本微侧身并做清晰手势，挥手版本伸出完整五指问好，文件版本双手把一叠三张无字奶白色折角纸质文件卡抱在胸前。四张都要完整保留头顶呆毛到鞋底和四周透明边距。

提示词必须明确这些检查项：珊瑚粉渐变、长度到肩的短发（第一版挥手和文件图变成了及腰长发加过膝袜和腿环，必须写明 `SHOULDER-LENGTH`、`short white socks`、`no thigh-high socks, no leg straps`）；观者右侧刘海上的白色光标发卡；黑色箭头朝左上；发卡右下三条珊瑚线；机能夹克结构与 `hero-character-ak.png` 一致；小白鼠只有观者右侧耳朵是珊瑚色；不要文字、Logo、UI、游戏素材、地面阴影或水印。文件卡只能使用纯色与折角，不出现字母、数字或符号。

首屏背景 `hero-pv-poster-ak.png` 是 16:9 的纯环境画面，不再重复画 Riko，避免和网页前景立绘争抢焦点。左侧保留低细节暗部给网页文案，上下自然压暗。场景只使用原创的深石墨数据工作间、磨砂玻璃板、细结构线、空白文件卡片轮廓、地面微反射和珊瑚雾光，不出现人物、动物、文字和游戏素材。

把同一张海报同时作为 Grok 图生视频的首帧和尾帧，6 秒、720p。动作限于珊瑚雾光呼吸、玻璃边缘高光缓慢流动、空白卡片漂移几个像素和地面反射轻微变化。镜头锁定，不切镜、不缩放，不生成新人物、新动物或新道具。每 12 帧抽查结构没有跳动，也没有凭空出现人物、文字或 Logo；如果首尾仍不一致，网页导出统一正放接倒放。

## 导出

| 物料 | 格式 |
| --- | --- |
| 官网 Hero | WebP，约 2400 × 900 |
| 立绘、小插图 | 透明 PNG 或 WebP |
| 价格卡插画 | 不透明 PNG 原图，网页用 WebP 420 和 840 宽 |
| 价格卡视频 | MP4（H.264，无音轨），网页版不超过 1MB |

官网用到的素材清单、当前状态和官网设计见[官网设计](website.md)。

## 参考

官网结构参考 [cindy.app](https://cindy.app/)：左侧大标题，右侧角色立绘，深色背景。只参考版式，角色、配色和伙伴都不照搬。
