#!/usr/bin/env python3
"""Set Larpy's factual category and free download price. Does not submit review."""
from decimal import Decimal
import json
from asc_request import request

APP = "6819279029"
INFO = "35d1f04a-776b-46b1-a2bb-55dff474dea1"
assert request(f"/v1/appInfos/{INFO}")["data"]["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"
assert "IOS" in request("/v1/appCategories/PRODUCTIVITY")["data"]["attributes"]["platforms"]
request(f"/v1/appInfos/{INFO}", "PATCH", {"data": {
    "type": "appInfos", "id": INFO, "relationships": {
        "primaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}}}}})
assert request(f"/v1/appInfos/{INFO}/primaryCategory")["data"]["id"] == "PRODUCTIVITY"
print(json.dumps({"primaryCategory": "PRODUCTIVITY"}), flush=True)

try:
    schedule = request(f"/v1/apps/{APP}/appPriceSchedule").get("data")
    if schedule:
        # Apple exposes an empty schedule shell even before initial pricing.
        request(f"/v1/appPriceSchedules/{schedule['id']}/manualPrices?limit=1")
except RuntimeError as error:
    if '"http": 404' not in str(error):
        raise
    schedule = None
if schedule is None:
    points = request(f"/v1/apps/{APP}/appPricePoints?filter[territory]=IRL&limit=200")["data"]
    free = next(p for p in points if Decimal(p["attributes"]["customerPrice"]) == 0)
    schedule = request("/v1/appPriceSchedules", "POST", {
        "data": {"type": "appPriceSchedules", "relationships": {
            "app": {"data": {"type": "apps", "id": APP}},
            "baseTerritory": {"data": {"type": "territories", "id": "IRL"}},
            "manualPrices": {"data": [{"type": "appPrices", "id": "${free-price}"}]}}},
        "included": [{"type": "appPrices", "id": "${free-price}",
                      "attributes": {"startDate": None, "endDate": None},
                      "relationships": {"appPricePoint": {"data": {
                          "type": "appPricePoints", "id": free["id"]}}}}]})["data"]
prices = request(f"/v1/appPriceSchedules/{schedule['id']}/manualPrices?include=appPricePoint&limit=200")
points = [p for p in prices.get("included", []) if p["type"] == "appPricePoints"]
assert points and all(Decimal(p["attributes"]["customerPrice"]) == 0 for p in points), "Inspect existing price; do not silently change it."
print(json.dumps({"downloadPrice": "free", "priceSchedule": schedule['id'], "reviewSubmitted": False}), flush=True)
