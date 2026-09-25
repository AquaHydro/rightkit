#!/bin/zsh
# 构建商店版 RightKit：归档（Release-AppStore）→ 导出 .pkg → 检查签名和二进制 → 可选上传 App Store Connect。
#
# 上传使用 Xcode 里登录的 Apple 账号，凭据不进仓库。
#
# 用法：scripts/release/release_appstore.sh            只归档、导出和检查
#       UPLOAD=1 scripts/release/release_appstore.sh   检查通过后上传 App Store Connect
set -euo pipefail

root=${0:A:h:h:h}
cd "$root"
out=.build/release-appstore
archive=$out/RightKit.xcarchive
export_dir=$out/export
export_options=scripts/release/ExportOptions-AppStore.plist

rm -rf "$out"
mkdir -p "$out"

xcodegen generate >/dev/null
xcodebuild -project RightKit.xcodeproj -scheme "RightKit App Store" -configuration Release-AppStore \
  -derivedDataPath .build/DerivedData-AppStore -archivePath "$archive" \
  -allowProvisioningUpdates archive | tail -1
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$export_dir" \
  -exportOptionsPlist "$export_options" -allowProvisioningUpdates | tail -1

# 归档的中间产物里也有一份同 ID 的扩展，LaunchServices 会抢先注册它。用完就注销并删除。
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
intermediates=.build/DerivedData-AppStore/Build/Intermediates.noindex/ArchiveIntermediates
for leftover in $intermediates/**/RightKit.app(N/) "$archive"/Products/Applications/RightKit.app(N/); do
  pluginkit -r "$PWD/$leftover/Contents/PlugIns/RightKitFinder.appex" 2>/dev/null || true
  $lsregister -u "$PWD/$leftover" 2>/dev/null || true
done
rm -rf "$intermediates"

pkg=$(print -l "$export_dir"/*.pkg(N) | head -1)
[[ -n $pkg ]] || { echo "error: no .pkg exported" >&2; exit 1; }
pkgutil --check-signature "$pkg" | head -3

# 从 .pkg 里取出 app 检查签名（V-082）。
expanded=$out/expanded
pkgutil --expand-full "$pkg" "$expanded"
app=$(print -l "$expanded"/**/RightKit.app(N/) | head -1)
[[ -n $app ]] || { echo "error: RightKit.app not found in $pkg" >&2; exit 1; }
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist")
build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$app/Contents/Info.plist")
echo "RightKit App Store $version ($build)"
scripts/release/check_signature.sh "$app" appstore
rm -rf "$expanded"

if [[ -n ${UPLOAD:-} ]]; then
  upload_options=$out/ExportOptions-Upload.plist
  cp "$export_options" "$upload_options"
  /usr/libexec/PlistBuddy -c "Set :destination upload" "$upload_options"
  xcodebuild -exportArchive -archivePath "$archive" -exportPath "$out/upload" \
    -exportOptionsPlist "$upload_options" -allowProvisioningUpdates | tail -1
  echo "Uploaded to App Store Connect."
fi

echo "Done: $pkg"
