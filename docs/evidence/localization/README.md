# 日文、韩文国际化检查

2026-10-03，`codex/japanese-korean-localization` 分支，随本记录提交的工作树。对应 `F-004` 和 `V-007`。环境：macOS 27.0.1（26A434）、Xcode 27.0 / Swift 6.4。

## 自动检查

- `make verify XCODE_FLAGS=CODE_SIGNING_ALLOWED=NO`：官网版与商店版构建、120 个 Swift 测试、4 个 Python 文案校验测试、文档、模板、9 个 Intent 检查通过。
- 语言测试覆盖 `ja-JP` / `ko-KR`、系统偏好顺序、不支持语言的回退、五个设置值的 JSON 持久化、中英文旧标识、日文与韩文资源解析、默认文件名、菜单及用户自定义名称保持不变。
- 四个 string catalog 共 249 个键，每种语言均完整；三个系统服务名每种语言完整。检查格式参数的索引、类型、数量，以及 App Shortcuts 的 `${applicationName}`。
- 两个构建产物逐键检查 `.lproj` 里的共享文案、Intent 文案、快捷指令短语、权限说明与服务名称，均与源资源相同。此项已纳入 `make verify`。

## 隔离界面

预览编译的是生产 `AppModel`、设置五个分栏、欢迎窗口与公共组件，仅将 `SharedStore` 换成内存实现。使用独立预览 bundle ID；不运行正式主程序 AppDelegate，不注册 agent 或 Finder 扩展，不访问已安装 RightKit 的配置。没有测试授权目录，也没有执行文件操作。预览是商店版 UI，官网版自动更新设置的视觉未单独检查。

复现：

```sh
make verify XCODE_FLAGS=CODE_SIGNING_ALLOWED=NO
python3 scripts/e2e/localization_preview.py
open -n .build/localization-preview/RightKitLocalizationPreview.app --args ja
# 也可使用 --args ko，直接以韩文启动。
```

通过 Window 菜单在设置与欢迎窗口间切换。通用页滚动到语言选项，确认五个选项；切换日文、韩文；检查状态卡片、内置模板名和按钮。缩小到 420 × 360 的最小内容尺寸，检查滚动和工具栏溢出菜单；通过主题选项检查深色。预览中不要使用文件导入、授权、应用检测或系统设置动作。

观察结果：欢迎窗口、通用页与新建文件页的已检查文案没有遮挡按钮；最小窗口内容正常滚动，分栏仍可通过系统溢出菜单访问。日文与韩文互相切换后，设置和欢迎窗口的文案更新。发现欢迎窗口状态卡片仅观察扩展状态，切换语言后残留旧语言；已补充语言依赖，并复测状态卡片与欢迎正文都切换到韩文。

截图：

- [日文欢迎窗口](ja-welcome.png)
- [日文通用页](ja-settings.png)
- [日文深色最小窗口](ja-dark-small.png)
- [韩文欢迎窗口，状态卡片刷新修复后](ko-welcome.png)
- [韩文通用页](ko-settings.png)
- [韩文新建文件页](ko-newfile.png)
- [韩文新建文件最小窗口](ko-newfile-small.png)
- [韩文通用最小窗口](ko-general-small.png)
- [韩文深色最小窗口](ko-dark-small.png)

## 尚未覆盖

`V-007` 仍为 `Planned`：未运行真实 Finder 菜单与菜单栏验收、主程序跨进程重启持久化、macOS 应用语言切换后的系统服务/快捷指令/权限提示、翻译网站实际目标语言、增强对比度与 VoiceOver。隔离截图与资源检查不替代这些系统集成验收，也不是签名、公证或发布证据。待办已写入 `TASK.md`。

术语参考 Apple 的[日文登录项与扩展说明](https://support.apple.com/ja-jp/guide/mac-help/-mtusr003/mac)和[韩文说明](https://support.apple.com/ko-kr/guide/mac-help/-mtusr003/mac)。系统语言匹配使用 [Bundle.preferredLocalizations](https://developer.apple.com/documentation/foundation/bundle/preferredlocalizations)。
