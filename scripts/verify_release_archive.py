#!/usr/bin/env python3
"""Verify signed app/extension identities, versions and required entitlements."""
from pathlib import Path
import argparse
import json
import plistlib
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("archive", type=Path)
parser.add_argument("--build", required=True)
args = parser.parse_args()
app = args.archive / "Products/Applications/Larpy.app"
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
results = []
bundles = [app, *sorted((app / "PlugIns").glob("*.appex"))]
assert len(bundles) == 6
for bundle in bundles:
    info = plistlib.loads((bundle / "Info.plist").read_bytes())
    ent = plistlib.loads(subprocess.run(["codesign", "-d", "--entitlements", ":-", str(bundle)], capture_output=True, check=True).stdout)
    profile = plistlib.loads(subprocess.run(["security", "cms", "-D", "-i", str(bundle / "embedded.mobileprovision")], capture_output=True, check=True).stdout)
    assert info["CFBundleShortVersionString"] == "1.0" and info["CFBundleVersion"] == args.build
    assert ent.get("com.apple.security.application-groups") == ["group.com.vano.larpy"]
    assert profile["Entitlements"].get("get-task-allow") is False
    assert ent["application-identifier"] == profile["Entitlements"]["application-identifier"]
    assert ent["application-identifier"].endswith("." + info["CFBundleIdentifier"])
    if bundle == app or "Focus" in bundle.name:
        assert ent.get("com.apple.developer.family-controls") is True
        assert profile["Entitlements"].get("com.apple.developer.family-controls") is True
    if bundle == app:
        assert info.get("ITSAppUsesNonExemptEncryption") is False
        assert info["CFBundleIdentifier"] == "com.vano.larpy"
        assert ent.get("com.apple.developer.healthkit") is True
        assert info.get("NSHealthShareUsageDescription", "").strip()
        assert info.get("NSHealthUpdateUsageDescription", "").strip()
    results.append({"target": bundle.stem, "version": "1.0", "build": args.build,
                    "signature": "verified", "familyControls": ent.get("com.apple.developer.family-controls", False)})
(args.archive.parent / "archive-verification.json").write_text(json.dumps(results, indent=2))
print(json.dumps(results))
