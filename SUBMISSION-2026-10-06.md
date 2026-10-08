# Larpy submission status — 6 October 2026

**Not submitted or live.** The user authorized App Review submission and publication after approval. The corrected version is 1.0 (4), selected in the editable App Store draft. Automatic release after approval is selected. Apple's final Add for Review check currently stops on the unpublished App Privacy declaration.

## Completed and verified

- Build 4 is `VALID`, `APP_STORE_ELIGIBLE` and `READY_FOR_BETA_TESTING`. Apple build ID: `cc3e4f79-a901-4af4-9d17-23022a5b78dc`. Internal QA assignment, test notes and draft build selection were read back. No invitation was sent; automatic tester notifications are disabled.
- Signed archive and all six bundled targets verified. Main app and three focus extensions carry Family Controls distribution. App Group, version/build, HealthKit and privacy purpose keys verified. Build and upload logs, signed archive and `testflight-verification.json` are in `/private/tmp/larpy-release-20261006-build4/`.
- Apple Guideline 4.10 prohibits monetizing Screen Time APIs. Removed the subscription gate from all focus timers, app blocking and timed breaks. Plus covers local weekly comparisons, summaries and next-step suggestions. Do not submit build 3, which still gated protected focus.
- Subscription is one week, with a one-month free introductory offer for eligible subscribers, then EUR 2.00/week in Ireland. StoreKit supplies localized title, period, price and eligibility. Other territories use Apple's configured equalized prices. Restore and Safari legal links are on the paywall. No account was added.
- Corrected paywall, onboarding/settings, subscription description, App Store description, review notes and support page. Public support/privacy URLs return successfully; support commit `67e5154` is live.
- Focus rules (38) and weekly-review rules (12) passed again after the scope correction. The broader previous pass was 205 Swift checks and five Python tests. Final simulator build and archive passed. `git diff --check` and helper syntax checks passed.
- Current iPhone and 13-inch iPad home/focus screens were inspected. The free timer starts and labels apps available. The rebuilt Xcode StoreKit paywall shows the weekly review benefits, localized EUR 2.00 price and legal links above purchase. This used an already-trialled test account, so no free-trial offer was displayed.
- Real simulator screenshots in `QA/2026-10-06-review/` were uploaded without fabricated UI. Native PNGs were converted to JPEG to remove alpha. iPhone: 1320×2868; iPad: 2064×2752. All four storefront screenshots are `COMPLETE`; corrected subscription review screenshot `4ab24ece-4e8a-4a7e-982c-0f582dcb2022` is also `COMPLETE`.
- Productivity category, free download pricing, original-content answer, age rating, review contact, public support/privacy and standard Apple EULA are saved. The displayed iOS 26 rating is 9+ in most territories; the API's legacy rating is 4+.

## Remaining owner and device steps

1. **Paid Apps Agreement:** Business shows `Pending User Info`, no bank account, and missing Ireland and U.S. tax questionnaires. The owner must supply financial/tax details. Apple requires an active Paid Apps Agreement before IAP submission. https://appstoreconnect.apple.com/business
2. **App Privacy:** `Data Not Collected` is drafted based on the source audit: data is processed locally; no app server, analytics or advertising SDK is used. The final Publish dialog asks the owner to agree that the information is accurate, follows Apple's rules and applicable laws, and will be updated. Publication remains pending explicit confirmation. https://appstoreconnect.apple.com/apps/6819279029/distribution/privacy
3. **Physical iPhone QA:** remote Sandbox loading, eligible trial purchase, immediate entitlement, restore after reinstall, pending/cancellation/expiry and real Screen Time shields, timed break/re-block/end remain unverified. Local Xcode StoreKit purchase/restore/refund passed earlier, but that is not remote Sandbox proof. The automated StoreKit test harness failed with `SKInternalErrorDomain Code=3`; do not count it as a pass. Health/share/widgets and maximum text sizes still need the final device pass.
4. Once those steps pass, replace the draft-pending wording in review notes with factual tested instructions, add the app version, first subscription and subscription group to the same review submission, and submit. Verify `WAITING_FOR_REVIEW` before announcing submission. Submission, approval and public availability are distinct states.

## Apple references

- [Guideline 4.10](https://developer.apple.com/app-store/review/guidelines/#monetizing-built-in-capabilities)
- [Paid Apps Agreement requirements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements)
- [First subscription submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/)

Approval on the first attempt cannot be guaranteed. No customer purchase, subscriber count, retention or revenue is established by this preparation.
