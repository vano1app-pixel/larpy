#!/usr/bin/env python3
"""Snapshot the six-target app and attach already-verified manual profiles.

Signing settings only change in the private release snapshot, never the checkout.
Does not archive, upload, accept agreements or submit anything for review.
"""
from pathlib import Path
import argparse
import hashlib
import json
import plistlib
import re
import shutil

parser = argparse.ArgumentParser()
parser.add_argument("profiles", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
profiles = json.loads(args.profiles.read_text())
assert len(profiles) == 6 and all(p["validForBuild"] for p in profiles)
by_bundle = {p["bundle"]: p for p in profiles}
args.output.mkdir(mode=0o700)
source = args.output / "source"
source.mkdir()
folders = ["Larpy", "LarpyWidget", "LarpyShare", "LarpyFocusAction", "LarpyFocusMonitor", "LarpyFocusShield", "Shared", "Larpy.xcodeproj"]
manifest = {}
for name in folders:
    shutil.copytree(root / name, source / name, ignore=shutil.ignore_patterns("xcuserdata", ".DS_Store"))
    for path in sorted((source / name).rglob("*")):
        if path.is_file():
            manifest[str(path.relative_to(source))] = hashlib.sha256(path.read_bytes()).hexdigest()
(args.output / "source-sha256.json").write_text(json.dumps(manifest, indent=2))

for p in profiles:
    for relative in ("Library/Developer/Xcode/UserData/Provisioning Profiles", "Library/MobileDevice/Provisioning Profiles"):
        directory = Path.home() / relative
        directory.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p["path"], directory / (p["uuid"] + ".mobileprovision"))

project = source / "Larpy.xcodeproj/project.pbxproj"
changed = []
def attach(match):
    text = match.group(0)
    bundle = re.search(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", text)
    if not bundle:
        return text
    profile = by_bundle[bundle.group(1).strip('"')]
    changed.append(profile["target"])
    text = text.replace("CODE_SIGN_STYLE = Automatic;", "CODE_SIGN_STYLE = Manual;")
    return text.replace("buildSettings = {", 'buildSettings = {\n\t\t\t\tCODE_SIGN_IDENTITY = "Apple Distribution";\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "' + profile["uuid"] + '";')
project.write_text(re.sub(r"buildSettings = \{[\s\S]*?\n\t\t\t\};", attach, project.read_text()))
assert len(changed) == 12 and set(changed) == {p["target"] for p in profiles}
options = {
    "method": "app-store-connect", "destination": "export", "signingStyle": "manual",
    "teamID": "36RZ9VDHBC", "signingCertificate": "Apple Distribution",
    "provisioningProfiles": {p["bundle"]: p["uuid"] for p in profiles},
    "manageAppVersionAndBuildNumber": False, "uploadSymbols": True,
    "testFlightInternalTestingOnly": False,
}
with (args.output / "ExportOptions.plist").open("wb") as file:
    plistlib.dump(options, file)
print("Snapshot and six signing profiles prepared: " + str(args.output))
