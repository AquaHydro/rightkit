#!/bin/bash
# CI 发布前准备签名：临时钥匙串导入证书，写出 App Store Connect API key（.github/workflows/release.yml）。
#
# 需要的 secrets（仓库 Settings → Secrets and variables → Actions）：
#   SIGNING_CERTS_P12_BASE64    一个 .p12，含 Developer ID Application、Apple Distribution、
#                               3rd Party Mac Developer Installer 三个证书和私钥，base64 编码
#   SIGNING_CERTS_P12_PASSWORD  导出 .p12 时设的密码
#   ASC_KEY_P8_BASE64           App Store Connect API key（.p8，Admin 角色），base64 编码
#   ASC_KEY_ID、ASC_ISSUER_ID    这个 key 的 ID 和 Issuer ID
set -euo pipefail
: "${SIGNING_CERTS_P12_BASE64:?}" "${SIGNING_CERTS_P12_PASSWORD:?}"
: "${ASC_KEY_P8_BASE64:?}" "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}"

keychain="$RUNNER_TEMP/rightkit-signing.keychain-db"
keychain_password=$(uuidgen)
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"

certs="$RUNNER_TEMP/rightkit-certs.p12"
printf '%s' "$SIGNING_CERTS_P12_BASE64" | base64 --decode > "$certs"
security import "$certs" -k "$keychain" -P "$SIGNING_CERTS_P12_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/security
rm -f "$certs"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
# 放在搜索列表最前面，同时保留原有钥匙串。
existing=()
while IFS= read -r line; do
  line=${line//\"/}
  line=${line#"${line%%[![:space:]]*}"}
  [[ -n $line ]] && existing+=("$line")
done < <(security list-keychains -d user)
security list-keychains -d user -s "$keychain" "${existing[@]}"
security find-identity -v -p codesigning "$keychain"

key="$RUNNER_TEMP/AuthKey_$ASC_KEY_ID.p8"
printf '%s' "$ASC_KEY_P8_BASE64" | base64 --decode > "$key"
chmod 600 "$key"

{
  echo "ASC_KEY_PATH=$key"
  echo "RIGHTKIT_KEYCHAIN=$keychain"
} >> "$GITHUB_ENV"
