#!/usr/bin/env python3
"""Save factual Larpy review notes and age-rating answers; never submit review."""
import json
from asc_request import request

INFO = "35d1f04a-776b-46b1-a2bb-55dff474dea1"
REVIEW = "408d0425-3975-43aa-9fce-795e54ac0621"
assert request(f"/v1/appInfos/{INFO}")["data"]["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"

# Apple defines UGC as broad in-app distribution, messaging as in-app user
# communication and web access as an embedded browser. Larpy has none of these:
# notes/photos are local and explicit exports use the system share sheet.
# Self-directed Screen Time focus is not parental control of another person.
attributes = {field: False for field in (
    "advertising", "gambling", "lootBox", "messagingAndChat", "parentalControls",
    "ageAssurance", "socialMedia", "socialMediaAgeRestricted", "unrestrictedWebAccess",
    "userGeneratedContent")}
attributes.update({field: "NONE" for field in (
    "alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated",
    "gunsOrOtherWeapons", "medicalOrTreatmentInformation", "profanityOrCrudeHumor",
    "sexualContentGraphicAndNudity", "sexualContentOrNudity", "horrorOrFearThemes",
    "matureOrSuggestiveThemes", "violenceCartoonOrFantasy",
    "violenceRealisticProlongedGraphicOrSadistic", "violenceRealistic")})
attributes["healthOrWellnessTopics"] = True  # Workout and self-care prompts.
request(f"/v1/ageRatingDeclarations/{INFO}", "PATCH", {"data": {
    "type": "ageRatingDeclarations", "id": INFO, "attributes": attributes}})
saved = request(f"/v1/appInfos/{INFO}/ageRatingDeclaration")["data"]["attributes"]
assert all(saved[key] == value for key, value in attributes.items())

notes = """DRAFT PREPARATION: physical-device Sandbox and Screen Time QA remain pending. Do not submit this version until those checks and the account-holder Paid Apps requirements are complete.

No app account or sign-in is required. Complete onboarding, then use Today > Body, Work or Learnt to save activity. Work needs a link or photo; typed notes and saved activities remain available without Plus. All focus timers, app blocking and timed breaks are free, without any subscription gate. Plus pays for local weekly activity analysis and next-step suggestions; it is independent of Screen Time APIs and permission.

Larpy Plus is available in Settings > Explore Larpy Plus and from the detailed-weekly-review gate. Product ID: com.vano.larpy.plus.weekly. It is a weekly auto-renewable subscription with a one-month free introductory offer for eligible subscribers. Title, local price, period and trial eligibility come from StoreKit. Terms and Privacy open Safari above the purchase action. Restore purchases is available on the paywall and in Settings.

For protected focus on a physical iPhone, authorize individual Screen Time access, select distractions, start a session, take a timed break and end the session. The app and three focus extensions are signed with Family Controls distribution. Local activity, Health workout imports and focus information stay on device. Health access is read-only; no medical advice is given.

The app has no public user-content feed, in-app messaging, analytics or advertising. Friend comparisons use explicit progress files shared through Apple's share sheet. Website links open Safari.

Support: https://vano1app-pixel.github.io/larpy-support/
Privacy: https://vano1app-pixel.github.io/larpy-support/privacy.html
Terms: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"""
contact_fields = ("contactFirstName", "contactLastName", "contactEmail", "contactPhone")
current = request(f"/v1/appStoreReviewDetails/{REVIEW}")["data"]["attributes"]
contact = {key: current.get(key) for key in contact_fields}
if not all(contact.values()):
    # Reuse this same account holder's existing Apple review contact rather than
    # inventing a phone number or asking for information Apple already holds.
    apps = request("/v1/apps?filter[bundleId]=com.vano.shrink&limit=5")["data"]
    assert len(apps) == 1
    versions = request(f"/v1/apps/{apps[0]['id']}/appStoreVersions?limit=10")["data"]
    for version in versions:
        candidate = request(f"/v1/appStoreVersions/{version['id']}/appStoreReviewDetail")["data"]["attributes"]
        if (candidate.get("contactFirstName", "").casefold() == "ayush"
                and candidate.get("contactLastName", "").casefold() == "puri"
                and all(candidate.get(key) for key in contact_fields)):
            contact = {key: candidate[key] for key in contact_fields}
            break
assert all(contact.values()), "The account holder's verified Apple review contact is required."
request(f"/v1/appStoreReviewDetails/{REVIEW}", "PATCH", {"data": {
    "type": "appStoreReviewDetails", "id": REVIEW,
    "attributes": {**contact, "demoAccountRequired": False, "notes": notes}}})
assert request(f"/v1/appStoreReviewDetails/{REVIEW}")["data"]["attributes"]["notes"] == notes
rating = request(f"/v1/appInfos/{INFO}")["data"]["attributes"]["appStoreAgeRating"]
print(json.dumps({"ageAnswers": "verified", "ageRating": rating,
                  "reviewNotes": "saved draft with pending-QA disclosure", "submitted": False}))
