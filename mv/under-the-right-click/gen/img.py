# usage: python3 gen/img.py out.png "prompt" [ref1.png ref2.png ...]
# Needs an OpenAI Images compatible endpoint (/images/generations, and /images/edits when reference images are given).
# Config lives outside git in ~/.config/rightkit-mv/env: IMAGE_BASE (e.g. https://api.openai.com/v1), IMAGE_KEY.
import base64, json, os, subprocess, sys
env = dict(l.strip().split("=", 1) for l in open(os.path.expanduser("~/.config/rightkit-mv/env")) if "=" in l)
out, prompt, refs = sys.argv[1], sys.argv[2], sys.argv[3:]
size = os.environ.get("SIZE", "2048x1152")
model = os.environ.get("MODEL", "gpt-image-2.5-sunburst")
args = ["curl", "-s", "-m", "600", "-H", "Authorization: Bearer " + env["IMAGE_KEY"],
        "-F", f"model={model}", "-F", f"prompt={prompt}", "-F", f"size={size}", "-F", "quality=high"]
url = env["IMAGE_BASE"].rstrip("/") + ("/images/edits" if refs else "/images/generations")
for r in refs: args += ["-F", f"image[]=@{r}"]
if not refs:  # generations takes JSON
    args = args[:6] + ["-H", "Content-Type: application/json", "-d", json.dumps({"model": model, "prompt": prompt, "size": size, "quality": "high"})]
r = subprocess.run(args + [url], capture_output=True, text=True)
try:
    d = json.loads(r.stdout)["data"][0]
except Exception:
    sys.exit("error: " + r.stdout[:800])
if d.get("b64_json"):
    open(out, "wb").write(base64.b64decode(d["b64_json"]))
else:
    subprocess.run(["curl", "-sL", "-o", out, d["url"]])
open(out + ".prompt.txt", "w").write(prompt + "\n\nrefs: " + " ".join(refs))
print(out)
