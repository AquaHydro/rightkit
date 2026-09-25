# RightKit

RightKit 是 macOS 访达的右键菜单工具。用户用它新建文件、把项目复制或移动到常用位置、用指定应用打开，以及执行一组文件工具。

最低系统是 macOS 26。主程序负责设置、确认和耗时操作；访达扩展只负责在用户配置的监视目录内按当前选择组装菜单。监视目录由用户在首次启动时授权。

同一份代码发布两个渠道：官网版从官网跳转 GitHub Release 免费下载，商店版在 Mac App Store 付费购买。两者都运行在 App Sandbox 里，功能相同，差异见[功能规格](docs/features.md)的 `F-082`。

## 实现时读这些

1. [功能规格](docs/features.md)：要做哪些功能、默认值、菜单何时出现、失败时怎么提示。
2. [设计规范](DESIGN.md)：窗口、菜单、对话框和视觉怎么做。
3. [工程边界](docs/technical.md)：目标划分、设置数据、扩展和主程序怎么通信。
4. [验收](docs/verification.md)：做完怎样算通过。
5. [实现顺序](docs/roadmap.md)：建议的开发顺序。

行为以功能规格为准，视觉以设计规范为准。不要对照机器上另外安装的应用来增删功能或决定默认值。

## 构建

需要 Xcode 27 和 XcodeGen。工程由 `project.yml` 生成，生成的 `RightKit.xcodeproj` 也提交在仓库里。

```sh
make verify   # 生成工程、运行全部测试、构建两个渠道，再做文档、文案、模板、Intent 检查
make run      # 构建 Debug 版并启动（跳过登录项注册）
make release  # Developer ID 签名、公证并打 DMG，产物在 .build/release/
make release-appstore  # 商店版：归档、导出 .pkg 并检查签名和二进制，产物在 .build/release-appstore/
make upload-appstore   # 同上，检查通过后上传 App Store Connect
```

首次运行后，在「系统设置 → 通用 → 登录项与扩展」里打开 RightKit 的访达扩展。

## 文档维护

需要人工配合或真机完成的事项记在 [TASK.md](TASK.md)。

PR 由 GitHub Actions 跑 `make verify`；推 `v` 开头的标签会自动签名、公证、发布 GitHub Release 并上传商店版，见[工程边界](docs/technical.md)的「发布」。

功能编号 `F-xxx` 和验收编号 `V-xxx` 一经分配就不要复用。废弃的功能保留编号，并写明不实现。

```sh
python3 scripts/check_docs.py
```
