DERIVED := .build/DerivedData
APP := $(DERIVED)/Build/Products/Debug/RightKit.app
XCODEBUILD := xcodebuild -project RightKit.xcodeproj -scheme RightKit -derivedDataPath $(DERIVED) -allowProvisioningUpdates

.PHONY: generate build test verify run

generate:
	xcodegen generate

build: generate
	$(XCODEBUILD) -configuration Debug build

test: generate
	$(XCODEBUILD) test

# 统一验证入口（technical.md 构建与验证入口）。
verify: test build
	python3 scripts/check_docs.py
	python3 scripts/strings.py check
	python3 scripts/check_office_templates.py
	python3 scripts/check_intents.py $(APP)
	git diff --check

# 自动化环境跳过登录项注册。
run: build
	open --env RIGHTKIT_SKIP_LOGIN_ITEM=1 $(APP)
