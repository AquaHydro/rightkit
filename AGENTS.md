# AGENTS.md

## 用户与沟通

- 用户名为氢氧根，是独立产品开发者和设计师，主要开发 macOS、Electron 和 Web 产品。
- 优先使用简洁、易懂的中文。用户可能使用语音输入，应根据上下文理解目标，而不是拘泥于措辞。
- 用户重视界面、体验、动画、细节、可维护代码和现代实践。涉及平台行为时优先查阅官方文档。
- 除聊天和代码外，生成的邮件、应用文案等内容不要使用 em dash。

## 开始工作前

1. 阅读 `README.md`、`CONTEXT.md`、`docs/features.md`、`DESIGN.md`、`docs/technical.md`、`docs/verification.md` 和 `docs/roadmap.md`。
2. 行为以 `docs/features.md` 为准，视觉以 `DESIGN.md` 为准。不要对照机器上另外安装的应用来增删功能或改默认值。
3. 使用已有 `F-xxx` 与 `V-xxx` 编号。不要重排、复用或静默改变编号含义。

## 工作方式

- 主代理负责主要决策、审查和集成，小任务可直接处理。
- 大型且边界清晰、能独立验证的实现任务可委派给子代理并行完成。提供足够上下文（相关 `F-xxx`、文件边界、验收方式），由主代理审查后再集成。同时运行的子代理保持少量。
- 先确认真实瓶颈再做性能优化，并对同一工作负载给出前后数据。
- 视觉任务必须检查实际界面和交互。构建通过不能替代视觉验证。
- 优先在实现前或实现同时编写有价值的测试。用户可见流程与跨系统行为优先使用可重复的端到端验证，并保存截图、日志或结构化结果。

## 安全边界

- 日常开发不要修改、覆盖、重新签名或替换 `/Applications/RightKit.app`，也不要读写已经安装的 RightKit 的配置、模板、常用目录和开关。
- 例外：执行 `TASK.md` 里的真机验收时，可以把本仓库构建的 RightKit 装进 `/Applications/RightKit.app`、启动它，并把 `~/Library/Containers` 和 `~/Library/Group Containers` 里的 `app.rightkit.*` 移到废纸篓，以得到全新安装状态。
- 例外：用户要求录制审核演示或执行真机验收时，可以临时切换两个渠道的 Finder 扩展，避免重复菜单；先记录原状态，任务结束后恢复。可以启动对应构建的独立副本、授权仅含测试文件的演示目录，并在说明影响后重启 Finder。这些必要准备无需再次确认；不因此授权覆盖已安装应用、清空用户配置或向 Apple 上传、回复、提交审核。
- 本仓库的官网版应用使用 `app.rightkit.mac`，扩展使用 `app.rightkit.mac.finder`；商店版应用使用 `app.rightkit.mac.store`，扩展使用 `app.rightkit.mac.store.finder`。
- 测试只用临时目录和测试自己创建的文件。永久删除只能删除这些文件。

## 文档

- `CONTEXT.md` 只保存术语，不放实现方案、规格或进度。
- `docs/features.md` 是功能规格。
- `docs/verification.md` 是验收标准。
- 改变行为时，同步更新功能规格和验收用例。
- 完成文档更改后运行 `python3 scripts/check_docs.py`。

## 工程结构

按 `docs/technical.md` 实现：SwiftUI 主程序、轻量 Finder Sync Extension、转发 XPC 请求的 `RightKitAgent`，以及共享的纯逻辑模块。
