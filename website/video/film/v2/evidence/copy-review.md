# 文案审阅 v2

| 镜头 | 文案 | 依据 |
| --- | --- | --- |
| cold | `// macOS 访达` | 平台面 |
| brand | Right-click. Done. / 右键一下，就办好了。 | `website/content.json` 标语 |
| new / send / open / toolbox | 与第一版相同，send 的注释改为「超过 1 秒的操作会显示进度，随时可以取消。」 | `F-075` |
| more | More ways in / 聚焦、快捷指令、系统服务；快捷指令里有 9 个动作，二维码在本机生成，选中文字还能直接翻译。 | `F-074` 9 个动作；`F-070` 本机生成、不上传；`F-071` Google 与百度翻译 |
| safe | Safe by default / 只碰你授权的文件夹；运行在 App 沙盒里，访问哪个文件夹由你决定。标签：删除前先确认、系统目录受保护、重名从不覆盖 | `F-080`、`F-051`、`F-073`，重名规则 |
| end | 官网免费开源 · Mac App Store ¥8 · 需要 macOS 26 或更高版本；按钮「下载 RightKit」加 Apple 官方「Mac App Store 下载」徽章；`rightkit.yiliang.app` | `content.json` 的中文价格与 `cta.download`；`site.json` 的商店链接 |

- 画面文案没有 em dash（`grep` 为 0）。
- 说明文字阅读速度：最高是结尾 47 字 / 5.5 秒，约每秒 8.5 字，在每秒 6 到 9 字的范围内。
- 录屏里的菜单名、动作名来自真实应用，没有改写。
- 徽章是 Apple 官方素材，原样使用，不改颜色和比例。
