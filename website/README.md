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
| 文案（中英日韩四套） | `content.json` |
| 域名、下载地址、GitHub 链接、版本号 | `site.json` |
| 页面结构 | `src/index.html` |
| 样式和动画 | `src/styles.css`（经典，默认） |
| ak-ui 风格（`/ak/`） | `src/ak-ui.css`，叠加在 `styles.css` 之上；变量来自 `public/ak-ui/tokens.css` |
| 语言匹配、记住手动选择和原生语言菜单 | `src/language.js` |
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

## 国际化

经典版首页在 `/`、`/en/`、`/ja/`、`/ko/`，隐私政策在各语言目录的 `privacy/`。ak-ui 风格在相同路径前加 `/ak/`，共 16 页。两种风格共享文案和语言控制器；导航与页脚提供四种语言。`build.py` 的 `page_scope` 统一生成页面链接和语言列表，ak 页面的 SEO canonical 与 alternate 指向经典版对应语言。

默认中文入口按浏览器语言偏好顺序匹配中英日韩，手动选择优先并记在本机 `localStorage`。明确访问 `/en/`、`/ja/`、`/ko/` 时不自动改语言；`?lang=zh` 明确保留中文。切换保留页面类型、风格、查询参数和锚点。不支持的浏览器语言回退中文，存储被禁用时仍能切换；关闭 JavaScript 时使用普通链接。隐私政策说明了本机语言偏好存储。

日文、韩文页面的设置截图来自 `docs/evidence/localization/` 的生产视图隔离预览，标注为下一版本。应用尚未发布新语言前，标签和 FAQ 保留下一版本说明；发布后一起更新这些文案与 `site.json` 的版本号。当前版本号与已发布的 `v0.1.3` 一致。

```sh
make website-test   # 8 项 Python 产物检查 + 16 项 Node 控制器测试
```

构建仍只需要 Python 3；测试另需 Node.js 20 或更高版本，不需要安装 npm 依赖。`make verify` 同时运行官网测试。浏览器截图和复测记录见 [官网国际化验收](../docs/evidence/website-localization/README.md)。
