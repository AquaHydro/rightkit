#!/bin/bash
# 发布结束后删掉临时钥匙串和 API key，失败时也执行。
set -uo pipefail
[[ -n ${RIGHTKIT_KEYCHAIN:-} ]] && security delete-keychain "$RIGHTKIT_KEYCHAIN"
[[ -n ${ASC_KEY_PATH:-} ]] && rm -f "$ASC_KEY_PATH"
exit 0
