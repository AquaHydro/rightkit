#!/usr/bin/env python3
"""Export web images from the PNG masters in website/assets.

Run after the character art or RightKit app icon changes, then commit the output in
website/public/img and website/public/video. Requires Pillow (pip install pillow)
and ffmpeg for the videos; the site build itself needs neither.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "website/assets/character"
ICON = ROOT / "RightKit/Resources/AppIcon.icon"
OUT = ROOT / "website/public/img"

# name -> (source, widths). Each width is exported as name-<width>.webp.
CHARACTER = {
    "hero-character": ("hero-character.png", (560, 1120)),
    "hero-character-ak": ("hero-character-ak.png", (560, 1120)),  # ak-ui theme (/ak/)
    "cta-character": ("cta-character.png", (480, 960)),
    "main": ("main.png", (400, 800)),
    "feature-new-file": ("feature-new-file.png", (320, 640)),
    "feature-copy-move": ("feature-copy-move.png", (320, 640)),
    "feature-open-app": ("feature-open-app.png", (320, 640)),
    "feature-toolbox": ("feature-toolbox.png", (320, 640)),
    "feature-empty-error": ("feature-empty-error.png", (240, 480)),
    "pricing-free": ("pricing-free.png", (420, 840)),
    "pricing-store": ("pricing-store.png", (420, 840)),
    "pricing-oss": ("pricing-oss.png", (420, 840)),
    # ak-ui theme (/ak/): same compositions in the operator outfit.
    "cta-character-ak": ("cta-character-ak.png", (480, 960)),
    "feature-new-file-ak": ("feature-new-file-ak.png", (320, 640)),
    "feature-copy-move-ak": ("feature-copy-move-ak.png", (320, 640)),
    "feature-open-app-ak": ("feature-open-app-ak.png", (320, 640)),
    "feature-toolbox-ak": ("feature-toolbox-ak.png", (320, 640)),
    "feature-empty-error-ak": ("feature-empty-error-ak.png", (240, 480)),
    "pricing-free-ak": ("pricing-free-ak.png", (420, 840)),
    "pricing-store-ak": ("pricing-store-ak.png", (420, 840)),
    "pricing-oss-ak": ("pricing-oss-ak.png", (420, 840)),
    # Full-body profile art generated for the ak-ui archive gallery.
    "profile-riko-stand-ak": ("profile-riko-stand-ak.png", (512, 1024)),
    "profile-riko-ok-ak": ("profile-riko-ok-ak.png", (512, 1024)),
    "profile-riko-wave-ak": ("profile-riko-wave-ak.png", (512, 1024)),
    "profile-riko-file-ak": ("profile-riko-file-ak.png", (512, 1024)),
    "workbench-scene-ak": ("workbench-scene-ak.png", (768, 1536)),
}

# Pricing card loops in website/assets/video, played on hover. The poster is the
# matching still above, which is also the first frame of the loop.
VIDEOS = ("pricing-free", "pricing-store", "pricing-oss")
# The ak loops end away from their first frame, so they play forward then backward to loop without a jump.
PINGPONG = ("pricing-free-ak", "pricing-store-ak", "pricing-oss-ak", "hero-pv-ak")


def export_videos() -> None:
    target = ROOT / "website/public/video"
    target.mkdir(exist_ok=True)
    for name in VIDEOS + PINGPONG:
        # Ping-pong doubles the length, so it needs a higher CRF to stay under the 1 MB budget.
        loop = ["-filter_complex", "[0:v]split[a][b];[b]reverse[r];[a][r]concat=n=2:v=1[v]", "-map", "[v]"] if name in PINGPONG else []
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", ROOT / f"website/assets/video/{name}.mp4", *loop,
                        "-an", "-c:v", "libx264", "-crf", "31" if name in PINGPONG else "28", "-preset", "slow", "-pix_fmt", "yuv420p",
                        "-movflags", "+faststart", target / f"{name}.mp4"], check=True)


def export_character() -> None:
    for name, (source, widths) in CHARACTER.items():
        image = Image.open(ART / source).convert("RGBA")
        for width in widths:
            height = round(image.height * width / image.width)
            resized = image.resize((width, height), Image.LANCZOS)
            resized.save(OUT / f"{name}-{width}.webp", "WEBP", quality=82, method=6)

    # The cinematic ak hero background keeps one stable URL for the video poster.
    poster = Image.open(ART / "hero-pv-poster-ak.png").convert("RGB")
    poster.save(OUT / "hero-pv-poster-ak.webp", "WEBP", quality=88, method=6)


def squircle_mask(size: int) -> Image.Image:
    """macOS-style rounded square: 824/1024 body with a 185/1024 corner radius."""
    scale = 4
    big = size * scale
    inset = round(big * 100 / 1024)
    radius = round(big * 185 / 1024)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle((inset, inset, big - inset, big - inset), radius, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def export_icon() -> None:
    spec = json.loads((ICON / "icon.json").read_text())
    r, g, b, _ = (float(v) for v in spec["fill"]["solid"].split(":")[1].split(","))
    fill = (round(r * 255), round(g * 255), round(b * 255), 255)
    canvas = Image.new("RGBA", (1024, 1024), fill)
    # Groups are listed top first, so composite them in reverse.
    for group in reversed(spec["groups"]):
        for layer in group["layers"]:
            art = Image.open(ICON / "Assets" / layer["image-name"]).convert("RGBA").resize((1024, 1024))
            canvas.alpha_composite(art)
    # The .icon canvas is the icon body; scale it into the squircle so the icon keeps its margin.
    for size in (64, 180, 512):
        icon = canvas
        mask = squircle_mask(size)
        framed = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        inner = round(size * 824 / 1024)
        offset = (size - inner) // 2
        framed.paste(icon.resize((inner, inner), Image.LANCZOS), (offset, offset))
        framed.putalpha(ImageChops.multiply(framed.getchannel("A"), mask))
        framed.save(OUT / f"app-icon-{size}.png", optimize=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    export_character()
    export_icon()
    export_videos()
    for path in sorted([*OUT.rglob("*.*"), *(ROOT / "website/public/video").glob("*.mp4")]):
        print(f"{path.relative_to(ROOT)}  {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
