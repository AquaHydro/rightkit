#!/bin/zsh
# 在访达里对指定选择打开右键菜单并按路径点击，超时 15 秒自动按 Esc。
# 用法：scripts/e2e/finder_menu.sh <文件夹> <"a|b" 或 ""> <"工具箱>拷贝路径" 或 "?">
# 需要终端有辅助功能权限。访达要处于列表视图可见状态；刚替换过扩展时先重启访达。
here=${0:A:h}
osascript "$here/finder_menu.applescript" "$@" 2>&1 &
pid=$!
( sleep 15; kill $pid 2>/dev/null && osascript -e 'tell application "System Events" to key code 53' && echo "timeout: $3" ) &
wait $pid 2>/dev/null
