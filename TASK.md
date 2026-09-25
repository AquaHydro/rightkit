# 待办

需要人工配合、或者只能在真机上完成的事项。完成后勾选；整组做完就删掉那一节。编号含义见[功能规格](docs/features.md)和[验收](docs/verification.md)。

## 上架前必须完成

资料都在 [App Store 上架资料](docs/app-store.md)：商店名「RightKit: Finder Toolkit」（中文区「RightKit 访达工具箱」），价格 1 美元，版权 `2026 Liao Yiliang`，联系邮箱 `contact@yiliang.me`（电话直接填在 App Store Connect）。

- [x] 官网和隐私政策上线：`https://rightkit.yiliang.app`（Cloudflare Pages 项目 `rightkit`，`make website-deploy` 部署）。隐私政策 `/privacy/`、`/en/privacy/`。以后换正式域名时改 `website/site.json` 的 `url` 并重新部署。
- [ ] 在 App Store Connect 新建 App：bundle ID `app.rightkit.mac.store`，按上架资料填名称、副标题、描述、关键词、隐私政策和技术支持网址、价格、隐私问卷（不收集数据）、年龄分级（4+）。
- [ ] 送审备注：把上架资料里的英文备注贴进 App Review Information，不需要演示账号。
- [ ] 商店截图：按上架资料的「截图」一节，中英文各 5 张，16:10。
- [ ] 上传商店版：本机 `make upload-appstore`，或推标签后由 Release 工作流上传；确认通过 App Store Connect 的自动校验。出口合规已在 `Info.plist` 声明，不会再问。

## 自动化发布（GitHub Actions）

- [ ] 在 App Store Connect → 用户和访问 → 集成 → App Store Connect API 新建 key，角色选 Admin（要能创建 Developer ID 描述文件）。下载 `.p8`，记下 Key ID 和 Issuer ID。
- [ ] 在钥匙串访问里同时选中 Developer ID Application、Apple Distribution、3rd Party Mac Developer Installer 三个证书（连同私钥），导出成一个 `.p12`，设一个密码。
- [ ] 仓库 Settings → Secrets and variables → Actions 添加：`SIGNING_CERTS_P12_BASE64`（`base64 -i certs.p12 | pbcopy`）、`SIGNING_CERTS_P12_PASSWORD`、`ASC_KEY_P8_BASE64`（`base64 -i AuthKey_XXXX.p8 | pbcopy`）、`ASC_KEY_ID`、`ASC_ISSUER_ID`。
- [ ] 仓库 Settings → Environments 新建 `app-store`，按需勾选 Required reviewers，这样上传商店前要你点批准。
- [ ] 确认 PR 上的 CI 通过。`xcode-27` runner 还是公开预览，排队可能较慢。
- [ ] 第一次发布：改 `project.yml` 的 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`，合并后推标签（如 `git tag v0.2.0 && git push origin v0.2.0`），看 Release 工作流跑通。

## 真机验收

- [x] `V-002`：默认值改过（登录时启动、监视目录、常用目录），需要重跑。2026-09-26 通过。
- [x] `V-004`：欢迎窗口新增了授权行和登录时启动。2026-09-26 浅色和深色通过。
- [x] `V-006`：重启访达，官网版和商店版各一次，包括拒绝自动化授权的情况。2026-09-26 两个渠道都通过。
- [ ] `V-080`：文件夹授权，包括重启主程序、重新登录后仍能访问，以及授权失效后的「重新授权…」。2026-09-26 其余都已通过，还差重新登录，以及欢迎窗口「更改…」（要先清空配置）。
- [ ] `V-081`：发布第一个正式 Release 后，在官网版里确认「有新版本」和「已是最新」两种提示。
- [x] `V-082`：两个版本同时安装时设置互不影响。2026-09-26 通过，签名检查也在当前代码上重跑过。
- [ ] `V-083`：沙盒回归，包括替身、壁纸、文件夹图标、快捷指令、agent 签名校验、后台拉起不开窗口、扩展状态和 `iconutil`。2026-09-26 其余都已通过，还差快捷指令，以及在系统设置里停用后台项目后点菜单。

## 官网版发布

- [ ] 第一个 GitHub Release：由 Release 工作流在推标签时自动创建（见上一节）。标签是 `v` 加三段数字，并且等于 `MARKETING_VERSION`。
- [ ] 商店版上架后，在官网下载按钮旁放商店链接。

## 已知问题

- [ ] 仓库还是私有：官网的下载、GitHub、更新日志链接和官网版的检查更新都是 404。公开仓库后，把商店版「关于」和官网的反馈入口改回 GitHub Issues（或保留邮件）。

- [ ] 两个版本同时安装时，系统服务（翻译、二维码）的 `NSPortName` 都是 `RightKit`。2026-09-26 真机确认：两版都注册了同名服务，请求交给了其中一版，功能正常，但用户不能指定由哪一版处理。是否按渠道区分待定。
- [ ] 系统服务的菜单名只写了中文（Info.plist 的 `NSServices`），英文系统下也显示中文。
- [ ] 扩展读取全局 `AppleInterfaceStyle` 判断深浅色，隐私清单按 `CA92.1` 声明。如果审核对此有疑问，改用其他方式取外观。
