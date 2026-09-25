#!/bin/zsh
# 检查导出的 app（technical.md 发布渠道与标识、沙盒与文件访问；V-082）。
#
# 用法：scripts/release/check_signature.sh <RightKit.app> [direct|appstore]
#
# 两个渠道都检查：三个部件的签名标识、团队、沙盒、App Group、没有调试权限、agent 的 launchd 配置。
# 官网版另查 Developer ID、强化运行时、时间戳和网络权限；商店版另查 Apple Distribution、没有网络权限，
# 以及二进制里没有检查更新和 GitHub 的字符串。
set -euo pipefail
app=$1
channel=${2:-direct}
team=Q9C87Z9H4G
fail() { echo "error: $*" >&2; exit 1; }

case $channel in
  direct) app_id=app.rightkit.mac ;;
  appstore) app_id=app.rightkit.mac.store ;;
  *) fail "unknown channel $channel" ;;
esac
group=$team.$app_id

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

codesign --verify --deep --strict --verbose=2 "$app" 2>&1 | tail -1

# 读一项 entitlement；没有这一项时输出为空。
entitlement() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true
}

check() {
  local target=$1 identifier=$2
  local info; info=$(codesign -dvv "$target" 2>&1)
  [[ $info == *"Identifier=$identifier"* ]] || fail "$target identifier is not $identifier"
  [[ $info == *"TeamIdentifier=$team"* ]] || fail "$target team mismatch"
  if [[ $channel == direct ]]; then
    [[ $info == *"Authority=Developer ID Application"* ]] || fail "$target is not signed with Developer ID"
    [[ $info == *"flags=0x10000(runtime)"* ]] || fail "$target lacks hardened runtime"
    [[ $info == *"Timestamp="* ]] || fail "$target has no secure timestamp"
  else
    [[ $info == *"Authority=Apple Distribution"* || $info == *"Authority=3rd Party Mac Developer Application"* ]] \
      || fail "$target is not signed for the App Store"
  fi
  local ents=$tmp/$identifier.plist
  codesign -d --entitlements - --xml "$target" > "$ents" 2>/dev/null || fail "$target has no entitlements"
  [[ $(entitlement "$ents" com.apple.security.get-task-allow) != true ]] || fail "$target has get-task-allow"
  [[ $(entitlement "$ents" com.apple.security.app-sandbox) == true ]] || fail "$target is not sandboxed"
  [[ $(entitlement "$ents" com.apple.security.application-groups:0) == "$group" ]] || fail "$target lacks app group $group"
  echo "ok  $identifier"
}

check "$app" $app_id
check "$app/Contents/PlugIns/RightKitFinder.appex" $app_id.finder
check "$app/Contents/MacOS/RightKitAgent" $app_id.agent

# 主程序的网络权限只给官网版的检查更新（F-081、F-082）。
main_ents=$tmp/$app_id.plist
network=$(entitlement "$main_ents" com.apple.security.network.client)
if [[ $channel == direct ]]; then
  [[ $network == true ]] || fail "direct build lacks network.client for update checks"
else
  [[ -z $network ]] || fail "App Store build must not have network.client"
  for binary in "$app/Contents/MacOS/RightKit" "$app/Contents/MacOS/RightKitAgent" "$app/Contents/PlugIns/RightKitFinder.appex/Contents/MacOS/RightKitFinder"; do
    if grep -a -q -e "api.github.com" -e "github.com" "$binary"; then
      fail "$binary mentions GitHub; update checks and GitHub links belong to the direct build only"
    fi
  done
fi
[[ $(entitlement "$main_ents" com.apple.security.temporary-exception.apple-events:0) == com.apple.finder ]] \
  || fail "main app lacks the Finder Apple Events exception (F-001)"

plist="$app/Contents/Library/LaunchAgents/$app_id.agent.plist"
[[ -f $plist ]] || fail "agent plist missing: $plist"
[[ $(/usr/libexec/PlistBuddy -c "Print :Label" "$plist") == $app_id.agent ]] || fail "agent label mismatch"
/usr/libexec/PlistBuddy -c "Print :MachServices:$group.command" "$plist" >/dev/null \
  || fail "agent plist does not publish $group.command"
echo "Signature check passed ($channel)."
