#!/usr/bin/env python3
"""Create the requested weekly subscription draft, without setting a price or submitting it."""
from asc_request import request

APP = "6819279029"
PRODUCT = "com.vano.larpy.plus.weekly"

def create(kind, attributes, relationships):
    return request("/v1/" + kind, "POST", {"data": {
        "type": kind, "attributes": attributes, "relationships": relationships,
    }})["data"]

def relation(kind, identifier):
    return {"data": {"type": kind, "id": identifier}}

groups = request(f"/v1/apps/{APP}/subscriptionGroups?limit=200")["data"]
group = next((g for g in groups if g["attributes"]["referenceName"] == "Larpy Plus"), None)
if group is None:
    group = create("subscriptionGroups", {"referenceName": "Larpy Plus"}, {"app": relation("apps", APP)})
group_id = group["id"]
products = request(f"/v1/subscriptionGroups/{group_id}/subscriptions?limit=200")["data"]
product = next((p for p in products if p["attributes"]["productId"] == PRODUCT), None)
if product is None:
    product = create("subscriptions", {"name": "Larpy Plus Weekly", "productId": PRODUCT,
        "subscriptionPeriod": "ONE_WEEK", "familySharable": False, "groupLevel": 1},
        {"group": relation("subscriptionGroups", group_id)})
product_id = product["id"]
group_localizations = request(f"/v1/subscriptionGroups/{group_id}/subscriptionGroupLocalizations")["data"]
if not any(l["attributes"]["locale"] == "en-GB" for l in group_localizations):
    create("subscriptionGroupLocalizations", {"name": "Larpy Plus", "locale": "en-GB"},
           {"subscriptionGroup": relation("subscriptionGroups", group_id)})
localizations = request(f"/v1/subscriptions/{product_id}/subscriptionLocalizations")["data"]
if not any(l["attributes"]["locale"] == "en-GB" for l in localizations):
    create("subscriptionLocalizations", {"name": "Larpy Plus — weekly", "locale": "en-GB",
        "description": "Weekly activity comparisons, summaries and next steps."},
        {"subscription": relation("subscriptions", product_id)})
else:
    localization = next(l for l in localizations if l["attributes"]["locale"] == "en-GB")
    request("/v1/subscriptionLocalizations/" + localization["id"], "PATCH", {"data": {
        "type": "subscriptionLocalizations", "id": localization["id"],
        "attributes": {"description": "Weekly activity comparisons, summaries and next steps."}}})
verified = request("/v1/subscriptions/" + product_id)["data"]
print({"group": group_id, "subscription": product_id, "attributes": verified["attributes"],
       "note": "Draft only. Price, availability, one-month trial and review evidence still required."})
