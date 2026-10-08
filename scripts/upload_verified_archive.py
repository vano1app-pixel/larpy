#!/usr/bin/env python3
"""Upload an already verified archive to Apple. Does not submit for App Review.

Uses the existing local API credential without printing it. Upload logs and IPA
files stay outside the repository. Temporary key material is removed on exit.
"""
from pathlib import Path
import argparse
import json
import os
import plistlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("release", type=Path)
args = parser.parse_args()
release = args.release.resolve()
assert not release.is_relative_to(Path(__file__).resolve().parents[1])
proof = json.loads((release / "archive-verification.json").read_text())
assert len(proof) == 6 and all(p["signature"] == "verified" for p in proof)
options = plistlib.loads((release / "ExportOptions.plist").read_bytes())
assert options["method"] == "app-store-connect" and options["signingStyle"] == "manual"
options["destination"] = "upload"
upload_options = release / "ExportOptions-Upload.plist"
upload_options.write_bytes(plistlib.dumps(options))
credentials = json.loads((Path.home() / ".appstoreconnect/asc_key.json").read_text())
log = release / "upload.log"
with tempfile.TemporaryDirectory(prefix="larpy-upload-key-", dir="/private/tmp") as directory:
    key = Path(directory) / ("AuthKey_" + credentials["key_id"] + ".p8")
    key.write_text(credentials["key"])
    os.chmod(key, 0o600)
    command = ["xcodebuild", "-exportArchive", "-archivePath", str(release / "Larpy.xcarchive"),
               "-exportPath", str(release / "uploaded-export"), "-exportOptionsPlist", str(upload_options),
               "-authenticationKeyPath", str(key), "-authenticationKeyID", credentials["key_id"],
               "-authenticationKeyIssuerID", credentials["issuer_id"], "-allowProvisioningUpdates"]
    with log.open("w") as output:
        result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT)
    os.chmod(log, 0o600)
print(json.dumps({"exitCode": result.returncode, "log": str(log)}))
raise SystemExit(result.returncode)
