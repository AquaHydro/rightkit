# App Store 产品图

`zh/` 和 `en/` 各有 5 张 2560 × 1600 PNG，顺序与 [上架资料](../../app-store.md#截图) 一致。2026-10-02 已重拍并重新渲染，**已上传到 App Store Connect 的 0.1.3 待提交草稿，尚未提交审核或发布；线上 0.1.2 仍使用旧图**。

运行 `node scripts/appstore/render_product_images.mjs` 从 `source/{zh,en}/01` 至 `05` 的真实界面 PNG 和仓库内 Riko 素材重新渲染。临时依赖安装方法：`npm install --prefix .build/appstore-screenshots --no-save playwright`，不修改正式依赖。

## 2026-10-02 拍摄与检查

- macOS 27.0.1（26A434）；仓库提交 `52467d5`，0.1.2 (6)，使用商店版 Debug 构建。只为拍摄临时使用独立应用标识 `app.rightkit.capture`、独立 App Group 和进程名；没有改动应用界面源码，也没有覆盖已安装应用或读写其配置。本组截图不是从发布的 `.pkg` 重新安装后拍摄。
- 只授权拍摄新建的 `RightKit Capture` 演示目录，文件包括 Cover.png、Notes.txt 和 Release Plan.md，发送目标是 Projects、Assets 和 Archive。Finder 侧边栏没有进入产品图，不含个人文件名或路径。
- 01 为文件夹空白处的新建子菜单；02 为图片的移动目标；03 为图片的应用打开，演示终端和 Xcode；04 为图片工具箱，真实显示 15 项，文件夹专用的「解散文件夹」按规格不出现。
- 05 为新建文件设置页的顶部取景，包含创建选项、类型开关和通过真实文件选择面板导入的 Notes 自定义模板。取景没有覆盖全部 12 种类型；下方类型和拖动提示仍在真实窗口中。
- 英文原图使用 Finder 的 `AppleLanguages = (en)` 和 RightKit 的 English 语言。演示配置中的终端显示名同步使用 Terminal。两套源图分别拍摄，没有用模型生成或替换菜单文字。
- 临时关闭 QQ 闪传、Ghostty 两项、ToDesk 和 Claude 三项服务，以及微信输入法 Finder 扩展。Ghostty 两项实际属于系统服务，QQ 位于「文本」分类。拍摄期间还关闭两个正式 RightKit 扩展，避免重复菜单。
- 已检查十张产品图的标题、完整子菜单、语言、指针位置和角色遮挡；菜单中没有上述第三方服务或扩展项目。菜单与设置图只是静态展示，不代替功能验收。真实菜单回调见 [拍摄日志](capture/2026-10-02-menu.log)，扩展开关的拍摄前与恢复状态见 `capture/`。
- 拍摄后已恢复全部服务到原来的开启状态，两个正式 RightKit 和微信输入法扩展均恢复启用；删除 Finder 临时语言键并重启 Finder。演示应用、独立容器和演示文件夹已移到废纸篓，测试扩展已取消注册。

## 取景与素材

原始窗口截图只做裁切和 PNG 编码，没有修字或重画。坐标为 `(左, 上, 右, 下)`：

| 图片 | 两种语言使用的取景坐标 |
| --- | --- |
| 01 | `(0, 0, 1900, 1320)` |
| 02、03 | `(0, 0, 2200, 1450)` |
| 04 | `(0, 200, 2300, 1846)` |
| 05 | `(550, 0, 2390, 1115)` |

菜单取景及产品图排版保留完整子菜单和上下余量。`overview.png` 是中英文十张新图的总览。

角色使用 `website/assets/character/feature-*.png` 和 `status-ready.png`。没有重画 Riko。用于既有 Riko 二次创作的提示词见 [PROMPTS.md](PROMPTS.md)。

`source/zh/` 里旧的 JPG 和 `05-settings-status.png` 保留作历史来源，不再被当前渲染器使用。旧图曾上传至 App Store Connect，自 0.1.1 起沿用；旧英文图内嵌中文界面、部分菜单含 QQ/Ghostty、第五张只有状态卡。当前 PNG 已替换 0.1.3 草稿中的中英文截图，线上替换需等该版本审核并发布。

## App Store Connect 上传核对

2026-10-02 使用 asc CLI 创建 macOS `0.1.3` 草稿（版本 ID `196f557e-0fa3-4cc3-901f-3d1404701fb3`，`PREPARE_FOR_SUBMISSION`，手动发布），沿用 0.1.2 的中英文描述、关键词和网址等资料，没有复制旧版本的新功能说明。只替换草稿中的 `APP_DESKTOP` 截图。

`zh-Hans` 和 `en-US` 各 5 张，01 至 05 顺序、每个文件的 MD5 与仓库原图一致，尺寸均为 2560 × 1600，Apple 处理状态全部 `COMPLETE`。校验结果见 [上传记录](capture/2026-10-02-asc-upload.json)。本次没有关联新构建或提交审核。
