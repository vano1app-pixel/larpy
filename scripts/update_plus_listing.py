#!/usr/bin/env python3
"""Save verified legal/support URLs and the Plus scope on Larpy's draft listing. No submission."""
from asc_request import request

APP = "6819279029"
BASE = "https://vano1app-pixel.github.io/larpy-support/"
TERMS = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
versions = request(f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS")["data"]
version = next(v for v in versions if v["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION")
for item in request(f'/v1/appStoreVersions/{version["id"]}/appStoreVersionLocalizations')["data"]:
    if item["attributes"]["locale"] != "en-GB":
        continue
    description = item["attributes"]["description"] or ""
    marker = "\n\nLARPY PLUS"
    description = description.split(marker)[0]
    description += marker + "\nOptional Larpy Plus adds detailed weekly reviews: matching-weekday comparisons for Body, Work and Learnt, a weekly summary and a next-step suggestion. Activity logging, saved history, reflections, earned outfits, app blocking and timed breaks stay free. No app account is required.\n\nPlus is a weekly auto-renewable subscription. Apple shows the local price and any eligible introductory trial before you subscribe. Cancel in your Apple subscription settings.\n\nTerms of Use: " + TERMS + "\nPrivacy policy: " + BASE + "privacy.html"
    attrs = {"supportUrl": BASE, "description": description}
    request("/v1/appStoreVersionLocalizations/" + item["id"], "PATCH", {"data": {
        "type": "appStoreVersionLocalizations", "id": item["id"], "attributes": attrs}})
    saved = request("/v1/appStoreVersionLocalizations/" + item["id"])["data"]["attributes"]
    assert all(saved[k] == v for k, v in attrs.items())
    print("Draft description and support URL verified")
for info in request(f"/v1/apps/{APP}/appInfos")["data"]:
    if info["attributes"]["appStoreState"] != "PREPARE_FOR_SUBMISSION":
        continue
    for item in request(f'/v1/appInfos/{info["id"]}/appInfoLocalizations')["data"]:
        request("/v1/appInfoLocalizations/" + item["id"], "PATCH", {"data": {
            "type": "appInfoLocalizations", "id": item["id"], "attributes": {"privacyPolicyUrl": BASE + "privacy.html"}}})
        saved = request("/v1/appInfoLocalizations/" + item["id"])["data"]["attributes"]
        assert saved["privacyPolicyUrl"] == BASE + "privacy.html"
        print("Draft privacy URL verified: " + item["attributes"]["locale"])
print("No review submission or external message sent")
