#!/usr/bin/env python3
"""Release 菜单基准；只在临时目录创建测试文件，不启动或注册 RightKit。"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / ".build/menu-performance"
subprocess.run(["swift", "build", "--package-path", str(ROOT / "Packages/RightKitCore"),
                "-c", "release", "--scratch-path", str(SCRATCH)], check=True, cwd=ROOT)
objects = list(SCRATCH.rglob("RightKitCore.o"))
if len(objects) != 1:
    raise SystemExit(f"Expected one RightKitCore.o, found {len(objects)}")
products = objects[0].parent
with tempfile.TemporaryDirectory(prefix="rightkit-menu-perf-") as temporary:
    output = Path(temporary)
    bundles = list(products.glob("RightKitCore_RightKitCore.bundle"))
    if len(bundles) != 1:
        raise SystemExit("RightKitCore resource bundle missing")
    (output / bundles[0].name).symlink_to(bundles[0])
    executable = output / "menu-pipeline"
    subprocess.run(["xcrun", "swiftc", "-parse-as-library", "-O", "-I", str(products),
                    str(ROOT / "RightKitFinder/MenuRenderer.swift"),
                    str(ROOT / "RightKitFinder/PendingPasteState.swift"),
                    str(ROOT / "scripts/perf/menu_pipeline.swift"), str(objects[0]),
                    "-o", str(executable)], check=True, cwd=ROOT)
    subprocess.run([str(executable)], check=True, cwd=ROOT)
