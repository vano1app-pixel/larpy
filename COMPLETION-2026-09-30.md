# Larpy — current handoff, 30 September 2026

**Delivered locally, not a connected public release.** iPhone/iPad Debug and Release builds pass; the new Mac companion builds and runs on this Apple Silicon Mac. No App Store submission, TestFlight upload, live social authentication, actual purchase or messages sent to others.

### Apple account check — 1 October 2026

The team’s existing identifiers use the `com.vano.*` namespace (`com.vano.shrink`, `com.vano.stack`). Apple rejected `com.larpy.app` as unavailable, and the account had no Larpy app record. I registered `com.vano.larpy`, `com.vano.larpy.widget`, and `com.vano.larpy.share` for the team, enabled App Groups on all three and HealthKit on the app, and updated Xcode to the team ID and those bundle IDs. The StoreKit code now uses `com.vano.larpy.afterdark2026`. No app record or purchase product has been created yet; Apple’s documentation requires creating the app record through the App Store Connect website. The new `group.com.vano.larpy` identifier still needs to be created and linked in the Developer portal before a signed widget/share build can be validated. The Developer portal currently requires an Apple Account sign-in to continue.

The current public `https://larpy.app` endpoint returns HTTP 404 `DEPLOYMENT_NOT_FOUND`. There is an in-app privacy explanation, but no live privacy-policy URL or support page with verified contact details. Apple requires a public privacy-policy URL for iOS apps and a support URL with actual contact information. App Privacy disclosures, age rating, product metadata, and the seasonal IAP record cannot yet be completed because the app record is absent. See [Apple’s app-information requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [privacy requirements](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/), and [support URL requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

### Local release audit — 1 October 2026

- Removed the obsolete wardrobe-wide €2.99 paywall code and its dead entry points. That offer contradicted the current free-progression model; only the separate optional After dark collection can be sold. Legacy earned-skin migration data remains readable.
- Rebuilt the iOS app, widget, and share extension successfully after the cleanup. This is simulator compilation evidence, not signed-device or App Store validation.
- The public domain currently has no deployed page. The developer contact address remains unverified; do not publish a personal email as a substitute.
- The app is still not release-ready: create/link the App Group, create the App Store record, publish hosted privacy and support pages, enter App Privacy disclosures and age rating, configure the IAP, request Family Controls distribution approval (only if Screen Time is pursued), verify live connector permissions, complete physical-device checks, and submit for review.

## Current product

- Today / Days / Skins. Large animated pet, walks/waves/blinks, responds to taps, optional name and Buddy / Coach / Little menace personalities. Reduced Motion and background pausing remain. Career onboarding adapts Work/Learnt prompts.
- Original scrapbook of dated outfit stamps, recent first; honest missed days, activity filters and saved details. Optional calendar connection shows the next seven days. Native event editor adds a user-confirmed 25-minute block without full access. Plans never grant rewards.
- One starter, twelve activity milestone looks (10/25/50/100 unique days for each lane), three separate 10k-platform milestones. Earned skins remain earned. More than one activity on a day cannot farm day milestones.
- Three new seasonal designs in the After dark collection: Pumpkin shift, Night shift, Spell check. Separate non-consumable `com.vano.larpy.afterdark2026`; verified StoreKit entitlement, revocation, restore and dynamic price. Preview only until the App Store product is actually available. No purchase bypasses achievement skins. Migration preserves only original legacy availability.
- Friend snapshots: explicit export/import, optional followers/token fields, same-week activity and per-tool token comparison, source dates, unknown values and removal. Self-reported files; no identity verification or live syncing. Never used to grant achievements.
- Working Mac app at `Companion/Mac/build/Larpy Desktop.app`: floating draggable animated pet, focus blocks, three voices, optional chosen-app nudges, pause/hide/quit and local-agent token sync folder picker. No screenshots/content surveillance; no login/background service. See its README for Python, platform and distribution limitations.
- Connector hub: Apple Health, Apple calendars, Codex/Claude Code via Mac, screenshot-based followers, honest TradingView journal guidance and OpenAI API capability explanation. Trading goals are process/review days, never cash-profit challenges.

## Evidence

[Current rendered screens and workflow checks](QA/2026-09-30-living/REVIEW.md). **102 checks passed**: 36 receipt, 33 progression, 15 calendar, 13 snapshot, 5 usage-sync tests. Both iOS build configurations passed and Mac launched. Real simulator save -> ten-day skin -> wear/relaunch tested; calendar add -> connect -> read tested; friend import -> optional fields -> native export -> file privacy check tested. Native Mac timer and pet responses tested. Maximum-text friend comparison verified and number wrapping fixed. StoreKit transaction, app-monitor nudge delivery and physical-device integrations remain unverified.

## Still needed for the full connected release

1. Social developer apps/permissions and a secure backend for actual LinkedIn/Instagram/X OAuth and follower refresh. Current counts are self-reported screenshots. TradingView's public REST API is for broker integrations, not a general personal-account profit connector. No unsupported account connection is faked.
2. iPhone Screen Time: Account Holder must obtain Family Controls distribution approval and configure signed app/Device Activity/Shield extensions, then test on a physical device. Larpy cannot float arbitrary UI over Instagram/TikTok. No Screen Time monitoring is implemented in this local build.
3. Automatic email/SMS: an opt-in delivery service, verified sender/domain, unsubscribe/preferences and actual backend. None exists here; no email or SMS is sent. Existing iPhone reminders are local opt-in notifications scheduled when the app opens.
4. OpenAI organisation usage: the official organisation usage endpoint requires an admin key. Consumer ChatGPT sign-in is not a token-counter connector. No organisation key was requested, stored or used; use local Codex counters now.
5. Configure/test the seasonal App Store product, agreements and signed-device purchase/refund/restore flows. Provide hosted privacy/support pages and verified developer contact. App signing Team remains unset in the repository. No Apple approval is claimed.
6. Mac public release: Developer ID/notarisation or sandboxed Mac App Store setup; bundled token-parser runtime; multi-display and notification/monitoring tests. Mac appearance/focus counts are local; phone wardrobe/account sync is not implemented.
7. Maximum text/VoiceOver and physical Health/calendar/App Group/iCloud delivery QA of the final version. Live friend sync needs a backend; files are the functioning offline exchange.

## Official references checked

- [Apple review and in-app purchases](https://developer.apple.com/app-store/review/guidelines/).
- [EventKit access](https://developer.apple.com/documentation/eventkit/accessing-the-event-store) and [iOS 17 event editor access model](https://developer.apple.com/videos/play/wwdc2023/10052/).
- [Family Controls distribution entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement) and [individual authorization](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:)).
- [TradingView API scope](https://www.tradingview.com/support/solutions/43000474413-i-need-access-to-your-api-in-order-to-get-data-or-indicator-values/).
- [OpenAI organisation usage](https://developers.openai.com/api/reference/python/resources/admin/subresources/organization/subresources/usage/methods/completions).

---

## Earlier milestone pass — historical details and evidence

# Larpy — local completion pass, 30 September 2026

Status: working local simulator build. Not uploaded to TestFlight, submitted to Apple, or connected to live social APIs.

## Delivered

- Today / Progress / Skins navigation. Today has Body, Work and Learnt actions, a next-skin goal, and a separate AI usage tracker. Settings keeps path selection, trackers, appearance, reminders and privacy together.
- First-use career selection: founder, trader, vlogger, creator, developer, designer, student or exploring. Work and Learnt prompts change with the selected path. Setup and tracker access are optional; no fake account sign-in was introduced.
- One starter skin and nine activity skins at 10 / 25 / 50 days in each lane. At most one day per lane per recorded date. Work requires a valid link or image. Learning requires a source/topic and takeaway. Body uses a 10-minute timer/imported workout or explicitly self-reported photo. This measures activity days, not verified gym attendance.
- Follower milestone skins: 10,000 LinkedIn = The networker; 10,000 Instagram = The viewfinder; 10,000 X = The broadcaster. Platforms count separately. These are original founder-inspired costumes, not named likenesses, official portraits or endorsements.
- Larger wardrobe previews and distinct blazer, camera, microphone/headphones and training details. Exact goal and progress on locked skins. Earned skins remain available after a count drops or a tracker is removed. No trial/payment gate on progression.
- Previously earned wardrobe availability is retained through a one-time migration. Old receipt JSON stays readable. New and migrated receipts preserve their local recording date so later timezone changes do not reclassify existing active days.
- Manual follower evidence stores profile name, exact count, current screenshot and update date. No provider verification is implied. Includes input limits, explicit ownership/current-count confirmation, update/remove controls, stale-data copy and protection against overwriting unreadable saved tracker data.
- Existing Mac token import and optional Apple Health connection remain. Today labels synced and manual token quantities separately when both exist because they may overlap; tokens alone cannot earn learning days.
- In-app privacy text and privacy manifests bundled with app, widget and share extension. The local activity/photo folder is excluded from backup because it can contain workout data. Device-specific HealthKit and App Group behavior still needs validation.

## Verified this session

- Simulator build of app, widget and share extension succeeded. `PrivacyInfo.xcprivacy` is present in all three built bundles.
- 36 existing receipt/compatibility checks, 29 new progression checks, five Mac usage-sync tests passed. New checks cover thresholds, duplicates, rest days, future dates, learning vs token usage, separate platforms, serialization and recorded-day stability across timezones.
- On isolated iPhone 17e simulator: chose Content creator, completed setup, opened Work, entered a clearly marked example.com QA receipt, saved it, and observed 1/10 Work days.
- Entered a QA LinkedIn count with a test screenshot. Save remained disabled until the required fields/evidence/confirmation were present. 10,000 earned The networker. Wearing it updated the character. Relaunch preserved the grant and selected skin. Lowering the sample count to 9,999 immediately refreshed the follower screen and retained the earned skin.
- The Instagram skin stayed locked, displayed `0 / 10,000 Instagram followers`, and its action opened the follower screen.
- Inspected normal iPhone layout and maximum accessibility text in dark mode; verified the follower action remained activatable. This is not a full VoiceOver or physical-device accessibility audit.
- On isolated iPad Pro 11-inch simulator: completed founder setup, checked Today and used the Skins tab. The grid adapts to the wider screen. Screenshots are in `QA/2026-09-30/`.
- Existing user simulator and its data were not replaced. QA follower data is labelled “QA sample account” and is not a real social profile or live count.

## Still required to finish the requested connected release

1. **Real social connections.** They are not implemented in this pass. This build uses screenshot-based, self-reported counts. Register/verify the developer apps and establish permitted access before promising automatic sync. LinkedIn member follower counts require Community Management access plus `r_member_profileAnalytics`. X lookup requires a developer app and authorized access. Meta's current account eligibility, app review and permissions must be confirmed; the official Instagram documentation request returned HTTP 429 during this session. No social credentials, client IDs, OAuth flows or backend exchanges were invented or embedded.
2. **Public privacy/support URLs and App Store metadata.** The in-app policy is present; a hosted policy URL and verified support contact must be supplied for submission. Audit the final live integrations and disclosures together. The old `hello@larpy.app` source constant is not evidence of a working inbox or owned domain.
3. **Signed physical-device validation.** Health permissions/denial/revocation and background delivery; Mac-to-iPhone iCloud folder delivery; real YouTube share; App Group widget/share behavior; purchase migration if a paid build has ever been distributed. The old StoreKit code remains for compatibility but no purchase is needed for the new progression route.
4. **Release archive and Apple review.** Validate signing, entitlements, privacy report, age rating, actual screenshots and review access before uploading. No Apple approval is claimed.

## Sources checked

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Required-reason APIs: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype — `CA92.1` for app defaults and `1C8F.1` for the same App Group.
- Backup exclusions: https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- LinkedIn member counts: https://learn.microsoft.com/en-us/linkedin/marketing/community-management/members/follower-statistics?view=li-lms-2026-07
- LinkedIn access overview: https://learn.microsoft.com/en-us/linkedin/marketing/community-management/community-management-overview?view=li-lms-2026-06
- X user lookup: https://docs.x.com/x-api/users/lookup/introduction

## Re-run local checks

```sh
xcodebuild -project Larpy.xcodeproj -scheme Larpy -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/larpy-milestones-build CODE_SIGNING_ALLOWED=NO build
cat Larpy/Models/ProofLog.swift Tests/ReceiptRulesChecks.swift > /private/tmp/larpy-receipts.swift
swift /private/tmp/larpy-receipts.swift
cat Larpy/Models/ProofLog.swift Larpy/Progression.swift Tests/ProgressionChecks.swift > /private/tmp/larpy-progression.swift
swift /private/tmp/larpy-progression.swift
python3 -m unittest discover -s Tests -p test_usage_sync.py
```
