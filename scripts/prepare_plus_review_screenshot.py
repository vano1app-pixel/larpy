#!/usr/bin/env python3
"""Upload an actual simulator paywall capture to the unsubmitted subscription draft.

This is a screenshot, not evidence of a physical-device Sandbox purchase.
Never submits the subscription or app for review.
"""
from asc_request import request
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
import json
import time

PRODUCT = "6819757204"
asset = Path(__file__).resolve().parents[1] / "QA/2026-10-06-plus/paywall-returning-subscriber-xcode.png"
product = request("/v1/subscriptions/" + PRODUCT)["data"]
assert product["attributes"]["productId"] == "com.vano.larpy.plus.weekly"
assert product["attributes"]["state"] in ("MISSING_METADATA", "READY_TO_SUBMIT")
try:
    existing = request(f"/v1/subscriptions/{PRODUCT}/appStoreReviewScreenshot").get("data")
except RuntimeError as error:
    if '"http": 404' not in str(error):
        raise
    existing = None
if existing:
    print(json.dumps({"existingScreenshot": existing["id"], "state": existing["attributes"]["assetDeliveryState"]}))
    raise SystemExit(0)

data = asset.read_bytes()
kind = "subscriptionAppStoreReviewScreenshots"
reservation = request("/v1/" + kind, "POST", {"data": {
    "type": kind, "attributes": {"fileName": asset.name, "fileSize": len(data)},
    "relationships": {"subscription": {"data": {"type": "subscriptions", "id": PRODUCT}}}}})["data"]
for operation in reservation["attributes"]["uploadOperations"]:
    offset, length = operation["offset"], operation["length"]
    headers = {header["name"]: header["value"] for header in operation["requestHeaders"]}
    upload = Request(operation["url"], data=data[offset:offset + length], headers=headers, method=operation["method"])
    with urlopen(upload, timeout=60) as response:
        assert 200 <= response.status < 300
identifier = reservation["id"]
request(f"/v1/{kind}/{identifier}", "PATCH", {"data": {
    "type": kind, "id": identifier,
    "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
for _ in range(20):
    result = request(f"/v1/{kind}/{identifier}")["data"]
    state = result["attributes"]["assetDeliveryState"]
    if state["state"] in ("COMPLETE", "FAILED"):
        print(json.dumps({"screenshot": identifier, "state": state}))
        assert state["state"] == "COMPLETE", "Apple did not accept the screenshot"
        break
    time.sleep(2)
else:
    print(json.dumps({"screenshot": identifier, "state": state, "needsPolling": True}))
print(json.dumps({"subscriptionState": request('/v1/subscriptions/' + PRODUCT)["data"]["attributes"]["state"]}))
