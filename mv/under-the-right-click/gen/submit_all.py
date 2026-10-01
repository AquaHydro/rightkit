# Submit every shot in gen/shots.json that has no submit record yet.
# Every shot is a Seedance 2.5 call (see gen/sd.py for the endpoint). Adjacent shots are packed into one
# call of up to 15 s ("镜头1（前4秒）… 镜头2（后10秒）…") so fewer, longer generations cover the song.
import json, math, os, subprocess
CH = "图片1是角色设定图中的少女Riko（珊瑚色蓬松短发、头顶一根卷起的呆毛、刘海右侧白色圆角发卡上有黑色鼠标箭头和三条珊瑚色短横线、深红棕色眼睛、白色机能连帽外套配黑色背带和珊瑚色条纹、肩上一只小白鼠只有一只珊瑚色耳朵），场景参考图片2。\n"
ST = "\n日本90年代TV动画赛璐璐风格，干净黑色线稿，平涂阴影，与角色设定图画风一致，人物外形保持和设定图完全一致。"
for name, a, b, sing, st, p in json.load(open("gen/shots.json")):
    if os.path.exists(f"gen/sd/{name}.submit.json"): continue
    dur = max(4, min(15, math.ceil(b - a)))
    model = os.environ.get("MODEL", "doubao-seedance-2.5")
    audio = "-"
    if sing:
        audio = f"slices/{name}.mp3"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(a), "-to", str(min(b, a + 15)), "-i", "song/chirp-hawk-wild_2.mp3", "-c:a", "libmp3lame", "-b:a", "192k", audio], check=True)
        p += "跟随音频1的女声演唱，嘴型与歌词和节奏精确同步。"
    r = subprocess.run(["python3", "gen/sd.py", name, str(dur), audio, CH + p + ST, "ref/char_sheet.jpg", f"ref/{st}.jpg"],
                       capture_output=True, text=True, env={**os.environ, "MODEL": model})
    print(name, dur, model, r.stdout.strip()[:200], r.stderr[-300:])
