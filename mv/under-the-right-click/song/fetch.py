# usage: python3 song/fetch.py   -> downloads finished songs and their word timing next to this file
# Uses the same SunoAPI-compatible service as submit.py. The CDN rejects Python's default user agent, so downloads go through curl.
import json, os, subprocess, sys
sys.path.insert(0, "song")
from submit import call
for f in ["chirp-hawk", "chirp-hawk-wild"]:
    if not os.path.exists(f"song/submit_{f}.json"): continue
    d = call("GET", f"/suno/fetch/{json.load(open(f'song/submit_{f}.json'))['data']}")["data"]
    print(f, d.get("status"), d.get("fail_reason") or "")
    for i, c in enumerate(d.get("data") or []):
        print("  ", c["id"], c.get("status"), (c.get("metadata") or {}).get("duration"))
        if c.get("status") != "complete": continue
        subprocess.run(["curl", "-sL", "-A", "Mozilla/5.0", "-o", f"song/{f}_{i + 1}.mp3", c["audio_url"]], check=True)
        t = call("GET", f"/suno/act/timing/{c['id']}")
        json.dump(t.get("data", t), open(f"song/timing_{f}_{i + 1}.json", "w"), ensure_ascii=False)
