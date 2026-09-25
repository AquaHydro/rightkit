#!/usr/bin/env python3
"""Validate required documentation and local Markdown links."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = (
    Path("README.md"),
    Path("AGENTS.md"),
    Path("CONTEXT.md"),
    Path("DESIGN.md"),
    Path("docs/features.md"),
    Path("docs/roadmap.md"),
    Path("docs/technical.md"),
    Path("docs/verification.md"),
)
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")


def markdown_files() -> list[Path]:
    files = [path for path in ROOT.rglob("*.md") if not {".git", "node_modules"} & set(path.parts)]
    return sorted(files)


def local_link_target(raw_target: str) -> str | None:
    target = raw_target.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    target = target.split(maxsplit=1)[0]
    parsed = urlsplit(target)
    if parsed.scheme or parsed.netloc or not parsed.path:
        return None
    return unquote(parsed.path)


def main() -> int:
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing required document: {relative_path}")
        elif not path.read_text(encoding="utf-8").strip():
            errors.append(f"empty required document: {relative_path}")

    for document in markdown_files():
        text = document.read_text(encoding="utf-8")
        for match in MARKDOWN_LINK.finditer(text):
            target = local_link_target(match.group(1))
            if target is None:
                continue
            resolved = (document.parent / target).resolve()
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                errors.append(
                    f"{document.relative_to(ROOT)}: link escapes repository: {target}"
                )
                continue
            if not resolved.exists():
                errors.append(
                    f"{document.relative_to(ROOT)}: broken relative link: {target}"
                )

    if errors:
        print("Documentation check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        f"Documentation check passed: {len(REQUIRED_FILES)} required files, "
        f"{len(markdown_files())} Markdown files."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
