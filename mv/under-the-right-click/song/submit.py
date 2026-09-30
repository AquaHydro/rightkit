# usage: python3 song/submit.py chirp-hawk-wild   (the Suno model version; each call returns 2 songs)
# Suno has no public official API, so this needs a service speaking the common SunoAPI format:
#   POST {SUNO_BASE}/suno/submit/music   GET {SUNO_BASE}/suno/fetch/{task}   GET {SUNO_BASE}/suno/act/timing/{clip}
# Config lives outside git in ~/.config/rightkit-mv/env: SUNO_BASE, SUNO_KEY. Generate with a paid Suno plan for commercial use.
import json, os, sys, urllib.request
env = dict(l.strip().split("=", 1) for l in open(os.path.expanduser("~/.config/rightkit-mv/env")) if "=" in l)
BASE = env["SUNO_BASE"].rstrip("/")
def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method,
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization": "Bearer " + env["SUNO_KEY"], "Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=60))
if __name__ == "__main__":
    mv = sys.argv[1]
    body = {
        "prompt": open("song/lyrics.txt").read(),
        "mv": mv,
        "title": "Under the Right Click",
        "tags": "1990s anime opening theme, J-rock, energetic bright Japanese female vocals, Japanese lyrics with English hooks, 168 BPM, driving distorted guitars, fast tight drums, busy bass, glitchy digital click sounds, synth arpeggios, orchestral string stabs in chorus, dark cyberpunk atmosphere, dramatic builds, catchy powerful hook, key change final chorus",
        "negative_tags": "rap, male vocals, heavy autotune, lo-fi, acoustic, ballad",
    }
    r = call("POST", "/suno/submit/music", body)
    print(json.dumps(r, ensure_ascii=False))
    json.dump(r, open(f"song/submit_{mv}.json", "w"), ensure_ascii=False)
