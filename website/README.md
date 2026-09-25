# RightKit 官网

设计见 [官网设计](../docs/design/website.md)，角色见 [品牌角色设定](../docs/design/brand-character.md)。

## 构建和预览

```sh
make website        # 生成 website/dist
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
| 样式和动画 | `src/styles.css` |
| 首屏右键演示、滚动进场 | `src/main.js` |
| 字体、导出的图片、图标 | `public/` |

## 更新图片

角色原图在 `assets/character/`。换图后重新导出网页用的 WebP 和应用图标，并提交 `public/img/` 的变化：

```sh
pip install pillow
python3 website/tools/export_images.py
```

分享图 `public/img/og.jpg` 由 `tools/og.html` 渲染，需要 Playwright：

```sh
node website/tools/render_og.mjs
```
