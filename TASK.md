# 待办

需要人工配合、或者只能在真机上完成的事项。完成后勾选；整组做完就删掉那一节。编号含义见[功能规格](docs/features.md)和[验收](docs/verification.md)。

## 上架前必须完成

资料都在 [App Store 上架资料](docs/app-store.md)：商店名「RightKit: Finder Toolkit」（中文区「RightKit 访达工具箱」），价格 1 美元，版权 `2026 Liao Yiliang`，联系邮箱 `contact@yiliang.me`（电话直接填在 App Store Connect）。
首次提审过程、分工和剩余步骤见 [提审交接记录](docs/app-store-submission-log.md)。2026-09-26 已由用户提交审核，当前等待审核；通过后仍需用户手动发布。

- [x] 官网和隐私政策上线：`https://rightkit.yiliang.app`（Cloudflare Pages 项目 `rightkit`，`make website-deploy` 部署）。隐私政策 `/privacy/`、`/en/privacy/`。以后换正式域名时改 `website/site.json` 的 `url` 并重新部署。
- [x] 在 App Store Connect 新建 App：bundle ID `app.rightkit.mac.store`，按上架资料填名称、副标题、描述、关键词、隐私政策和技术支持网址、价格、隐私问卷（不收集数据）、年龄分级（4+）。隐私答复已发布。
- [x] 送审备注：把上架资料里的英文备注贴进 App Review Information，不需要演示账号。
- [x] App 沙盒信息：`com.apple.security.temporary-exception.apple-events` 已在 App Sandbox Information 填写 Finder 重启用途和审核方法，见 `docs/app-store.md`。
- [x] 商店截图：`docs/evidence/app-store/zh` 与 `en` 各 5 张 2560 × 1600 产品图，已上传 App Store Connect 并按 01 至 05 排序。英文产品图用英文介绍配中文实机界面，用户已接受。
- [x] 上传商店版：本机 `make upload-appstore` 上传 `0.1.1 (4)`；App Store Connect 显示上传完成、二进制已验证。出口合规从 `Info.plist` 读为「否」。
- [x] 设置 App 供应国家或地区：App Store Connect 显示全部 175 个国家或地区为「App 发布时供应」，包含中国大陆。
- [x] 付费 App 协议与商务资料：Connect 显示付费协议有效、银行账户可用、报税表使用中；该 App 的欧盟数字服务法交易商声明已提交。
- [x] 用户正式提审：2026-09-26 12:32 提交 `0.1.1 (4)`，提交 ID `01dc116b-b85e-4cf4-950b-1fe5dd8056ff`；Connect 显示「等待审核」。
- [ ] 处理 Apple 的实际审核反馈，直到审核通过。
- [ ] 审核通过后由用户手动发布，并检查商店页面、购买和首次启动；发布方式当前不是自动发布。

## 自动化发布（GitHub Actions）

- [x] App Store Connect API key（Admin，`4UBZD7P35G`）已存进仓库 secrets：`ASC_KEY_P8_BASE64`、`ASC_KEY_ID`。
- [x] 仓库已建 `app-store` 环境，只允许 `v*` 标签使用。私有仓库的免费方案不能要求手动批准。
- [ ] 存 `ASC_ISSUER_ID`：`gh secret set ASC_ISSUER_ID`。
- [ ] 在钥匙串访问里同时选中「Developer ID Application: YiLiang Liao」和「Apple Development: YiLiang Liao」两个证书（连同私钥），导出成一个 `.p12` 并设密码；再存 `SIGNING_CERTS_P12_BASE64`（`base64 -i certs.p12 | gh secret set SIGNING_CERTS_P12_BASE64`）和 `SIGNING_CERTS_P12_PASSWORD`。商店版证书由 Apple 云端代管，不用导出。
- [ ] 试运行：Actions → Release → Run workflow，两个渠道都应通过签名、公证和检查。
- [ ] 第一次正式发布：改 `project.yml` 的 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`，合并后推标签（如 `git tag v0.2.0 && git push origin v0.2.0`），看 Release 工作流跑通。

## 真机验收

- [x] `V-002`：默认值改过（登录时启动、监视目录、常用目录），需要重跑。2026-09-26 通过。
- [x] `V-004`：欢迎窗口新增了授权行和登录时启动。2026-09-26 浅色和深色通过。
- [x] `V-006`：重启访达，官网版和商店版各一次，包括拒绝自动化授权的情况。2026-09-26 两个渠道都通过。
- [x] `V-080`：文件夹授权，包括重启主程序、重新登录后仍能访问，以及授权失效后的「重新授权…」。2026-09-26 其余都已通过，欢迎窗口「更改…」也已通过（主目录改为桌面，两个默认列表同步更新），重新登录后的新建、复制、移动、删除均通过，无需重新授权。
- [ ] `V-081`：发布第一个正式 Release 后，在官网版里确认「有新版本」和「已是最新」两种提示。
- [x] `V-082`：两个版本同时安装时设置互不影响。2026-09-26 通过，签名检查也在当前代码上重跑过。
- [x] `V-083`：沙盒回归，包括替身、壁纸、文件夹图标、快捷指令、agent 签名校验、后台拉起不开窗口、扩展状态和 `iconutil`。2026-09-26 其余都已通过，快捷指令授权目录输出和未授权目录拒绝已复测通过，修复了系统不同路径导致的误拒绝；后台项目关闭后的菜单回退也已通过，恢复开启后命令正常。

## 官网版发布

- [ ] 第一个 GitHub Release：由 Release 工作流在推标签时自动创建（见上一节）。标签是 `v` 加三段数字，并且等于 `MARKETING_VERSION`。
- [ ] 商店版上架后，在官网下载按钮旁放商店链接。

## 已知问题

- [ ] 仓库还是私有：官网的下载、GitHub、更新日志链接和官网版的检查更新都是 404。公开仓库后，把商店版「关于」和官网的反馈入口改回 GitHub Issues（或保留邮件）。

- [ ] 两个版本同时安装时，系统服务（翻译、二维码）的 `NSPortName` 都是 `RightKit`。2026-09-26 真机确认：两版都注册了同名服务，请求交给了其中一版，功能正常，但用户不能指定由哪一版处理。是否按渠道区分待定。
- [ ] 系统服务的菜单名只写了中文（Info.plist 的 `NSServices`），英文系统下也显示中文。
- [ ] 扩展读取全局 `AppleInterfaceStyle` 判断深浅色，隐私清单按 `CA92.1` 声明。如果审核对此有疑问，改用其他方式取外观。
