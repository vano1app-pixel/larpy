#!/usr/bin/env python3
"""Prepare a processed Larpy build for internal QA without inviting testers.

Disables automatic notifications, sets What to Test, assigns the build to an
internal group and selects it in the existing editable App Store draft.
Does not submit either App Review or external Beta App Review.
"""
import argparse
import json
from pathlib import Path
from asc_request import request

APP = "6819279029"
VERSION = "05a2207b-2359-46aa-8d7b-4c56ba5314d9"
NOTES = """Larpy Plus Monthly: eligible new subscribers get seven days free, then the monthly price shown by Apple (EUR 3.99/month in Ireland). Product: com.vano.larpy.plus.monthly. TestFlight purchases use Apple's no-charge test environment.

Please test on a physical iPhone:
1. Launch, finish onboarding, log Body / Work / Learnt, view saved activities and run the free timer.
2. Open Settings > Larpy Plus. Check Apple's price, trial eligibility, Terms and Privacy links. Purchase, confirm immediate Plus access, then restore after reinstall. Check cancellation, expiration and pending approval.
3. Without a subscription, authorize Screen Time and choose a disposable test app. Start protected focus, verify its shield, take a timed break, verify re-blocking in the background, then End focus. Revoke permission and verify access is restored. All Screen Time features are free.
4. Open the weekly review, save a reflection, and verify saved notes remain available when Plus expires.
5. Check Health workout import, calendar, share extension, widgets, iPad layout and larger text. Report any crash or unclear wording with the device and iOS version.

Known verification boundary: build 8 loaded the new monthly product and opened Apple's sign-in prompt in the simulator. A completed remote Sandbox purchase/restore and physical-device blocking still require this test pass. No Larpy account or server login is needed. Earlier local Xcode StoreKit results concern the previous weekly product and do not verify the monthly release."""

parser = argparse.ArgumentParser()
parser.add_argument("build")
parser.add_argument("--evidence", type=Path, required=True)
args = parser.parse_args()
builds = request(f"/v1/builds?filter[app]={APP}&filter[version]={args.build}&include=buildBetaDetail&limit=10")
assert len(builds["data"]) == 1
build = builds["data"][0]
assert build["attributes"]["processingState"] == "VALID"
build_id = build["id"]
request(f"/v1/buildBetaDetails/{build_id}", "PATCH", {"data": {
    "type": "buildBetaDetails", "id": build_id, "attributes": {"autoNotifyEnabled": False}}})

localizations = request(f"/v1/builds/{build_id}/betaBuildLocalizations")["data"]
existing = next((item for item in localizations if item["attributes"]["locale"] == "en-GB"), None)
if existing:
    request(f"/v1/betaBuildLocalizations/{existing['id']}", "PATCH", {"data": {
        "type": "betaBuildLocalizations", "id": existing["id"], "attributes": {"whatsNew": NOTES}}})
else:
    request("/v1/betaBuildLocalizations", "POST", {"data": {
        "type": "betaBuildLocalizations", "attributes": {"locale": "en-GB", "whatsNew": NOTES},
        "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}})

groups = request(f"/v1/betaGroups?filter[app]={APP}&limit=50")["data"]
group = next((g for g in groups if g["attributes"]["name"] == "Internal QA" and g["attributes"]["isInternalGroup"]), None)
if not group:
    group = request("/v1/betaGroups", "POST", {"data": {"type": "betaGroups", "attributes": {
        "name": "Internal QA", "isInternalGroup": True, "hasAccessToAllBuilds": False},
        "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]
assigned = request(f"/v1/betaGroups/{group['id']}/relationships/builds")["data"]
if not any(item["id"] == build_id for item in assigned):
    request(f"/v1/betaGroups/{group['id']}/relationships/builds", "POST", {
        "data": [{"type": "builds", "id": build_id}]})

version = request(f"/v1/appStoreVersions/{VERSION}")["data"]
assert version["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"
request(f"/v1/appStoreVersions/{VERSION}/relationships/build", "PATCH", {
    "data": {"type": "builds", "id": build_id}})

proof = {
    "build": request(f"/v1/builds/{build_id}?include=buildBetaDetail"),
    "notes": request(f"/v1/builds/{build_id}/betaBuildLocalizations"),
    "group": request(f"/v1/betaGroups/{group['id']}"),
    "assignedBuilds": request(f"/v1/betaGroups/{group['id']}/relationships/builds"),
    "draftBuild": request(f"/v1/appStoreVersions/{VERSION}/relationships/build"),
}
args.evidence.write_text(json.dumps(proof, indent=2))
assert proof["notes"]["data"][0]["attributes"]["whatsNew"] == NOTES
assert proof["draftBuild"]["data"]["id"] == build_id
print(json.dumps({"build": args.build, "processingState": "VALID", "internalGroup": group["id"],
                  "whatToTest": "verified", "draftBuild": "selected", "testersInvited": 0,
                  "reviewSubmitted": False, "evidence": str(args.evidence)}))
