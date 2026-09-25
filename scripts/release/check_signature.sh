#!/bin/zsh
# 检查导出的 app：Developer ID、强化运行时、时间戳、没有调试权限、都开了沙盒，三个部件的签名标识和 App Group 正确。
set -euo pipefail
app=$1
fail() { echo "error: $*" >&2; exit 1; }

codesign --verify --deep --strict --verbose=2 "$app" 2>&1 | tail -1
check() {
  local target=$1 identifier=$2 needs_group=$3
  local info; info=$(codesign -dvv "$target" 2>&1)
  [[ $info == *"Identifier=$identifier"* ]] || fail "$target identifier is not $identifier"
  [[ $info == *"Authority=Developer ID Application"* ]] || fail "$target is not signed with Developer ID"
  [[ $info == *"TeamIdentifier=Q9C87Z9H4G"* ]] || fail "$target team mismatch"
  [[ $info == *"flags=0x10000(runtime)"* ]] || fail "$target lacks hardened runtime"
  [[ $info == *"Timestamp="* ]] || fail "$target has no secure timestamp"
  local ents; ents=$(codesign -d --entitlements - --xml "$target" 2>/dev/null)
  [[ $ents != *"get-task-allow"* ]] || fail "$target has get-task-allow"
  [[ $ents == *"<key>com.apple.security.app-sandbox</key><true/>"* ]] || fail "$target is not sandboxed"
  # App Group 用团队 ID 前缀，不需要描述文件授权（technical.md 发布渠道与标识）。
  if [[ $needs_group == yes ]]; then
    [[ $ents == *"<string>Q9C87Z9H4G.app.rightkit.mac</string>"* ]] || fail "$target lacks the app group"
  fi
  echo "ok  $identifier"
}
check "$app" app.rightkit.mac yes
check "$app/Contents/PlugIns/RightKitFinder.appex" app.rightkit.mac.finder yes
check "$app/Contents/MacOS/RightKitAgent" app.rightkit.mac.agent yes
plist="$app/Contents/Library/LaunchAgents/app.rightkit.mac.agent.plist"
[[ -f $plist ]] || fail "agent plist missing"
[[ $(/usr/libexec/PlistBuddy -c "Print :Label" "$plist") == app.rightkit.mac.agent ]] || fail "agent label mismatch"
/usr/libexec/PlistBuddy -c "Print :MachServices:Q9C87Z9H4G.app.rightkit.mac.command" "$plist" >/dev/null \
  || fail "agent plist does not publish Q9C87Z9H4G.app.rightkit.mac.command"
echo "Signature check passed."
