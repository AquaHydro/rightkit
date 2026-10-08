#!/bin/zsh
# 用法: bench.sh A|B|C 轮数
W=/private/tmp/rk-prewarm; V=$1; N=${2:-3}
LS=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
for x in A B C; do pluginkit -r $W/$x/RightKit.app/Contents/PlugIns/RightKitFinder.appex 2>/dev/null; done
pluginkit -r /Users/liao/Documents/rightkit/.build/DerivedData/Build/Products/Debug/RightKit.app/Contents/PlugIns/RightKitFinder.appex 2>/dev/null
$LS -u /Users/liao/Documents/rightkit/.build/DerivedData/Build/Products/Debug/RightKit.app 2>/dev/null
$LS -f -R -trusted $W/$V/RightKit.app; pluginkit -a $W/$V/RightKit.app/Contents/PlugIns/RightKitFinder.appex; pluginkit -e use -i app.rightkit.mac.finder
sleep 1
pluginkit -m -A -v -i app.rightkit.mac.finder | grep -q "/$V/RightKit.app" || { echo "注册失败 $V"; exit 1; }
for r in $(seq $N); do
  pkill -x RightKitFinder; killall Finder; sleep 3
  osascript -e 'tell application "Finder"
    close every window
    set w to make new Finder window to (POSIX file "/Users/liao/rk-prewarm-test" as alias)
    set current view of w to list view
    set bounds of w to {200, 200, 1100, 700}
    select (POSIX file "/Users/liao/rk-prewarm-test/a.txt" as alias)
    activate
  end tell' >/dev/null
  sleep 3
  line="$V round$r:"
  for i in 1 2 3 4 5; do
    osascript -e 'tell application "Finder" to activate'; sleep 0.4
    v=$($W/rclick 415 295 | sed 's/visible_ms=//;s/ rightkit=yes//')
    line="$line $v"; sleep 0.3; osascript -e 'tell application "System Events" to key code 53'; sleep 0.5
  done
  echo $line
done
