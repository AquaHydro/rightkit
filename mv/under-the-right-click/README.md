# Under the Right Click · 右クリックの向こう

Riko 的第一支音乐 MV。一部不存在的 90 年代 TV 动画的片头曲，日语主歌夹英文 hook，画面全部用孔版印刷质感的“riso-cel”风格重绘。

| 项目 | 内容 |
| --- | --- |
| 时长 | 3:28（208.15 秒），1920 × 1080，30 fps |
| 歌曲 | Suno v6 wild（`chirp-hawk-wild`）第 2 版，J-rock 动画 OP，170 BPM |
| 画面 | 14 段 Seedance 2.5 视频 + 8 张静态背景图 + 代码动效，全部经 WebGL 着色器重绘 |
| 成片 | 不在 git 内。本机 `~/Documents/riko-mv/video/`，或按下文重新渲染 |
| 完成 | 2026-09-30 |

总览截图见 [qa/contact-sheet.jpg](qa/contact-sheet.jpg)（每 4 秒一格），逐镜头分镜见 [STORYBOARD.md](STORYBOARD.md)。

## 1. 故事

**世界观：失序档案城。** 城市由无数文件柜堆成，每份文件原本都有名字和位置。一股叫“熵潮”的混乱浪潮袭来，高楼崩塌，文件像雪一样飘散，丢了名字，也找不到回家的路。

**主角：Riko。** 城里的整理者，能力是右键：点一下，世界的背面就会打开，一层层菜单像咒语一样展开，把混乱放回原位。

| 段落 | 时间 | 剧情 |
| --- | --- | --- |
| 失序 | 0–29 秒 | 警报响起，“第七层失序”。Riko 在天台回头，走过倒塌的文件柜峡谷，伸手接住无名文件。路径栏碎掉，一张“untitled”文件卡独自坠落。 |
| 第一次右键 | 29–65 秒 | 指尖亮起光标，她碰了碰发卡上的三条横线，倒数 3、2、1，点下右键。“新建、拷贝、移动”逐项亮起，熵值下降。巨浪升起，她转身一指，浪变成整齐的菜单。“我在这里。” |
| 雨夜 | 65–99 秒 | 画面褪成黑白灰，只剩一点珊瑚色。她在铁灰色的雨里走，墙角的草稿还在发热。小白鼠竖起珊瑚色耳朵指向远处的光，她追过去，扎进深不见底的文件夹竖井。 |
| 空白 | 99–158 秒 | 第二轮副歌里城市开始复原，接着切进一片纯白。她抱膝坐着，唱“如果有一天我也被遗忘”，然后轻点空白处，浮出一行字：“Archived. everything's okay.” |
| 归位 | 158–208 秒 | 三下巨大的右键把她唤醒。她撕开夜空，飞进星海般的菜单层。熵潮退去，文件飞回抽屉，城市在黎明复原，熵值降到 0.0%。她和小白鼠一起看日出。 |

**和产品的关系：** 整个故事是 RightKit 的比喻。文件乱了、找不到了、名字丢了，右键一下就能新建、拷贝、移动，一切回到该在的位置。

## 2. 歌词

原文在 [song/lyrics.txt](song/lyrics.txt)，逐词时间轴在 [song/timing_chirp-hawk-wild_2.json](song/timing_chirp-hawk-wild_2.json)。下面括号里的秒数是 Suno 对齐后的起唱时间。

**前奏**（2.3）
> Entropy alert\
> 熵值警报
>
> Layer seven, out of order\
> 第七层，失序

**主歌 1**（11.2）
> 真夜中のアーカイブ・シティ 崩れてく塔\
> 午夜的档案城，高塔正在崩塌
>
> 名前のないファイルが 雪みたいに舞う\
> 没有名字的文件，像雪一样飞舞
>
> 途切れたパスの先 誰も覚えてない\
> 断掉的路径尽头，谁也不记得了
>
> 帰る場所さえ 失くしたまま\
> 连回去的地方，都已经失去

**导歌 1**（29.5）
> 指先 宙に浮かべて カーソルが光る\
> 指尖悬在半空，光标亮起
>
> 三本のライン それだけを信じて\
> 三条横线，我只相信它们
>
> Three, two, one!

**副歌**（40.2 / 99.5）
> Right click! 世界の裏側を開いて\
> 右键！打开世界的背面
>
> 重なるメニューは 夜に咲く呪文\
> 层层叠叠的菜单，是夜里绽放的咒语
>
> New file, copy, move 行くべき未来へ\
> 新建、拷贝、移动，去往该去的未来
>
> エントロピーの波が 高くても put it all right\
> 就算熵的浪潮再高，也要把一切摆正
>
> Right click, right now\
> 右键，就是现在
>
> 混沌の果てで I'm here\
> 在混沌的尽头，我在这里

**主歌 2**（65.1）
> 鉄色の雨が すべての行を濡らす\
> 铁灰色的雨，淋湿每一行字
>
> 忘れられた下書きが 隅で熱を持つ\
> 被遗忘的草稿，在角落里发着热
>
> 小さなネズミが 珊瑚色の耳を立てた\
> 小老鼠竖起了珊瑚色的耳朵
>
> その一点の色が 帰り道のサイン\
> 那一点颜色，就是回家的路标

**导歌 2**（85.1）
> モノクロの街が 合図を待ってる\
> 黑白的城市，在等一个信号
>
> どんなに深いフォルダでも 見つけ出すから\
> 不管多深的文件夹，我都会找到你
>
> Three, two, one!

**桥段**（133.5）
> いつか私も 忘れられたなら\
> 如果有一天，我也被遗忘了
>
> 空白の場所を そっとクリックして\
> 就在空白的地方，轻轻点一下
>
> 小さな光の一行が 告げるでしょう\
> 一行小小的光会告诉你
>
> Archived, everything's okay\
> 已归档，一切安好

**升调前**（158.1）
> Right click\
> 右键
>
> Right click\
> 右键
>
> Right click, right now!\
> 右键，就是现在！

**最终副歌**（167.3）
> Right click! 世界の裏側を切り裂いて\
> 右键！撕开世界的背面
>
> 千のレイヤーが 星のように輝く\
> 千层图层，像星星一样闪耀
>
> New file, copy, move 在るべき未来へ\
> 新建、拷贝、移动，去往本该有的未来
>
> 波が引いたら すべての名前が還る\
> 浪潮退去，所有的名字都回来了
>
> Right click, right now\
> 右键，就是现在
>
> 混沌の果てで I'm here\
> 在混沌的尽头，我在这里

**尾声**（191.3）
> Put it all right\
> 把一切放回原处

“put it all right”是双关：字面是“把一切摆正”，又藏着“Right Click”的 Right。

**Suno 风格词**（`song/submit.py`）：`1990s anime opening theme, J-rock, energetic bright Japanese female vocals, Japanese lyrics with English hooks, 168 BPM, driving distorted guitars, fast tight drums, busy bass, glitchy digital click sounds, synth arpeggios, orchestral string stabs in chorus, dark cyberpunk atmosphere, dramatic builds, catchy powerful hook, key change final chorus`；排除 `rap, male vocals, heavy autotune, lo-fi, acoustic, ballad`。一共生成了 4 版，选第 2 版 wild 的理由是进副歌最快（40 秒），歌词对齐误差最低（0.42）。

## 3. 视觉风格

### riso-cel 重绘

AI 画面**从不直接出镜**。每一帧都经 `studio/gl.js` 重画：

1. Kuwahara 滤波压平成色块。
2. XDoG 勾出墨线，线条按 12 fps 抖动（“一拍两张”）。
3. 每个像素映射到当前调色板里最近的专色，暗部多一层硬边阴影。
4. 阴影区叠 45° 网点。
5. 印刷层：纸纤维、颗粒、套色错位、暗角。

结果像印在纸上的 90 年代赛璐璐，不同 AI 片段之间画风再飘也能统一。

### 专色

| 名称 | 色值 | 用途 |
| --- | --- | --- |
| paper | `#FAF7F5` | 纸张、浅色背景（RightKit 浅色背景） |
| ink | `#2A2B31` | 墨线、深色字（RightKit 图标底色） |
| coral | `#FF8F6C` | Riko 发根、主强调色 |
| rose | `#FF5175` | Riko 发梢、警报、第二强调色 |
| navy | `#12203F` | 夜空、档案城 |
| blue | `#1D5FD1` | 套色错位、夜景 |
| make / copy / send / nav | `#34C759` `#007AFF` `#00A3BF` `#FF8D28` | 只用在菜单图形上，对应 RightKit 菜单意图色 |

每个场景从 `studio/core.js` 的 `PAL` 里选一套调色板：`night`（夜景）、`face`（近景人脸，含肤色与腮红）、`rain`（主歌 2，几乎黑白，只留珊瑚色）、`blank`（桥段纯白）、`dawn`（结尾黎明）。

### 字体与版式

- **明朝体大字卡**（Shippori Mincho B1）：“第七層 失序”、片名卡，致敬 EVA 标题卡。
- **粗压缩无衬线**（Anton）：英文 hook 按歌词逐词砸出，“RIGHT CLICK!”“I'M HERE”。
- **竖排日文**（Noto Sans JP 900）：日语歌词从画面右侧自上而下展开。
- **字幕**：底部日文 + 珊瑚色英文释义。
- **等宽**（JetBrains Mono）：左上 “ARCHIVE CITY / LAYER 07”，右上熵值条。熵值随剧情变化：主歌上升，每次右键下降，结尾归零显示“ALL ARCHIVED”。

### 反复出现的母题

- **右键菜单**：Riko 发卡的放大版。纸色圆角卡片，四项“New File / Copy Path / Move to… / Open With”，色块用菜单意图色，高亮行是珊瑚色。
- **光标箭头**：黑色箭头加白描边，朝左上，和发卡一致。
- **倒数卡**：副歌前的“3、2、1”，墨、纸、珊瑚三色轮换。
- **小白鼠**：只有右耳是珊瑚色，暗指“鼠标右键”，在雨夜段落里负责指路。

### Riko 不能变的特征

和 [docs/design/brand-character.md](../../docs/design/brand-character.md) 一致：珊瑚渐变发色、头顶一根卷起的呆毛、刘海右侧的光标菜单发卡（箭头朝左上，三条珊瑚短横线在右下）。本片用的是明日方舟风的机能外套版本（`website/assets/character/profile-riko-stand-ak.png`），先据此生成 90 年代赛璐璐版设定图 [ref/char_sheet.jpg](ref/char_sheet.jpg)，之后每段视频都同时引用设定图和场景图。

## 4. 制作流程

```
歌词 ─▶ Suno 生成 4 版 ─▶ 选版 + 逐词时间轴
                              │
设定图 + 8 张场景图 ────────┐  │
                           ▼  ▼
                  Seedance 2.5（参考图 + 该段音频，口型同步）
                              │
                    gen/sd/*.mp4 ─▶ prep.sh 拆帧
                              │
        studio/scenes_riko.js 时间线（逐词卡点 + 代码动效）
                              │
             render.mjs 无头 Chrome 逐帧渲染 ─▶ encode.sh
```

### 目录

| 路径 | 内容 |
| --- | --- |
| `song/` | 歌词、Suno 提交与下载脚本、选定的母带、逐词时间轴 |
| `ref/` | 设定图与场景图（JPEG），旁边的 `.prompt.txt` 是生成提示词 |
| `gen/img.py` | 生图，调用兼容 OpenAI Images 的接口（本片用 `gpt-image-2.5`，带参考图时走 edits） |
| `gen/shots.json` | 12 个视频镜头的定义：名字、起止秒、是否唱歌、场景图、中文提示词 |
| `gen/submit_all.py` | 切音频片段并提交所有还没提交过的镜头 |
| `gen/sd.py` | 单个 Seedance 任务的提交与轮询 |
| `gen/sd/` | 14 段 Seedance 片段（Git LFS）和各自的提交记录（含完整提示词） |
| `studio/` | 渲染引擎、`lyrics.js`（按歌词行重组的时间轴）、`scenes_riko.js`（整片时间线） |
| `STORYBOARD.md` | 逐镜头分镜表 |

### 重新渲染

需要 Node、ffmpeg 和 Google Chrome，且要先装 Git LFS 把 `gen/sd/*.mp4` 拉下来。

```bash
cd mv/under-the-right-click
git lfs pull --include "mv/under-the-right-click/gen/sd/*"
npm install
./prep.sh                       # 拆帧、复制歌曲
node server.mjs &               # 预览：http://localhost:18766/index.html?t=45.2
node render.mjs --stills=45.2   # 单帧截图到 qa/
npm run render                  # 全片约 6,245 帧，4 进程约 3 分钟
./encode.sh                     # 输出到 video/
```

预览播放：`http://localhost:18766/index.html?play&from=40`，点一下页面开始。端口用 18766，是因为本机 8765、8766 常被别的工具占用。

### 重新生成素材

三类生成服务的地址和 key 都从 `~/.config/rightkit-mv/env` 读取，这个文件不进 git：

```
# 视频：Seedance，兼容火山方舟官方任务接口（POST/GET {SEEDANCE_BASE}/contents/generations/tasks）
SEEDANCE_BASE=https://ark.cn-beijing.volces.com/api/v3
SEEDANCE_KEY=...
SEEDANCE_MODEL=doubao-seedance-2.5   # 可选，按所用平台的模型 ID 填写
# 生图：兼容 OpenAI Images 的接口
IMAGE_BASE=https://api.openai.com/v1
IMAGE_KEY=...
# 歌曲：Suno 没有公开的官方 API，需要一个兼容 SunoAPI 格式的服务
SUNO_BASE=...
SUNO_KEY=...
```

用于商用的歌曲要在付费 Suno 账号下生成。

- Seedance 的参考图和音频以 base64 直接放进请求，不需要上传到公网。
- 改某个镜头：删掉 `gen/sd/<名字>.submit.json`，改 `gen/shots.json` 里的提示词，再跑 `python3 gen/submit_all.py`，然后 `python3 gen/sd.py --poll <名字>`。
- 一次调用里可以写“镜头1（前4秒）… 镜头2（后10秒）…”，让 Seedance 在一段里切多个镜头。

## 5. 关键经验

**官方 API 等额费用预估**（按火山方舟 2026 年公布的刊例价，无视频输入，16:9，24 fps）

| 模型 | 720p | 480p |
| --- | --- | --- |
| Seedance 2.5 | 约 ¥1.51 / 秒（¥70 / 百万 token） | 约 ¥0.67 / 秒 |
| Seedance 2.0 | 约 ¥0.99 / 秒（¥46 / 百万 token） | 约 ¥0.46 / 秒 |

本片 14 段视频共 124 秒（样片 13 秒，正片 111 秒），全部是 Seedance 2.5、720p：

| 方案 | 预估费用 |
| --- | --- |
| 本片实际规格：2.5，720p | 约 ¥187 |
| 改用 2.0，720p | 约 ¥123 |
| 2.5，480p | 约 ¥83 |
| 2.0，480p | 约 ¥57 |

生图（9 张）和 Suno 生成（2 次，共 4 首）费用很小，未计入。官方按秒计费，所以省钱的关键是少生成秒数：副歌镜头尽量复用，能用场景图加代码动效完成的段落不生成视频。riso-cel 着色器会重绘每一帧，480p 的线条细节略粗，但整体风格不受影响，是最直接的降本选项。

**复用策略**：副歌 2 的开头三句直接复用副歌 1 的两段片段（换裁切），指尖、睁眼特写、升调前的冲击镜头都从样片片段里截取；“浪被劈开”用复用的巨浪片段加代码动效完成。相邻镜头合并进一次最长 15 秒的生成（如 FG、IJ、ST、UV），在提示词里写“镜头1（前4秒）… 镜头2（后10秒）…”让 Seedance 在一段里切镜头。

**着色器调参**：人脸不要提高曝光（`expo` 保持约 0.98），否则皮肤会被映射成纸白并出现斑块；人脸调色板里不能放冷灰色，否则皮肤会落到灰色上。

## 6. 可以改进的地方

- 口型同步只做了逐帧截图检查，没有逐段人耳校对。
- 副歌 2 大量复用副歌 1，想要更丰富可以补 2 到 3 个新镜头（按官方价，5 秒 720p 约 ¥7.6）。
- 成片 450 MB，颗粒让压缩效率很低；发布前可以另做一版降低颗粒强度的网络版。
