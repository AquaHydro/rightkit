# GPT-Image 2.5 二次编辑提示词

建议只重绘透明背景的 Q 版 Riko 角色层，再用 `scripts/appstore/render_product_images.mjs` 与真实界面截图合成。不要让生图模型改写 Finder 菜单、设置窗口或标题文字。每次上传以下参考图：`RightKit/Resources/AppIcon.icon/Assets/character.png`、`RightKit/Resources/AppIcon.icon/Assets/badge.png`、`website/assets/character/sheet.png`，以及对应的当前 `feature-*.png` 或 `status-ready.png`。输出透明 PNG，角色身份以图标和设定表为准。

前四张将下方整段作为提示词，把最后一行的 `{SCENE}` 替换为表格中的一项：

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

Create one chibi Riko cutout, 2.5 head-body ratio, matching the attached existing feature illustration's proportions and face. Preserve the exact curled ahoge and cursor-menu clip from the app icon; do not mirror or redesign the clip. Isolated full-body character, transparent 1024 x 1536 PNG, no background and no ground shadow. Keep hands anatomically consistent. Scene: {SCENE}
```

| 产品图 | `{SCENE}` |
| --- | --- |
| 01 新建文件 | `Riko pulls a fresh blank document from her hoodie pocket, with a small green plus badge near it. She looks excited and ready to help. No text on the document.` |
| 02 复制与移动 | `Riko carries several blank file cards and sends one toward a simple blue folder. A restrained teal motion trail shows the direction. No labels on the cards.` |
| 03 在应用中打开 | `Riko holds a cursor-shaped key next to a simple generic app window, suggesting opening a project. No app logos or text in the window.` |
| 04 工具箱 | `Riko opens a compact coral toolbox containing a ruler, magnifier, tag and small generic tools; her white mouse helps from inside the box. Keep the tools readable at small size.` |

第五张另用方形状态头像提示词，不沿用全身 2:3 的尺寸：

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

Edit only the status-ready mascot portrait, using the attached status-ready.png as the layout reference. Square 1024 x 1024 composition, flat charcoal #2A2B31 background. Keep the head position and size, curled ahoge, white cursor-menu hair clip, hoodie silhouette and tiny mouse consistent with the reference. Bright confident smile and a clear OK hand gesture. Everything important must remain inside a central circular crop with 8% margin. Do not add UI, text, a second character or extra props.
```

**成品检查：**生成图只替换透明角色层；标题继续由 HTML 排版，真实界面截图保持逐像素不变。对照图标检查发色、呆毛、发卡箭头和三条珊瑚线。英文版应重新截取真实英文 UI，不用模型翻译截图里的菜单文字。
