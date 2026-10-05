#!/usr/bin/env python3
"""Build the RightKit website into website/dist.

Standard library only. Renders src/index.html and src/privacy.html once per language in content.json
and theme, and copies the static files next to it. The classic theme lives at the root; the ak-ui theme
(styles.css plus src/ak-ui.css) lives under /ak/ and shares the same assets.

Template syntax:
  {{ path.to.value }}          HTML-escaped text; {name} placeholders use site.json
  {{ path.to.value|raw }}      inserted as is
  {{ path.to.value|json }}     JSON, safe inside <script>
  {% for item in path %}...{% endfor %}   loops can nest; loop.index starts at 1
  {% if path %}...{% else %}...{% endif %}
"""

from __future__ import annotations

import html
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
DIST = ROOT / "dist"

# Theme name -> URL prefix. Templates see theme.ak to add the ak-ui markup.
THEMES = {"classic": "", "ak": "ak/"}
LANGUAGES = {
    "zh": {"name": "简体中文", "short": "中文"},
    "en": {"name": "English", "short": "EN"},
    "ja": {"name": "日本語", "short": "JA"},
    "ko": {"name": "한국어", "short": "KO"},
}


def page_scope(site: dict, content: dict, key: str, theme: str, sub: str) -> dict:
    prefix = THEMES[theme]
    strings = content[key]
    path = "/" + prefix + strings["path"].lstrip("/") + sub
    depth = len([part for part in path.split("/") if part])
    base = "../" * depth
    languages = []
    for code, labels in LANGUAGES.items():
        locale = content[code]
        language_path = prefix + locale["path"].lstrip("/") + sub
        href = base + language_path or "./"
        languages.append({**labels, "key": code, "lang": locale["lang"],
                          "href": href + ("?lang=zh" if code == "zh" else ""),
                          "canonical": site["url"] + locale["path"] + sub,
                          "current": code == key})
    home = base + prefix + strings["path"].lstrip("/") or "./"
    explicit = "?lang=zh" if key == "zh" else ""
    return {"site": site, "t": strings, "base": base, "home": base + prefix,
            "theme": {theme: True}, "languages": languages,
            "currentLanguage": LANGUAGES[key],
            "page": {"canonical": site["url"] + strings["path"] + sub,
                     "default": site["url"] + "/" + sub,
                     "home": home + explicit, "privacy": home + "privacy/" + explicit},
            "languageConfig": {"current": key, "defaultEntry": key == "zh", "languages": languages}}


TOKEN = re.compile(r"\{\{\s*(.+?)\s*\}\}|\{%\s*(.+?)\s*%\}", re.S)


def lookup(scope: dict, path: str):
    value = scope
    for part in path.split("."):
        if isinstance(value, dict):
            if part not in value:
                raise KeyError(path)
            value = value[part]
        elif isinstance(value, list) and part.isdigit():
            value = value[int(part)]
        else:
            raise KeyError(path)
    return value


def fill(text: str, site: dict) -> str:
    return re.sub(r"\{(\w+)\}", lambda m: str(site.get(m.group(1), m.group(0))), text)


def parse(template: str) -> list:
    """Turn the template into a tree of text, expressions and blocks."""
    root: list = []
    stack = [(root, None)]
    pos = 0
    for match in TOKEN.finditer(template):
        stack[-1][0].append(template[pos:match.start()])
        pos = match.end()
        expr, tag = match.group(1), match.group(2)
        if expr:
            stack[-1][0].append(("expr", expr))
            continue
        words = tag.split()
        if words[0] == "for":
            node = {"kind": "for", "var": words[1], "path": words[3], "body": []}
            stack[-1][0].append(node)
            stack.append((node["body"], node))
        elif words[0] == "if":
            node = {"kind": "if", "path": words[1], "body": [], "else": []}
            stack[-1][0].append(node)
            stack.append((node["body"], node))
        elif words[0] == "else":
            node = stack[-1][1]
            stack[-1] = (node["else"], node)
        elif words[0] in ("endfor", "endif"):
            stack.pop()
        else:
            raise ValueError(f"unknown tag: {tag}")
    stack[-1][0].append(template[pos:])
    if len(stack) != 1:
        raise ValueError("unclosed block")
    return root


def render(nodes: list, scope: dict) -> str:
    out = []
    for node in nodes:
        if isinstance(node, str):
            out.append(node)
        elif isinstance(node, tuple):
            path, _, flag = node[1].partition("|")
            value = lookup(scope, path.strip())
            flag = flag.strip()
            if flag == "json":
                out.append(json.dumps(value, ensure_ascii=False).replace("</", "<\\/"))
            elif flag == "raw":
                out.append(str(value))
            else:
                if isinstance(value, bool):
                    value = "true" if value else "false"
                out.append(html.escape(fill(str(value), scope["site"])))
        elif node["kind"] == "for":
            items = lookup(scope, node["path"])
            for index, item in enumerate(items, 1):
                inner = dict(scope)
                inner[node["var"]] = item
                inner["loop"] = {"index": index, "first": index == 1}
                out.append(render(node["body"], inner))
        elif node["kind"] == "if":
            try:
                value = lookup(scope, node["path"])
            except KeyError:
                value = None
            out.append(render(node["body"] if value else node["else"], scope))
    return "".join(out)


def main() -> int:
    site = json.loads((ROOT / "site.json").read_text(encoding="utf-8"))
    content = json.loads((ROOT / "content.json").read_text(encoding="utf-8"))
    # Each page is rendered once per language under <language path><sub-path>.
    pages = {"": parse((SRC / "index.html").read_text(encoding="utf-8")),
             "privacy/": parse((SRC / "privacy.html").read_text(encoding="utf-8"))}

    if DIST.exists():
        shutil.rmtree(DIST)
    shutil.copytree(ROOT / "public", DIST)
    for name in ("styles.css", "ak-ui.css", "main.js", "ak.js", "language.js"):
        shutil.copy2(SRC / name, DIST / name)

    for theme, prefix in THEMES.items():
        for key, strings in content.items():
            for sub, tree in pages.items():
                path = "/" + prefix + strings["path"].lstrip("/") + sub
                scope = page_scope(site, content, key, theme, sub)
                target = DIST / path.strip("/") / "index.html"
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(render(tree, scope), encoding="utf-8")
                print(f"built {target.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
