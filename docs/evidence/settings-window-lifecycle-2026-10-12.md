# 设置窗口寿命回归记录

日期：2026-10-12。范围：`V-002` 设置分栏寿命、`F-014` 模板导入取消。环境：macOS 27.0.1（Build 26A434），隔离 Release 设置探针。

## 发现与修复

应用未激活时，同一个真实 `NSWindow` 连续两次关闭并重新显示，第二次可能没有新的 key 或遮挡状态通知。修复前，第二次重开记录 `visible=true`、`key=false`、`active=false`、`occlusion=8194`，但当前分栏承载视图为空。

`WindowOpener` 现在在实际调用 SwiftUI `openWindow(id: "settings")` 前发出明确的设置打开请求，容器幂等恢复已关闭页面并重新监听关闭。已经打开的页面继续复用，不需要轮询，也不依赖系统是否允许应用激活。

## 重复验证

```sh
python3 scripts/perf/run_settings.py --variant working --e2e --inactive --rounds 1 --output .build/settings-e2e
python3 scripts/perf/run_settings.py --variant working --e2e --inactive --no-build --rounds 1 --output .build/settings-e2e
```

两次运行均通过 29 个布尔检查。检查覆盖缓存复用、隐藏页脱离原生视图树、重复打开不重建、真实关闭释放页面、真实 SwiftUI 打开请求连续两次恢复当前页，以及切页和关窗对模板导入的取消与副本清理。探针只使用自己的临时文件、独立偏好域和内存设置，不启动生产 AppDelegate、agent 或 Finder 扩展。

模板取消检查使用真实 `NewFilePane` 导入任务与 `TemplateLibrary` 文件复制，在副本已写入、尚未提交设置时暂停。检查取消后设置没有新增模板、副本目录为空、源文件保持原样。测试源副本绕过文件选择与名称对话框，因此这部分属于组件集成验收，不能替代真实面板操作。

聚焦 `SettingsPageContainerTests` 共 5 个测试通过，包括关闭期间更新分栏后恢复、重复打开幂等、第二次关闭再次释放缓存。单元测试的窗口通知由测试显式发出，真实窗口通知和 SwiftUI 打开由隔离探针另外验证。

本地重复证据：`.build/settings-e2e/working.json`、`summary.json`、`working.log`、`working.json.nonkey-reopen.png`、`container-tests.log`。已查看非 key 重开截图，当前页有实际内容。原有语言位图差异仅是烟雾检查，翻译语义和外部辅助功能树仍需独立界面验收。完整 Finder、签名沙盒、文件选择面板和发布验收由主验收记录负责。
