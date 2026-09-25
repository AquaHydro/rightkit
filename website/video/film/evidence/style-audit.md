# 风格审计

决策：`repo`。沿用官网（`docs/design/website.md`「视觉」，代码 `website/src/styles.css`）。视频只加画面排版，样式全部复用官网的 token 和类。

## 色板

| 用途 | 值 | 来源 |
| --- | --- | --- |
| 深色背景 | `--ink #2A2B31`，结尾 `--ink-3 #202126` | styles.css `:root` |
| 米白背景 | `--paper #FAF7F5`（第 7 镜） | 同上 |
| 品牌色 | `--coral #FF7973`：编号、强调、注释行 | 同上 |
| 珊瑚渐变 | `#FF8F6C → #FF5175`：跑马灯、下载按钮、「就办好了。」 | 同上，只用于大色块和强调 |
| 弱文本 | `--on-ink-2 #AEACB3` / `--on-paper-2` | 同上 |
| 菜单 | `--menu-bg`、高亮 `--menu-hi #0A84FF` | 同上，外观按 menu-system.html |
| 红色 | 只出现在官网工具箱卡片的「彻底删除」上，视频里没有用 | — |

工具箱对比镜头的差异行用 `rgba(255,121,115,.2)` 加 3px 珊瑚左边线，是品牌色，不是危险红。

## 字体

- 英文标题：Nunito 900，`website/public/fonts/nunito-latin.woff2`（OFL，许可证在同目录），拉丁子集，由 `--film-font-en` 指定。
- 中文标题和正文：PingFang SC 600/400，系统字体，Mac 上渲染，由 `--film-font-zh` 指定，不打包。
- 小标签、文件名：Geist Mono 500（同目录，OFL）。小标签格式 `// 01  新建`，编号珊瑚色。
- 渲染前等待 `document.fonts.ready`；静帧里 Nunito 的字形（圆头、900 字重）已确认加载。

## 空间和形状

卡片圆角 16px（放心用卡片放大到 22px），菜单 12px，访达窗口 14px，原样来自 styles.css。访达窗口和菜单整体按 1.35 倍放大，内部间距不变。

## 动效

全片主曲线 `cubic-bezier(0.16, 1, 0.3, 1)`。进场上升 24px 加淡入，时长 0.7s，同组错开 60 到 70ms。菜单从光标位置缩放 0.96 到 1，0.18s。光标移动 `cubic-bezier(0.45,0,0.2,1)`，图标飞向侧栏 `cubic-bezier(0.5,0,0.2,1)` 520ms，都照抄 main.js。官网的 CSS 动画全部关掉，改由主时间轴驱动，可以任意 seek。

## 品牌与角色

- 应用图标 `website/public/img/app-icon-512.png`，完整圆角底板。
- Riko：第 3 镜用 `hero-character`（手指向左，指着访达窗口），结尾用 `cta-character`，第 4 到 6 镜小尺寸配 `feature-*`。都没有翻转，也没有放在珊瑚色块上，放在深色底加珊瑚光晕上。

## 镜头适配

- 直接复用：访达窗口 markup、菜单项（buildMenu 输出）、文件图标、状态条、假光标、类型标签、应用标签、卡片、跑马灯、下载按钮。
- 调整：窗口放大 1.35 倍；菜单改为 stage 内绝对定位，翻转和贴边规则照 place() 实现；跑马灯文字改用菜单名。
