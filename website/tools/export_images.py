#!/usr/bin/env python3
"""Export web images from the PNG masters in website/assets.

Run after the character art or the app icon changes, then commit the output in
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
}

# Pricing card loops in website/assets/video, played on hover. The poster is the
# matching still above, which is also the first frame of the loop.
VIDEOS = ("pricing-free", "pricing-store", "pricing-oss")


def export_videos() -> None:
    target = ROOT / "website/public/video"
    target.mkdir(exist_ok=True)
    for name in VIDEOS:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", ROOT / f"website/assets/video/{name}.mp4",
                        "-an", "-c:v", "libx264", "-crf", "28", "-preset", "slow", "-pix_fmt", "yuv420p",
                        "-movflags", "+faststart", target / f"{name}.mp4"], check=True)


def export_character() -> None:
    for name, (source, widths) in CHARACTER.items():
        image = Image.open(ART / source).convert("RGBA")
        for width in widths:
            height = round(image.height * width / image.width)
            resized = image.resize((width, height), Image.LANCZOS)
            resized.save(OUT / f"{name}-{width}.webp", "WEBP", quality=82, method=6)


# App icons for the Open in App section, scaled onto the macOS icon grid
# (the body is 824 of 1024 points). Xcode already ships with that margin.
APP_ICONS = {"terminal": 824 / 1024, "ghostty": 824 / 1024, "vscode": 780 / 1024, "xcode": 1.0}


def export_app_icons() -> None:
    target = OUT / "apps"
    target.mkdir(exist_ok=True)
    for name, body in APP_ICONS.items():
        source = Image.open(ROOT / "website/assets/apps" / f"{name}.png").convert("RGBA")
        canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        inner = round(512 * body)
        offset = (512 - inner) // 2
        canvas.alpha_composite(source.resize((inner, inner), Image.LANCZOS), (offset, offset))
        for size in (64, 128):
            canvas.resize((size, size), Image.LANCZOS).save(target / f"{name}-{size}.webp", "WEBP", quality=90, method=6)


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
    export_app_icons()
    export_videos()
    for path in sorted([*OUT.rglob("*.*"), *(ROOT / "website/public/video").glob("*.mp4")]):
        print(f"{path.relative_to(ROOT)}  {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
