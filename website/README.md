# RightKit 官网

设计见 [官网设计](../docs/design/website.md)，角色见 [品牌角色设定](../docs/design/brand-character.md)。

## 构建和预览

```sh
make website        # 生成 website/dist：经典版在 /，ak-ui 版在 /ak/
make website-serve  # 构建后在 http://localhost:8000 预览
make website-deploy # 构建并部署到 https://rightkit.yiliang.app
```

只需要 Python 3，不需要安装依赖。

## 改什么在哪里

| 要改的 | 文件 |
| --- | --- |
| 文案（中英两套） | `content.json` |
| 域名、下载地址、GitHub 链接、版本号 | `site.json` |
| 页面结构 | `src/index.html` |
| 样式和动画 | `src/styles.css`（经典，默认） |
| ak-ui 风格（`/ak/`） | `src/ak-ui.css`，叠加在 `styles.css` 之上；变量来自 `public/ak-ui/tokens.css` |
| 首屏右键演示、滚动进场 | `src/main.js` |
| ak-ui 版章节索引、工作台热点、词条粒子、Riko 档案和背景动效 | `src/ak.js`，调用 `public/ak-ui/js/` 里的 ak-ui 模块 |
| 字体、导出的图片、图标和视频 | `public/` |

## 更新图片

角色和 ak 工作台原图在 `assets/character/`，价格卡与 ak 首屏视频原片在 `assets/video/`。换图后重新导出网页用的 WebP、应用图标和视频（需要 ffmpeg），并提交 `public/img/` 和 `public/video/` 的变化。ak 首屏原片会自动导出成正放接倒放的无缝循环：

```sh
pip install pillow
python3 website/tools/export_images.py
```

分享图 `public/img/og.jpg` 由 `tools/og.html` 渲染，需要 Playwright：

```sh
node website/tools/render_og.mjs
```
