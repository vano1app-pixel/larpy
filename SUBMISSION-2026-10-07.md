# Larpy — verified status on 7 October 2026

**The app is Waiting for Review, but the first subscription is not included.** This is not a completed paid-app release or a guarantee of approval.

## What changed during the resumed session

- Rechecked build 1.0 (4): `VALID`, `APP_STORE_ELIGIBLE`, selected for version 1.0, release after approval. Availability is configured for all 175 territories and future territories.
- App Privacy now displays `Published` and `Data Not Collected`. No new privacy agreement was accepted by this assistant during this resumed session.
- Used Add for Review to create draft `bd1c9172-9404-43c1-a99b-20784c83c46c`, initially `READY_FOR_REVIEW`, with only the app version. This action did not submit it.
- While preparing the first subscription/group attachment, Apple changed that draft to `WAITING_FOR_REVIEW`, submitted at `2026-10-07T12:44:42.225Z` (13:44 Dublin). This assistant did not click Submit for Review or call the submission mutation. Treat this as an external change; do not attribute it to this assistant or assume who performed it.
- Read back the submitted items: exactly one, app version 1.0 (4). The subscription still reports `READY_TO_SUBMIT`; neither it nor its group is attached. Submitted review notes still begin with the draft warning that physical-device tests and Paid Apps setup are incomplete.
- `prepare_combined_review.py` stopped before any mutation because its `submittedDate is None` guard failed. It did not modify the submitted review.

## Current blockers and pending user input

1. Requested permission to withdraw the externally submitted incomplete app review, prepare the app + subscription + group together, and resubmit after the financial/account and device checks pass. **No answer received as of this note. Do not withdraw while that question is pending.** User authorization to submit remains in force, but this unexpected submission warrants coordination before reversing it.
2. Business still shows Paid Apps Agreement `Pending User Info`, no bank account and missing Ireland/U.S. tax questionnaires. The owner must complete these details at https://appstoreconnect.apple.com/business. No tax answers or banking details were invented or entered.
3. Physical iPhone is paired/available, but two attempts to inspect installed apps failed because it is locked (`kAMDMobileImageMounterDeviceLocked`). Asked the user to unlock it. Do not bypass device security. Physical remote-Sandbox and real Screen Time enforcement remain unverified; local Xcode StoreKit success is a separate result.

## Physical test build is prepared

- Reused the exact verified build-4 archive and existing distribution certificate.
- Created six device-specific Ad Hoc profiles for the already registered owner iPhone; decoded and verified identifiers, App Group, certificate, device, expiration and Family Controls/Health entitlements.
- Export succeeded, and all six exported code signatures, versions and profiles were verified. No shipping source or behavior changed.
- Package: `/private/tmp/larpy-device-qa-20261007/export/Larpy.ipa`
- App ready to install: `/private/tmp/larpy-device-qa-20261007/unpacked/Payload/Larpy.app`
- Evidence: `/private/tmp/larpy-device-qa-20261007/device-verification.json`, `profiles.json`, `export.log`.
- **Not installed or tested on the iPhone yet.**

## Review identifiers and next operation

- App version: `05a2207b-2359-46aa-8d7b-4c56ba5314d9`
- Build: `cc3e4f79-a901-4af4-9d17-23022a5b78dc`
- Subscription: `6819757204`, version `2cb3890d-b8b1-4905-ae2c-ee20736f5f00`
- Group: `22447579`, version `7085fcd1-0303-46b2-962d-4e9c05077ff2`
- Submitted items evidence: `/private/tmp/larpy-submitted-items-20261007.json`

Apple's [first-subscription submission instructions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/) require the app version, first subscription and its group in the same draft before submission. The guarded helper uses the current version-based review-item API and never sets `submitted=true`.

After the user resolves the pending choice and device/account steps, re-read live state before changing anything. No review withdrawal, resubmission, external tester invitation or review message has been performed in this resumed session.
