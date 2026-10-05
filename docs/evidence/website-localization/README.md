# 官网日文、韩文国际化验收

2026-10-03，`codex/website-japanese-korean` 分支，随本记录提交的工作树；对应 `F-083`、`V-085`。环境：macOS 27.0.1，Codex 内置浏览器，静态服务 `http://localhost:8765`。本记录验证本地构建，尚未部署线上。

## 复现

```sh
make website
make website-test
python3 -m http.server 8765 --directory website/dist
```

经典版首页 `/`、`/en/`、`/ja/`、`/ko/`；隐私政策在相同语言目录下加 `privacy/`。ak 风格在上述路径前加 `/ak/`。两种风格共 16 页。日文、韩文页面的设置截图复制自 `docs/evidence/localization/`，明确标注下一版本隔离预览。当前下载版本显示 `0.1.3`，与 2026-10-02 发布的 `v0.1.3` 相同，没有把未来版本标成已发布。

## 自动验证

- 8 项 Python 测试：四语结构、占位符、技术字段、截图资源；真实临时构建的 16 页，检查所有本地资源、页面语言、模板替换、canonical、四语 hreflang / x-default、同风格/同页面类型的切换链接。ak 的 canonical 和 alternate 保持指向经典版对应语言。
- 16 项 Node 测试：执行实际 `language.js`，覆盖地区语言、偏好顺序、手动偏好优先、无效或被禁用的存储、不支持语言回退、明确语言路径与中文覆盖标记、查询和锚点保留、子路径部署、原生链接与修饰键、Escape 焦点回归、外部点击关闭。无需 npm 依赖。
- 官网测试已加入 `make verify`。没有将 VM 控制器测试写成真实浏览器语言模拟。

## 浏览器检查

- 日/韩 × 经典/ak × 1440 × 900 桌面与 390 × 844 手机，共 8 组布局：无横向溢出。ak 的说明文字全部位于内容背景内。尺寸、语言与边界见 [结构化结果](browser-checks.json)。
- 四语菜单展开、当前态、Enter 开启与 Escape 关闭正常，焦点返回摘要控件。手动选择韩文后访问默认入口进入 `/ko/`，直接访问 `/ja/` 仍显示日文。
- `/ak/ko/privacy/` 切到日文后进入 `/ak/ja/privacy/`，风格与页面类型保持不变。
- 中文 `/ak/?lang=zh` 的「隐私说明」仍进入 `/ak/privacy/?lang=zh`，不被已有日文偏好覆盖。
- 日文演示通过键盘展开新建子菜单，创建 `名称未設定.txt`，状态条显示日文成功反馈。
- 实际禁用页面 JavaScript 后，语言 disclosure 仍能展开，从日文 ak 隐私页切到英文 ak 隐私页；恢复了 JavaScript。
- 模拟减弱动态效果后，角色和跑马灯计算样式的动画为 `none`；仍可阅读全部内容。测试结束恢复了媒体与视口覆盖。

发现并修复：韩文的换行规则让品牌字标末尾折行，使说明离开固定高度的珊瑚背景。字标保持单行，ak 标题与说明现在以内容决定背景高度；日文手机长说明也不再越过背景。审查还修复了 ak canonical 偏离既有设计约定，以及中文「继续探索」隐私入口丢失显式语言标记的问题。修复后重新运行测试并检查界面。

截图：

| 页面 | 桌面 | 手机 |
| --- | --- | --- |
| 日文经典版 | [截图](ja-desktop.jpg) | [截图](ja-mobile.jpg) |
| 韩文经典版 | [截图](ko-desktop.jpg) | [截图](ko-mobile.jpg) |
| 日文 ak | [截图](ja-ak-desktop.jpg) | [截图](ja-ak-mobile.jpg) |
| 韩文 ak | [截图](ko-ak-desktop.jpg) | [截图](ko-ak-mobile.jpg) |

另有[语言菜单](ja-language-menu.jpg)、[韩文隐私手机页](ko-privacy-mobile.jpg)，以及设置截图在[日文桌面页](ja-settings-desktop.jpg)和[韩文手机页](ko-settings-mobile.jpg)里的实际展示。

## 复审修复：演示侧边栏折行

2026-10-05 复审发现，日文 1440 × 900 桌面页的模拟访达侧边栏里，「ダウンロード」「デスクトップ」折成两行（行高 50 px，见[修复前](ja-finder-sidebar-before.png)）。侧边栏加宽到 148 px，名称保持单行，过长时用省略号截断，不再折行。修复后用 Playwright Chromium 在 Linux 上对 `/ja/`、`/ko/`、`/ak/ja/`、`/en/`、`/?lang=zh` 逐项检查：侧边栏标题和三个位置名都只占一行，没有被截断（见[修复后](ja-finder-sidebar-after.png)）。官网测试 8 + 16 项重新通过。这次检查使用的是 Linux 字体，不能代替 macOS 上的视觉复测。

## 边界

自动浏览器语言优先级由控制器测试覆盖；当前内置浏览器不支持原始 CDP 的 User-Agent / Accept-Language 覆盖，因此没有宣称用真实浏览器模拟日/韩系统语言。未在真实手机、VoiceOver、其他浏览器或线上部署环境验收。没有修改已安装 RightKit、上传 App Store 或部署官网。

参考：[MDN 本机存储](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)、[Google 多语言页面说明](https://developers.google.com/search/docs/specialty/international/localized-versions)。保留明确语言路径与完整 hreflang，自动选择只用于默认入口。
