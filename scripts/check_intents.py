#!/usr/bin/env python3
"""V-074: the built app exposes exactly the nine App Intents from F-074."""

import json
import sys
from pathlib import Path

EXPECTED = {
    "CopyPathIntent", "CopyNameIntent", "NewFileIntent", "FileHashIntent", "ConvertImageIntent",
    "MacIconSetIntent", "IOSIconSetIntent", "QRCodeIntent", "OpenInAppIntent",
}
app = Path(sys.argv[1] if len(sys.argv) > 1 else ".build/DerivedData/Build/Products/Debug/RightKit.app")
data = json.loads((app / "Contents/Resources/Metadata.appintents/extract.actionsdata").read_text())
actions = set(data["actions"])
if actions != EXPECTED:
    print(f"error: unexpected intents; missing={sorted(EXPECTED - actions)} extra={sorted(actions - EXPECTED)}")
    sys.exit(1)
if any("Delete" in a or "Dissolve" in a for a in actions):
    print("error: delete or dissolve must not be an intent")
    sys.exit(1)
print(f"Intent check passed: {len(actions)} actions.")
