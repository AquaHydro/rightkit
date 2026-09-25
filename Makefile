DERIVED := .build/DerivedData
APP := $(DERIVED)/Build/Products/Debug/RightKit.app
XCODEBUILD := xcodebuild -project RightKit.xcodeproj -scheme RightKit -derivedDataPath $(DERIVED) -allowProvisioningUpdates

.PHONY: generate build build-appstore test verify run release release-unsigned release-appstore upload-appstore website website-serve

generate:
	xcodegen generate

build: generate
	$(XCODEBUILD) -configuration Debug build

# 商店版 Debug 构建（technical.md 发布渠道与标识）。
build-appstore: generate
	xcodebuild -project RightKit.xcodeproj -scheme "RightKit App Store" -derivedDataPath $(DERIVED) -allowProvisioningUpdates -configuration Debug-AppStore build

test: generate
	$(XCODEBUILD) test

# 统一验证入口（technical.md 构建与验证入口）。
verify: test build build-appstore
	python3 scripts/check_docs.py
	python3 scripts/strings.py check
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

# 官网：生成 website/dist，中文在 /，英文在 /en/。只用 Python 标准库。
website:
	python3 website/build.py

# 本地预览官网：http://localhost:8000
website-serve: website
	python3 -m http.server 8000 --directory website/dist
