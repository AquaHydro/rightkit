#!/bin/sh
# Cuts, crops and re-encodes the v2 footage into seek-friendly clips (every frame a keyframe).
# Inputs: recordings/*.mov (screen recordings) and ai-clips/*.mp4 (Medio Gen). Output: public/clips/.
# The purple "sharing" pill in the recordings' title bar is covered with the title bar's own white.
set -e
cd "$(dirname "$0")/.."
mkdir -p public/clips
enc() { # enc <in> <start> <duration> <filter> <out>
  ffmpeg -v error -y -ss "$2" -t "$3" -i "$1" -vf "$4" -an -c:v libx264 -g 1 -bf 0 -crf 14 -pix_fmt yuv420p "public/clips/$5.mp4"
}
pill='drawbox=x=8:y=8:w=142:h=48:color=white:t=fill'
enc ai-clips/riko-point-16x9.mp4   0   6    'crop=1920:1080:0:4'           riko-point
# Riko's press lands at 1.375s; after 1.85s the hair clip gets covered and lost, so keep only the start.
enc ai-clips/chibi/press.mp4       0   1.85 'crop=1920:1080:0:4'           chibi-press
enc ai-clips/chibi/shield.mp4      0   6    'crop=1920:1080:0:4'           chibi-shield
enc ai-clips/riko-wave-flat.mp4    0   6    'crop=1920:1080:0:4'           riko-wave-flat
cp ai-clips/chibi/juggle.png public/clips/chibi-juggle.png
enc recordings/welcome.mov         8.4 3.5  'crop=800:136:216:1000'        welcome-row
enc recordings/shortcuts.mov       3.0 3.95 'crop=592:720:1848:590'        shortcuts
enc recordings/qrcode.mov          0.8 5    "crop=640:832:112:76,$pill"    qrcode
enc recordings/progress.mov        0   2.75 "crop=800:296:112:76,$pill"    progress
ls -la public/clips
