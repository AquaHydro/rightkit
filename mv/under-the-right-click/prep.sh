#!/bin/zsh
# prep.sh: rebuild the studio inputs that are not in git.
# Seedance clips (gen/sd/*.mp4) -> studio/frames/<shot>/NNNN.jpg at 24 fps + index.json, and the song -> studio/song.mp3.
set -e
cd "$(dirname "$0")"
for f in gen/sd/*.mp4; do
  s=$(basename "$f" .mp4)
  rm -rf "studio/frames/$s"; mkdir -p "studio/frames/$s"
  ffmpeg -v error -y -i "$f" -vf "fps=24,scale=1920:1080:flags=lanczos" -q:v 2 "studio/frames/$s/%04d.jpg"
done
python3 -c 'import os,json; r="studio/frames"; json.dump({s:{"n":len(os.listdir(f"{r}/{s}"))} for s in sorted(os.listdir(r)) if os.path.isdir(f"{r}/{s}")}, open(f"{r}/index.json","w"))'
cp song/chirp-hawk-wild_2.mp3 studio/song.mp3
echo "frames ready: $(find studio/frames -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') shots"
