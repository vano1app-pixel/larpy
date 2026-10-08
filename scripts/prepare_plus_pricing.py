#!/usr/bin/env python3
"""Stage the requested EUR 2 weekly plan and 1-month trial. Never submits for review.

Default is a read-only plan. --apply only accepts a never-approved draft product,
uses Apple's territory equalizations and refuses to replace existing prices/offers.
"""
from asc_request import request
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal
from pathlib import Path
from urllib.parse import urlsplit
import json
import sys

PRODUCT = "6819757204"

def all_records(path):
    rows = []
    while path:
        page = request(path)
        rows.extend(page["data"])
        next_url = page.get("links", {}).get("next")
        path = (urlsplit(next_url).path + "?" + urlsplit(next_url).query) if next_url else None
    return rows

def link(kind, identifier):
    return {"data": {"type": kind, "id": identifier}}

def territory(record):
    return record["relationships"]["territory"]["data"]["id"]

product = request("/v1/subscriptions/" + PRODUCT)["data"]
assert product["attributes"]["productId"] == "com.vano.larpy.plus.weekly"
assert product["attributes"]["subscriptionPeriod"] == "ONE_WEEK"
assert product["attributes"]["state"] in ("MISSING_METADATA", "READY_TO_SUBMIT"), "Refuse to change a submitted/approved product"
points = all_records(f"/v1/subscriptions/{PRODUCT}/pricePoints?filter[territory]=IRL&limit=200")
base = next(p for p in points if Decimal(p["attributes"]["customerPrice"]) == Decimal("2.00"))
equalized = all_records(f'/v1/subscriptionPricePoints/{base["id"]}/equalizations?include=territory&limit=200')
planned = {territory(p): p for p in equalized}
planned["IRL"] = base
prices = all_records(f"/v1/subscriptions/{PRODUCT}/prices?include=territory,subscriptionPricePoint&limit=200")
offers = all_records(f"/v1/subscriptions/{PRODUCT}/introductoryOffers?include=territory&limit=200")
existing_prices = {territory(p): p for p in prices}
existing_offers = {territory(o): o for o in offers}
for code, current in existing_prices.items():
    if code in planned:
        assert current["relationships"]["subscriptionPricePoint"]["data"]["id"] == planned[code]["id"], "Refuse to replace existing price: " + code
for code, current in existing_offers.items():
    a = current["attributes"]
    assert a["offerMode"] == "FREE_TRIAL" and a["duration"] == "ONE_MONTH" and a["numberOfPeriods"] == 1, "Refuse to replace existing offer: " + code
plan = {"baseCurrency": "EUR", "baseTerritory": "IRL", "baseWeeklyPrice": "2.00", "trial": "ONE_MONTH",
        "territories": len(planned), "existingPrices": len(existing_prices), "existingOffers": len(existing_offers)}
print(json.dumps(plan), flush=True)
if "--apply" not in sys.argv:
    print("Read-only plan. Use --apply to stage draft pricing; this does not submit or publish.")
    raise SystemExit(0)

try:
    availability = request(f"/v1/subscriptions/{PRODUCT}/subscriptionAvailability").get("data")
except RuntimeError as error:
    if '"http": 404' not in str(error):
        raise
    availability = None
if availability is None:
    request("/v1/subscriptionAvailabilities", "POST", {"data": {
        "type": "subscriptionAvailabilities", "attributes": {"availableInNewTerritories": True},
        "relationships": {"subscription": link("subscriptions", PRODUCT),
                          "availableTerritories": {"data": [{"type": "territories", "id": code} for code in planned]}}}})
    print("Draft territory availability created before pricing", flush=True)

def configure(item):
    code, point = item
    if code not in existing_prices:
        request("/v1/subscriptionPrices", "POST", {"data": {
            "type": "subscriptionPrices", "attributes": {"preserveCurrentPrice": False, "startDate": None},
            "relationships": {"subscription": link("subscriptions", PRODUCT),
                              "territory": link("territories", code),
                              "subscriptionPricePoint": link("subscriptionPricePoints", point["id"])}}})
    if code not in existing_offers:
        request("/v1/subscriptionIntroductoryOffers", "POST", {"data": {
            "type": "subscriptionIntroductoryOffers",
            "attributes": {"duration": "ONE_MONTH", "numberOfPeriods": 1, "offerMode": "FREE_TRIAL"},
            "relationships": {"subscription": link("subscriptions", PRODUCT), "territory": link("territories", code)}}})
    return code

# Countries are independent. Keep concurrency low to respect Apple's API limits.
with ThreadPoolExecutor(max_workers=3) as pool:
    for index, code in enumerate(pool.map(configure, planned.items()), 1):
        if code == "IRL" or index % 25 == 0:
            print(f"Configured {index}/{len(planned)} territories; latest {code}", flush=True)
final_prices = all_records(f"/v1/subscriptions/{PRODUCT}/prices?include=territory,subscriptionPricePoint&limit=200")
final_offers = all_records(f"/v1/subscriptions/{PRODUCT}/introductoryOffers?include=territory&limit=200")
assert set(planned) <= {territory(p) for p in final_prices}
assert set(planned) <= {territory(o) for o in final_offers if o["attributes"]["duration"] == "ONE_MONTH" and o["attributes"]["offerMode"] == "FREE_TRIAL"}
for price in final_prices:
    code = territory(price)
    if code in planned:
        assert price["relationships"]["subscriptionPricePoint"]["data"]["id"] == planned[code]["id"]
evidence = {**plan, "verifiedPrices": len(final_prices), "verifiedOffers": len(final_offers),
            "prices": final_prices, "offers": final_offers}
Path("/private/tmp/larpy-plus-pricing-20261006.json").write_text(json.dumps(evidence, indent=2))
print("Draft prices and one-month trial verified. Availability/review are separate; no submission made.", flush=True)
