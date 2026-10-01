# usage: python3 gen/sd.py NAME duration audio.mp3 "prompt" img1 [img2 ...]   -> submit; python3 gen/sd.py --poll NAME
# Needs Seedance (ByteDance Doubao video model) through an endpoint compatible with the official Volcengine Ark task API:
#   POST {SEEDANCE_BASE}/contents/generations/tasks   GET {SEEDANCE_BASE}/contents/generations/tasks/{id}
#   official base: https://ark.cn-beijing.volces.com/api/v3
# Reference images and audio are sent inline as base64 data URLs, so nothing has to be uploaded publicly.
# Config lives outside git in ~/.config/rightkit-mv/env (SEEDANCE_BASE, SEEDANCE_KEY, optional SEEDANCE_MODEL).
import base64, json, os, subprocess, sys, time, mimetypes
env = dict(l.strip().split("=", 1) for l in open(os.path.expanduser("~/.config/rightkit-mv/env")) if "=" in l)
BASE = env["SEEDANCE_BASE"].rstrip("/")
MODEL = os.environ.get("MODEL", env.get("SEEDANCE_MODEL", "doubao-seedance-2.5"))
def curl(method, path, body=None):
    a = ["curl", "-s", "-m", "300", "-X", method, "-H", "Authorization: Bearer " + env["SEEDANCE_KEY"], "-H", "Content-Type: application/json"]
    if body is not None: a += ["--data-binary", "@-"]
    r = subprocess.run(a + [BASE + path], input=json.dumps(body) if body is not None else None, capture_output=True, text=True)
    return json.loads(r.stdout)
def data_url(p):
    m = mimetypes.guess_type(p)[0] or "application/octet-stream"
    return f"data:{m};base64," + base64.b64encode(open(p, "rb").read()).decode()
if sys.argv[1] == "--poll":
    name = sys.argv[2]; tid = json.load(open(f"gen/sd/{name}.submit.json"))["id"]
    while True:
        d = curl("GET", f"/contents/generations/tasks/{tid}")
        st = d.get("status"); print(name, st, flush=True)
        if st in ("succeeded", "failed", "expired", "cancelled") or "error" in d: break
        time.sleep(15)
    json.dump(d, open(f"gen/sd/{name}.result.json", "w"), ensure_ascii=False, indent=1)
    if st == "succeeded":
        subprocess.run(["curl", "-sL", "-o", f"gen/sd/{name}.mp4", d["content"][0]["video_url"]["url"] if isinstance(d["content"], list) else d["content"]["video_url"]])
        print(f"gen/sd/{name}.mp4")
    else: print(json.dumps(d, ensure_ascii=False)[:1500])
    sys.exit()
name, dur, audio, prompt, imgs = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5:]
content = [{"type": "text", "text": prompt}]
content += [{"type": "image_url", "image_url": {"url": data_url(i)}, "role": "reference_image"} for i in imgs]
if audio != "-": content.append({"type": "audio_url", "audio_url": {"url": data_url(audio)}, "role": "reference_audio"})
body = {"model": MODEL, "content": content, "generate_audio": False, "ratio": "16:9", "duration": dur,
        "resolution": os.environ.get("RES", "720p"), "watermark": False}
d = curl("POST", "/contents/generations/tasks", body)
print(json.dumps(d, ensure_ascii=False)[:1500])
if d.get("id"):
    json.dump({"id": d["id"], "prompt": prompt, "imgs": imgs, "audio": audio, "dur": dur, "model": MODEL}, open(f"gen/sd/{name}.submit.json", "w"), ensure_ascii=False, indent=1)
