#!/usr/bin/env python3
"""Build a local preview of production SwiftUI views without running RightKit services.

Run make verify first, then:
  python3 scripts/e2e/localization_preview.py
  open -n .build/localization-preview/RightKitLocalizationPreview.app --args ja
The settings live only in memory. Do not use file/system-action buttons in this preview.
"""
import plistlib
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRODUCTS = ROOT / ".build/DerivedData/Build/Products/Debug-AppStore"
APP = ROOT / ".build/localization-preview/RightKitLocalizationPreview.app"
RESOURCES = APP / "Contents/Resources"
EXECUTABLE = APP / "Contents/MacOS/RightKitLocalizationPreview"
RESOURCES.mkdir(parents=True, exist_ok=True)
EXECUTABLE.parent.mkdir(parents=True, exist_ok=True)
# Use a private bundle ID for AppStorage and do not embed extension/agent executables.
(APP / "Contents/Info.plist").write_bytes(plistlib.dumps({
    "CFBundleIdentifier": "app.rightkit.localization-preview",
    "CFBundleName": "RightKitLocalizationPreview",
    "CFBundleExecutable": EXECUTABLE.name,
    "CFBundlePackageType": "APPL",
    "RKAppBundleID": "app.rightkit.localization-preview",
    "RKAppGroup": "app.rightkit.localization-preview",
    "RKURLScheme": "rightkit-localization-preview",
}))
for name in ["RightKitCore_RightKitCore.bundle", "Assets.car"]:
    source = PRODUCTS / "RightKit.app/Contents/Resources" / name
    target = RESOURCES / name
    if source.is_dir():
        shutil.copytree(source, target, dirs_exist_ok=True)
    else:
        shutil.copy2(source, target)
sources = [ROOT / "scripts/e2e/localization_preview.swift", ROOT / "RightKit/App/AppModel.swift",
           ROOT / "RightKit/App/WindowOpener.swift", ROOT / "RightKit/Services/Alerts.swift",
           ROOT / "RightKit/Services/TemplateLibrary.swift", ROOT / "RightKit/Views/WelcomeView.swift",
           *sorted((ROOT / "RightKit/Views/Settings").glob("*.swift")),
           *sorted((ROOT / "RightKit/Engine").glob("*.swift"))]
subprocess.run(["xcrun", "swiftc", "-parse-as-library", "-D", "APP_STORE", "-I", str(PRODUCTS),
                *map(str, sources), str(PRODUCTS / "RightKitCore.o"),
                "-o", str(EXECUTABLE)], check=True, cwd=ROOT)
subprocess.run(["codesign", "--force", "--sign", "-", str(APP)], check=True)
print(APP)
