# 应用图标来源

「在应用中打开」一节用这些图标指代 RightKit 能检测到的应用。图标归各自所有者，只用于说明 RightKit 可以配合这些应用使用。

| 文件 | 来源 | 权利人 |
| --- | --- | --- |
| `terminal.png` | Apple 终端使用手册页面（support.apple.com/guide/terminal） | Apple Inc. |
| `xcode.png` | Apple Developer 网站的 Xcode 图标（developer.apple.com） | Apple Inc. |
| `vscode.png` | Visual Studio Code 品牌资源包（code.visualstudio.com/brand） | Microsoft Corporation |
| `ghostty.png` | Ghostty 仓库 `images/icons/icon_512.png`（github.com/ghostty-org/ghostty） | Ghostty 项目 |

Microsoft 的品牌指南允许用蓝色图标指代 Visual Studio Code。Apple 对自家应用图标的对外使用有限制，正式上线前需要确认是否符合 Apple 的商标使用指南，不符合时换回自绘图标。

导出：`python3 website/tools/export_images.py`，输出到 `public/img/apps/`。
