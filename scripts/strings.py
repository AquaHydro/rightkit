#!/usr/bin/env python3
"""Keep the RightKit string catalog in sync with L("…") calls.

  python3 scripts/strings.py check          # validate all app languages, catalogs, placeholders and services
  python3 scripts/strings.py add < pairs.tsv  # merge "中文<TAB>English" lines
"""

from __future__ import annotations

import json
import re
import sys
import subprocess
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "Packages/RightKitCore/Sources/RightKitCore/Resources/Localizable.xcstrings"
CALL = re.compile(r'\bL\("((?:[^"\\]|\\.)*)"')
CATALOGS = [CATALOG, *sorted((ROOT / "RightKit/Resources").glob("*.xcstrings"))]
SUPPORTED = ("zh-Hans", "en", "ja", "ko")
FORMAT = re.compile(r"%(?:[1-9]\d*\$)?[-+#0 ']*(?:\d+|\*)?(?:\.\d+)?(?:hh|ll|[hlLzjt])?[@diuoxXfFeEgGaAcCsSp]")
SHORTCUT = re.compile(r"\$\{[^}]+\}")
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


def translated(entry: dict, language: str) -> str | None:
    unit = entry.get("localizations", {}).get(language, {}).get("stringUnit", {})
    return unit.get("value") if unit.get("state") == "translated" else None


def placeholders(value: str) -> Counter:
    # Compare each argument's index and type; a translator may reorder them safely.
    formats = []
    implicit_index = 1
    for token in FORMAT.findall(value.replace("%%", "")):
        position = re.match(r"%([1-9]\d*)\$", token)
        index = int(position.group(1)) if position else implicit_index
        if not position:
            implicit_index += 1
        formats.append((index, re.sub(r"^%[1-9]\d*\$", "%", token)))
    return Counter(formats + SHORTCUT.findall(value))


def validate_catalog(catalog: dict, label: str) -> list[str]:
    errors = []
    for key, entry in catalog["strings"].items():
        source = translated(entry, catalog["sourceLanguage"]) or key
        for language in SUPPORTED:
            value = translated(entry, language)
            if not value:
                errors.append(f"{label}: missing {language} translation: {key}")
            elif placeholders(source) != placeholders(value):
                errors.append(f"{label}: {language} placeholder mismatch: {key}")
    return errors


def service_values(path: Path) -> dict:
    result = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(path)],
                            check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def validate_compiled(app: Path) -> list[str]:
    resources = app / "Contents/Resources"
    errors = []
    for catalog_path in CATALOGS:
        base = (resources / "RightKitCore_RightKitCore.bundle/Contents/Resources"
                if catalog_path == CATALOG else resources)
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        for language in SUPPORTED:
            path = base / f"{language}.lproj/{catalog_path.stem}.strings"
            if not path.exists():
                errors.append(f"{app.name}: missing compiled {path.relative_to(resources)}")
                continue
            values = service_values(path)
            for key, entry in catalog["strings"].items():
                if values.get(key) != translated(entry, language):
                    errors.append(f"{app.name}: compiled {language} {catalog_path.stem} mismatch: {key}")
    for language in SUPPORTED:
        source = service_values(ROOT / f"RightKit/Resources/{language}.lproj/ServicesMenu.strings")
        path = resources / f"{language}.lproj/ServicesMenu.strings"
        if not path.exists() or service_values(path) != source:
            errors.append(f"{app.name}: compiled services mismatch: {language}")
    return errors


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "check"
    catalog = load()
    strings = catalog["strings"]
    if mode == "add":
        for line in sys.stdin.read().splitlines():
            if not line.strip():
                continue
            zh, en = line.split("\t")
            localizations = strings.setdefault(zh, {}).setdefault("localizations", {})
            localizations.update({
                "en": {"stringUnit": {"state": "translated", "value": en}},
                "zh-Hans": {"stringUnit": {"state": "translated", "value": zh}}})
        save(catalog)
        return 0
    errors = [f"missing catalog key: {key}" for key in sorted(used_keys() - strings.keys())]
    for path in CATALOGS:
        errors.extend(validate_catalog(json.loads(path.read_text(encoding="utf-8")), str(path.relative_to(ROOT))))
    source_services = service_values(ROOT / "RightKit/Resources/zh-Hans.lproj/ServicesMenu.strings")
    for language in SUPPORTED:
        path = ROOT / f"RightKit/Resources/{language}.lproj/ServicesMenu.strings"
        if not path.exists():
            errors.append(f"missing services: {language}")
            continue
        values = service_values(path)
        if values.keys() != source_services.keys() or any(not value for value in values.values()):
            errors.append(f"incomplete services: {language}")
    if len(sys.argv) > 2:
        errors.extend(validate_compiled(Path(sys.argv[2])))
    for error in errors:
        print(error)
    if errors:
        return 1
    print(f"String check passed: {len(strings)} shared keys, {len(CATALOGS)} catalogs, {len(SUPPORTED)} languages, services and placeholders.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
