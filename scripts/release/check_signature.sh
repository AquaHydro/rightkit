#!/bin/zsh
# 检查导出的 app：Developer ID、强化运行时、时间戳、没有调试权限，四个部件的签名标识和 App Group 正确。
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
  if [[ $needs_group == yes ]]; then
    [[ $ents == *"group.app.rightkit.mac"* ]] || fail "$target lacks the app group"
    security cms -D -i "$target/Contents/embedded.provisionprofile" 2>/dev/null | grep -q "group.app.rightkit.mac" \
      || fail "$target provisioning profile does not authorize the app group"
  fi
  echo "ok  $identifier"
}
check "$app" app.rightkit.mac yes
check "$app/Contents/PlugIns/RightKitFinder.appex" app.rightkit.mac.finder yes
check "$app/Contents/MacOS/RightKitAgent" app.rightkit.mac.agent no
[[ -f "$app/Contents/Library/LaunchAgents/app.rightkit.mac.agent.plist" ]] || fail "agent plist missing"
echo "Signature check passed."
