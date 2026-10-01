#!/bin/zsh
# encode.sh: out/frames (30 fps) + the song -> master and web MP4 in video/
set -e
cd "$(dirname "$0")"
mkdir -p video
M="video/Under the Right Click - Riko MV.mp4"
ffmpeg -v error -y -framerate 30 -i out/frames/%05d.jpg -i song/chirp-hawk-wild_2.mp3 -map 0:v -map 1:a \
  -c:v libx264 -preset slow -crf 20 -maxrate 20M -bufsize 40M -profile:v high -pix_fmt yuv420p -movflags +faststart \
  -c:a aac -b:a 256k -ar 48000 -shortest "$M"
ffmpeg -v error -y -i "$M" -c:v libx264 -preset slow -crf 24 -maxrate 10M -bufsize 20M -pix_fmt yuv420p -movflags +faststart \
  -c:a aac -b:a 192k "video/Under the Right Click - Riko MV (web).mp4"
ls -lh video
