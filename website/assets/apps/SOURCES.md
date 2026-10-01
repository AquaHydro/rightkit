# 应用图标来源

「在应用中打开」一节用这些图标指代 RightKit 能检测到的应用。图标归各自所有者，只用于说明 RightKit 可以配合这些应用使用。

| 文件 | 来源 | 权利人 |
| --- | --- | --- |
| `terminal.png` | Apple 终端使用手册页面（support.apple.com/guide/terminal） | Apple Inc. |
| `xcode.png` | Apple Developer 网站的 Xcode 图标（developer.apple.com） | Apple Inc. |
| `vscode.png` | Visual Studio Code 品牌资源包（code.visualstudio.com/brand） | Microsoft Corporation |
| `ghostty.png` | Ghostty 仓库 `images/icons/icon_512.png`（github.com/ghostty-org/ghostty） | Ghostty 项目 |

Microsoft 的[品牌指南](https://code.visualstudio.com/brand)允许在文档中介绍 Visual Studio Code 时使用图标，但不允许用图标宣传自己的产品。Apple 对自家应用图标的对外使用也有限制。

导出：`python3 website/tools/export_images.py`，输出到 `public/img/apps/`。
