# 品牌角色设定

用于官网、启动画面、关于页、社交媒体等对外物料的角色立绘。App 界面里不使用立绘，界面视觉仍以 [DESIGN.md](../../DESIGN.md) 为准。

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
| 眼睛 | 深炭灰，带珊瑚色小高光，脸颊有粉色腮红，对应图标里的竖条眼和腮红 |
| 服装 | 奶白色宽松连帽外套，帽檐和袖口有炭灰 `#2A2B31` 滚边；胸前小口袋插一支铅笔和一张折角文件卡 |
| 伙伴 | 一只圆滚滚的小白鼠，只有右耳是珊瑚色，暗指「鼠标右键」 |
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
- 发卡和手指最容易画崩，用局部编辑修，修完对照图标检查箭头方向和三条横线。

## 提示词

### 固定风格段落

每条提示词开头都加这一段，外形才能保持一致。

```text
Character: "Riko", the mascot of RightKit, a macOS right-click menu utility.
A cheerful, quick-handed young woman, early 20s, friendly and capable.
Hair: fluffy shoulder-length layered bob with soft messy strands, coral gradient from peach-coral #FF8F6C at the roots to rose-pink #FF5175 at the tips, one big curled ahoge on top of the head.
Signature hair clip on the right side of the bangs: a small white rounded-square clip showing a black mouse cursor arrow with a white outline, next to three short coral horizontal lines like a context menu.
Eyes: dark charcoal eyes with small coral highlights, soft pink blush on the cheeks, small warm smile.
Outfit: oversized ivory-white hoodie with charcoal #2A2B31 trim on the hood edge and cuffs, a small chest pocket holding a pencil and a folded-corner file card.
Companion: a tiny round white mouse (the animal) with only its right ear colored coral, sitting on her shoulder.
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

透明背景，用于启动画面、官网首屏、关于页和头像。

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
Soft flat shading, clean vector-like look, small drop shadow under her feet.
```

| 分区 | 场景 |
| --- | --- |
| 新建文件 | `she pulls a fresh blank document out of her hoodie pocket like a magic trick, sparkles around it, a small green plus badge floats above` |
| 拷贝、移动到常用位置 | `she carries a stack of file cards and tosses one into a floating blue folder portal, motion trail behind the card` |
| 用指定应用打开 | `she holds a big key-shaped cursor and unlocks a floating app window` |
| 工具箱 | `she opens a small coral toolbox full of tiny tools (ruler, magnifier, tag, hash symbol block), the white mouse helps from inside the box` |
| 空状态、出错 | `she sits on a folder looking puzzled, the white mouse holds a tiny question-mark sign` |

## 导出

| 物料 | 格式 |
| --- | --- |
| 官网 Hero | WebP，约 2400 × 900 |
| 立绘、小插图 | 透明 PNG 或 WebP |

## 参考

官网结构参考 [cindy.app](https://cindy.app/)：左侧大标题，右侧角色立绘，深色背景。只参考版式，角色、配色和伙伴都不照搬。
