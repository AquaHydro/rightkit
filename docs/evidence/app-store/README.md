# App Store 产品图

`zh/` 和 `en/` 各有 5 张 2560 × 1600 PNG，顺序与 [上架资料](../../app-store.md#截图) 一致。用 `node scripts/appstore/render_product_images.mjs` 从真实界面截图和仓库内的 Riko 素材重新渲染。先运行 `npm install --prefix .build/appstore-screenshots --no-save playwright` 安装临时渲染依赖，不修改正式依赖。

## 画面来源与状态

- `source/zh/01` 至 `04` 是电脑控制在「RightKit 演示」目录取得的真实 Finder 菜单原图；演示文件名是笔记、发布计划、封面等，不含用户私人文件名。取景时运行的是当前已启用的 RightKit Finder 扩展；这四张并非从上传至 App Store Connect 的安装包重新安装后拍摄。
- `source/zh/05-settings-status.png` 从既有真机验收截图的顶部裁切，只保留「通用」与「访达扩展已启用」状态，不包含个人主目录路径。
- 角色使用 `website/assets/character/feature-*.png` 和 `status-ready.png`，没有让模型重画 UI、文字或 Riko 身份特征。
- `zh/` 为中文产品图，`en/` 的营销标题和说明已英文化，内嵌的真实界面仍是中文。用户已确认接受这个组合；不要用图像模型伪造 Finder 菜单文字。
- 两套图片已上传 App Store Connect，各 5 张并按 01 至 05 排序；尚未提交审核。发布前仍需逐张检查文案、菜单和角色发卡。

用于 Riko 二次创作的提示词见 [PROMPTS.md](PROMPTS.md)。
