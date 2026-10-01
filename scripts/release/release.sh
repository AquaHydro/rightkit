#!/bin/zsh
# 构建可分发的 RightKit：归档 → Developer ID 导出 → 公证 app → 钉票 → DMG → 公证 DMG → 钉票。
#
# 本机公证凭据只需配置一次（App 专用密码在 account.apple.com 生成，不进仓库）：
#   xcrun notarytool store-credentials RightKit --apple-id <Apple ID> --team-id Q9C87Z9H4G
# 设置了 ASC_KEY_PATH、ASC_KEY_ID、ASC_ISSUER_ID 时改用 App Store Connect API key（CI）。
#
# 用法：scripts/release/release.sh            完整流程
#       SKIP_NOTARIZE=1 scripts/release/release.sh   只归档、导出、打包，用于检查签名
set -euo pipefail

root=${0:A:h:h:h}
cd "$root"
profile=${NOTARY_PROFILE:-RightKit}
out=.build/release
archive=$out/RightKit.xcarchive
export_dir=$out/export
app=$export_dir/RightKit.app

rm -rf "$out"
mkdir -p "$out"

# CI 用 App Store Connect API key 做自动签名和公证（.github/workflows/release.yml）；本机用 Xcode 里登录的账号。
auth=()
if [[ -n ${ASC_KEY_PATH:-} ]]; then
  auth=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

xcodegen generate >/dev/null
xcodebuild -project RightKit.xcodeproj -scheme RightKit -configuration Release \
  -derivedDataPath .build/DerivedData-Release -archivePath "$archive" \
  -allowProvisioningUpdates "${auth[@]}" archive | tail -1
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$export_dir" \
  -exportOptionsPlist scripts/release/ExportOptions.plist -allowProvisioningUpdates "${auth[@]}" | tail -1

# 归档的中间产物里也有一份同 ID 的扩展，LaunchServices 会抢先注册它。用完就注销并删除。
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
intermediates=.build/DerivedData-Release/Build/Intermediates.noindex/ArchiveIntermediates
for leftover in $intermediates/**/RightKit.app(N/) "$archive"/Products/Applications/RightKit.app(N/); do
  pluginkit -r "$PWD/$leftover/Contents/PlugIns/RightKitFinder.appex" 2>/dev/null || true
  $lsregister -u "$PWD/$leftover" 2>/dev/null || true
done
rm -rf "$intermediates"

version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist")
build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$app/Contents/Info.plist")
dmg=$out/RightKit-$version.dmg
echo "RightKit $version ($build)"

scripts/release/check_signature.sh "$app"

notarize() {
  if [[ -n ${ASC_KEY_PATH:-} ]]; then
    xcrun notarytool submit "$1" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" --wait --timeout 30m
  else
    xcrun notarytool submit "$1" --keychain-profile "$profile" --wait --timeout 30m
  fi
}

if [[ -z ${SKIP_NOTARIZE:-} ]]; then
  ditto -c -k --keepParent "$app" "$out/RightKit.zip"
  notarize "$out/RightKit.zip"
  xcrun stapler staple "$app"
fi

# DMG：app 加一个指向 /Applications 的替身。
staging=$out/dmg
mkdir -p "$staging"
ditto "$app" "$staging/RightKit.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname "RightKit" -srcfolder "$staging" -fs APFS -format ULFO -ov "$dmg" >/dev/null
identity=$(codesign -dvv "$app" 2>&1 | sed -n 's/^Authority=\(Developer ID Application:.*\)$/\1/p' | head -1)
codesign --sign "$identity" --timestamp "$dmg"

if [[ -z ${SKIP_NOTARIZE:-} ]]; then
  notarize "$dmg"
  xcrun stapler staple "$dmg"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg"
  spctl --assess --type execute --verbose=2 "$app"
fi

shasum -a 256 "$dmg"
echo "Done: $dmg"
