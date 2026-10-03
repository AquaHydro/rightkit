DERIVED := .build/DerivedData
APP := $(DERIVED)/Build/Products/Debug/RightKit.app
# CI 没有签名证书，传 XCODE_FLAGS="CODE_SIGNING_ALLOWED=NO" 只做编译和测试（.github/workflows/ci.yml）。
XCODE_FLAGS ?=
XCODEBUILD := xcodebuild -project RightKit.xcodeproj -scheme RightKit -derivedDataPath $(DERIVED) -allowProvisioningUpdates $(XCODE_FLAGS)

.PHONY: generate build build-appstore test verify run release release-unsigned release-appstore upload-appstore website website-serve website-deploy website-test

generate:
	xcodegen generate

build: generate
	$(XCODEBUILD) -configuration Debug build

# 商店版 Debug 构建（technical.md 发布渠道与标识）。
build-appstore: generate
	xcodebuild -project RightKit.xcodeproj -scheme "RightKit App Store" -derivedDataPath $(DERIVED) -allowProvisioningUpdates -configuration Debug-AppStore $(XCODE_FLAGS) build

test: generate
	$(XCODEBUILD) test

# 统一验证入口（technical.md 构建与验证入口）。
verify: test build build-appstore
	python3 scripts/check_docs.py
	$(MAKE) website-test
	python3 -B -m unittest discover -s scripts/tests
	python3 scripts/strings.py check $(APP)
	python3 scripts/strings.py check .build/DerivedData/Build/Products/Debug-AppStore/RightKit.app
	python3 scripts/check_office_templates.py
	python3 scripts/check_intents.py $(APP)
	git diff --check

# Developer ID 签名、公证、钉票并打 DMG。公证凭据见 scripts/release/release.sh。
release:
	scripts/release/release.sh

# 只归档、导出、打包并检查签名，不提交公证。
release-unsigned:
	SKIP_NOTARIZE=1 scripts/release/release.sh

# 商店版：归档、导出 .pkg 并检查签名和二进制（V-082）。
release-appstore:
	scripts/release/release_appstore.sh

# 检查通过后上传 App Store Connect，使用 Xcode 里登录的账号。
upload-appstore:
	UPLOAD=1 scripts/release/release_appstore.sh

# 自动化环境跳过登录项注册。
run: build
	open --env RIGHTKIT_SKIP_LOGIN_ITEM=1 $(APP)

# 官网：生成 website/dist，中文在 /，英文在 /en/；ak-ui 风格在 /ak/。只用 Python 标准库。
website:
	python3 website/build.py

# 本地预览官网：http://localhost:8000
website-serve: website
	python3 -m http.server 8000 --directory website/dist

# 部署官网到 Cloudflare Pages 项目 rightkit（https://rightkit.yiliang.app）。第一次会打开浏览器登录。
website-deploy: website
	npx -y wrangler@latest pages deploy website/dist --project-name rightkit --branch main

# 官网国际化：实际静态产物检查和浏览器语言控制器的失败场景。
website-test:
	python3 -B -m unittest discover -s website/tests -p 'test_*.py'
	node --test website/tests/language.test.mjs
