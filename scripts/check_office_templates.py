#!/usr/bin/env python3
"""Validate the built-in Office templates' OPC package structure (F-010)."""

from __future__ import annotations

import posixpath
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = ROOT / "RightKit" / "Resources" / "Templates"

CT_NS = "{http://schemas.openxmlformats.org/package/2006/content-types}"
REL_NS = "{http://schemas.openxmlformats.org/package/2006/relationships}"
OREL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/"
OCT = "application/vnd.openxmlformats-officedocument."

MAIN_CT = {
    "docx": OCT + "wordprocessingml.document.main+xml",
    "xlsx": OCT + "spreadsheetml.sheet.main+xml",
    "pptx": OCT + "presentationml.presentation.main+xml",
}
# Relationship type -> content type its target must have.
REL_CT = {
    "http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties":
        "application/vnd.openxmlformats-package.core-properties+xml",
    OREL + "extended-properties": OCT + "extended-properties+xml",
    OREL + "theme": OCT + "theme+xml",
    OREL + "worksheet": OCT + "spreadsheetml.worksheet+xml",
    OREL + "slideMaster": OCT + "presentationml.slideMaster+xml",
    OREL + "slideLayout": OCT + "presentationml.slideLayout+xml",
    OREL + "slide": OCT + "presentationml.slide+xml",
    OREL + "presProps": OCT + "presentationml.presProps+xml",
    OREL + "viewProps": OCT + "presentationml.viewProps+xml",
    OREL + "tableStyles": OCT + "presentationml.tableStyles+xml",
    OREL + "settings": OCT + "wordprocessingml.settings+xml",
}
STYLES_CT = {
    "docx": OCT + "wordprocessingml.styles+xml",
    "xlsx": OCT + "spreadsheetml.styles+xml",
}
RELS_CT = "application/vnd.openxmlformats-package.relationships+xml"


def check(path: Path) -> list[str]:
    ext = path.suffix[1:]
    errors: list[str] = []
    err = lambda msg: errors.append(f"{path.name}: {msg}")  # noqa: E731

    if not zipfile.is_zipfile(path):
        return [f"{path.name}: not a zip file"]
    with zipfile.ZipFile(path) as zf:
        if (bad := zf.testzip()) is not None:
            return [f"{path.name}: corrupt member {bad}"]
        parts = {n: zf.read(n) for n in zf.namelist() if not n.endswith("/")}

    trees = {}
    for name, data in parts.items():
        try:
            trees[name] = ET.fromstring(data)
        except ET.ParseError as e:
            err(f"{name} is not well-formed XML: {e}")
    if errors:
        return errors

    if "[Content_Types].xml" not in trees:
        return [f"{path.name}: missing [Content_Types].xml"]
    ct = trees["[Content_Types].xml"]
    defaults = {d.get("Extension", "").lower(): d.get("ContentType") for d in ct.iter(CT_NS + "Default")}
    overrides = {o.get("PartName", "").lstrip("/"): o.get("ContentType") for o in ct.iter(CT_NS + "Override")}

    def content_type(part: str) -> str | None:
        # not splitext: it treats "_rels/.rels" as extensionless
        name = posixpath.basename(part)
        extension = name.rsplit(".", 1)[1].lower() if "." in name else ""
        return overrides.get(part) or defaults.get(extension)

    for part in overrides:
        if part not in parts:
            err(f"Override for missing part /{part}")
    for part in parts:
        if part == "[Content_Types].xml":
            continue
        if content_type(part) is None:
            err(f"no content type for /{part}")
        if part.endswith(".rels") and content_type(part) != RELS_CT:
            err(f"/{part} has content type {content_type(part)}, expected {RELS_CT}")

    if "_rels/.rels" not in trees:
        err("missing _rels/.rels")
    for rels_name, tree in trees.items():
        if not rels_name.endswith(".rels"):
            continue
        # a/b/_rels/c.xml.rels describes a/b/c.xml; targets resolve against a/b/
        base = posixpath.dirname(posixpath.dirname(rels_name))
        source = posixpath.join(base, posixpath.basename(rels_name)[: -len(".rels")])
        if rels_name != "_rels/.rels" and source not in parts:
            err(f"{rels_name} describes missing part {source}")
        ids = set()
        for rel in tree.iter(REL_NS + "Relationship"):
            rid, rtype, target = rel.get("Id"), rel.get("Type"), rel.get("Target", "")
            if rid in ids:
                err(f"{rels_name}: duplicate Id {rid}")
            ids.add(rid)
            if rel.get("TargetMode") == "External":
                continue
            resolved = target.lstrip("/") if target.startswith("/") else posixpath.normpath(posixpath.join(base, target))
            if resolved not in parts:
                err(f"{rels_name}: {rid} target {target} -> {resolved} does not exist")
                continue
            expected = REL_CT.get(rtype)
            if rtype == OREL + "officeDocument":
                expected = MAIN_CT[ext]
            elif rtype == OREL + "styles":
                expected = STYLES_CT.get(ext)
            if expected and content_type(resolved) != expected:
                err(f"/{resolved} has content type {content_type(resolved)}, expected {expected}")

    main = [r for r in trees.get("_rels/.rels", ET.Element("x")).iter(REL_NS + "Relationship")
            if r.get("Type") == OREL + "officeDocument"]
    if len(main) != 1:
        err(f"_rels/.rels must have exactly one officeDocument relationship, found {len(main)}")
    return errors


def main() -> int:
    files = [TEMPLATES / f"Template.{ext}" for ext in MAIN_CT]
    errors = []
    for f in files:
        errors += check(f) if f.exists() else [f"missing {f.relative_to(ROOT)}"]
    for e in errors:
        print(f"error: {e}", file=sys.stderr)
    if errors:
        return 1
    print(f"Office templates OK: {', '.join(f.name for f in files)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
