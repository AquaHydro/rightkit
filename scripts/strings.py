#!/usr/bin/env python3
"""Keep the RightKit string catalog in sync with L("…") calls.

  python3 scripts/strings.py check          # every L("…") key has an English value
  python3 scripts/strings.py add < pairs.tsv  # merge "中文<TAB>English" lines
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "Packages/RightKitCore/Sources/RightKitCore/Resources/Localizable.xcstrings"
CALL = re.compile(r'\bL\("((?:[^"\\]|\\.)*)"')
SOURCES = [ROOT / "Packages", ROOT / "RightKit", ROOT / "RightKitFinder", ROOT / "RightKitAgent"]


def load() -> dict:
    if CATALOG.exists():
        return json.loads(CATALOG.read_text(encoding="utf-8"))
    return {"sourceLanguage": "zh-Hans", "strings": {}, "version": "1.0"}


def save(catalog: dict) -> None:
    catalog["strings"] = dict(sorted(catalog["strings"].items()))
    CATALOG.parent.mkdir(parents=True, exist_ok=True)
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def used_keys() -> set[str]:
    keys: set[str] = set()
    for base in SOURCES:
        for path in base.rglob("*.swift"):
            if "Tests" in path.parts:
                continue
            for match in CALL.finditer(path.read_text(encoding="utf-8")):
                keys.add(match.group(1).encode().decode("unicode_escape").encode("latin1").decode("utf-8"))
    return keys


def english(entry: dict) -> str | None:
    return entry.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value")


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "check"
    catalog = load()
    strings = catalog["strings"]
    if mode == "add":
        for line in sys.stdin.read().splitlines():
            if not line.strip():
                continue
            zh, en = line.split("\t")
            strings[zh] = {"localizations": {
                "en": {"stringUnit": {"state": "translated", "value": en}},
                "zh-Hans": {"stringUnit": {"state": "translated", "value": zh}}}}
        save(catalog)
        return 0
    missing = sorted(k for k in used_keys() if k not in strings or not english(strings[k]))
    unused = sorted(k for k in strings if k not in used_keys())
    for key in missing:
        print(f"missing translation: {key}")
    for key in unused:
        print(f"unused key: {key}")
    if missing:
        return 1
    print(f"String check passed: {len(strings)} keys.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
