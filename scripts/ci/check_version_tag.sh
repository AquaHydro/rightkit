#!/bin/bash
# 标签必须是 v 加 project.yml 里的 MARKETING_VERSION，比如 v0.2.0（F-081 按标签比较版本）。
set -euo pipefail
tag=${1:?usage: check_version_tag.sh <tag>}
version=$(sed -n 's/^ *MARKETING_VERSION: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' project.yml | head -1)
if [[ ! $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::标签 $tag 不是 v 加三段数字"
  exit 1
fi
if [[ $tag != "v$version" ]]; then
  echo "::error::标签 $tag 与 project.yml 的 MARKETING_VERSION $version 不一致，先改版本号再打标签"
  exit 1
fi
echo "version=$version" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "Tag $tag matches MARKETING_VERSION $version"
