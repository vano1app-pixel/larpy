#!/usr/bin/env python3
"""Upload real Larpy captures to the editable App Store draft; never submit it."""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
import json
import time
from asc_request import request

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION = "3cdc0ebf-7e19-408b-94ea-1c4bf335d7c0"
VERSION = "05a2207b-2359-46aa-8d7b-4c56ba5314d9"
PRODUCT = "6819757204"


def upload(kind, relationship, parent_type, parent_id, asset):
    data = asset.read_bytes()
    reservation = request("/v1/" + kind, "POST", {"data": {
        "type": kind, "attributes": {"fileName": asset.name, "fileSize": len(data)},
        "relationships": {relationship: {"data": {"type": parent_type, "id": parent_id}}}}})["data"]
    for operation in reservation["attributes"]["uploadOperations"]:
        offset, length = operation["offset"], operation["length"]
        headers = {h["name"]: h["value"] for h in operation["requestHeaders"]}
        req = Request(operation["url"], data=data[offset:offset + length],
                      headers=headers, method=operation["method"])
        with urlopen(req, timeout=60) as response:
            assert 200 <= response.status < 300
    identifier = reservation["id"]
    request(f"/v1/{kind}/{identifier}", "PATCH", {"data": {
        "type": kind, "id": identifier,
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    for _ in range(20):
        result = request(f"/v1/{kind}/{identifier}")["data"]
        state = result["attributes"]["assetDeliveryState"]
        if state["state"] in ("COMPLETE", "FAILED"):
            assert state["state"] == "COMPLETE", state
            print(json.dumps({"asset": asset.name, "id": identifier, "state": state}), flush=True)
            return result
        time.sleep(2)
    raise RuntimeError(f"Upload {identifier} still processing; inspect before retrying.")


assert request(f"/v1/appStoreVersions/{VERSION}")["data"]["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"
assets = ROOT / "QA/2026-10-06-review"
sets = request(f"/v1/appStoreVersionLocalizations/{LOCALIZATION}/appScreenshotSets")["data"]
for display, names in (
    ("APP_IPHONE_67", ("iphone-home.jpg", "iphone-focus-free.jpg")),
    ("APP_IPAD_PRO_3GEN_129", ("ipad-home.jpg", "ipad-focus-free.jpg")),
):
    screenshot_set = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == display), None)
    if screenshot_set is None:
        screenshot_set = request("/v1/appScreenshotSets", "POST", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display},
            "relationships": {"appStoreVersionLocalization": {"data": {
                "type": "appStoreVersionLocalizations", "id": LOCALIZATION}}}}})["data"]
    existing = request(f"/v1/appScreenshotSets/{screenshot_set['id']}/appScreenshots")["data"]
    for name in names:
        match = next((item for item in existing if item["attributes"]["fileName"] == name), None)
        if match:
            assert match["attributes"]["assetDeliveryState"]["state"] == "COMPLETE", match
            assert match["attributes"]["sourceFileChecksum"] == hashlib.md5((assets / name).read_bytes()).hexdigest()
            print(json.dumps({"asset": name, "state": "already COMPLETE"}), flush=True)
        else:
            upload("appScreenshots", "appScreenshotSet", "appScreenshotSets", screenshot_set["id"], assets / name)

# Replace only the obsolete, unsubmitted screenshot created during this task.
# The old local capture is retained in QA/2026-10-06-plus for audit history.
product = request(f"/v1/subscriptions/{PRODUCT}")["data"]
assert product["attributes"]["state"] in ("MISSING_METADATA", "READY_TO_SUBMIT")
try:
    previous = request(f"/v1/subscriptions/{PRODUCT}/appStoreReviewScreenshot").get("data")
except RuntimeError as error:
    if '"http": 404' not in str(error):
        raise
    previous = None
paywall = assets / "paywall-weekly-reviews.jpg"
if previous and previous["attributes"].get("sourceFileChecksum") != hashlib.md5(paywall.read_bytes()).hexdigest():
    assert previous["id"] == "2320d986-883f-4bc3-b78d-4f1b0ad44766", "Unexpected screenshot; inspect it before replacement."
    request(f"/v1/subscriptionAppStoreReviewScreenshots/{previous['id']}", "DELETE")
    previous = None
if previous is None:
    upload("subscriptionAppStoreReviewScreenshots", "subscription", "subscriptions", PRODUCT, paywall)
else:
    assert previous["attributes"]["assetDeliveryState"]["state"] == "COMPLETE"
    print(json.dumps({"asset": paywall.name, "state": "already COMPLETE"}), flush=True)
print(json.dumps({"reviewSubmitted": False}), flush=True)
