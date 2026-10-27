# Current release status — 27 October 2026

**Build 7 uploaded and processed VALID; not publicly released.** Progress now reuses one summary per render and the companion pauses animation when hidden. 230 Swift checks and five Python tests pass; simulator saving, history, week navigation, outfit preview, unavailable Plus offer and free-timer cancellation were checked. All six archive signatures and required entitlements verify.

Apple rejected build 6 because the subscription did not load on iPad. The authenticated Business page shows Paid Apps Agreement **Pending User Info**, missing tax information, banking processing and a new developer agreement needing account-holder acceptance. Build 7 is now installed and launches on the owner's iPhone, with version readback verified. Physical-device Screen Time and remote Sandbox purchases remain unverified. The four local purchase tests failed in StoreKit test-service setup, so no current purchase-test pass is claimed. See [release evidence and remaining gates](RELEASE-2026-10-27.md).

## Previous release history

# Current release status — 7 October 2026

**App 1.0 (4) is Waiting for Review; Larpy Plus was not included.** App Privacy is published. An external submission occurred while the first subscription/group attachment was being prepared. Permission to withdraw and correct it is pending, along with owner bank/tax and physical-device checks. The exact build is signed and ready to install on the connected iPhone once it is unlocked. See [current submission status](SUBMISSION-2026-10-07.md).

## Previous preparation — 6 October 2026

Larpy Plus adds detailed weekly activity reviews and next-step suggestions. Daily logging, saved activities, all focus timers, app blocking, timed breaks, reflections and earned outfits stay free. This follows Apple Guideline 4.10, which prohibits monetizing Screen Time APIs. Apple has a draft weekly subscription with a one-month introductory trial, then EUR 2.00/week in Ireland and Apple-equalized prices elsewhere. The app displays prices and trial eligibility from StoreKit.

**Verified:** 205 Swift checks and five Python tests pass. Manual Xcode StoreKit purchase, restore and refund work. All six distribution signatures/profiles verify, including Screen Time. Corrected build **1.0 (4)** uploaded and Apple processed it as **VALID**; the internal QA group, test notes and release draft are prepared. Public [support](https://vano1app-pixel.github.io/larpy-support/) and [privacy](https://vano1app-pixel.github.io/larpy-support/privacy.html) pages are live. **Still required:** physical-iPhone Sandbox and app-blocking checks, remaining device/layout QA, account-holder bank/tax setup and the final review packet. No App Review submission or public release. See [current submission status](SUBMISSION-2026-10-06.md) and [payment evidence](PAYMENTS-2026-10-06.md).

## Historical project overview

# Larpy — current local build

An animated companion for Body, Work and Learnt. iPhone/iPad: Today, scrapbook Days, achievement Skins, optional calendar planning, follower evidence and explicit friend snapshots. Optional After dark costumes use StoreKit; core progression stays free.

**Local status:** built and tested on isolated simulators and this Mac. Not submitted, uploaded or Apple-approved. Social OAuth, iPhone Screen Time, production friend sync and email/SMS delivery remain unconnected. See [completion and evidence](COMPLETION-2026-09-30.md).

**Mac pet:** open `Companion/Mac/build/Larpy Desktop.app`. Rebuild with `bash Companion/Mac/build.sh`; Apple Silicon, macOS 14+, Python 3 for optional token sync. Monitoring is opt-in each launch. Use the menu-bar face to show/hide the pet or quit. Details in [Mac README](Companion/Mac/README.md).

## Earlier project notes

# Current local build — 30 September 2026

Larpy now has career-based prompts, Today / Progress / Skins, activity-day skin rewards and 10k follower milestones for LinkedIn, Instagram and X. Social counts are currently manual with screenshots; automatic social connections are not implemented. [Verified changes and release requirements](COMPLETION-2026-09-30.md).

## Earlier project overview

# Larpy

Become the person. Bring receipts.

Native SwiftUI iOS app with three moves: **Body / Learnt / Work**. A cream egg changes into founder-inspired looks as you log; only completed Work with a link or screenshot advances the weekly level.

- Today, Week, People
- 54 bundled founder-inspired costume looks
- Local proof storage and photo evidence
- Learning share extension and Home Screen widget
- One-friend invite preview; live sync is not connected

See [CHANGES.md](CHANGES.md) for the product decisions, implementation, checks and known limits.

Build:

```sh
xcodebuild -project Larpy.xcodeproj -scheme Larpy -sdk iphonesimulator -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

Receipt checks:

```sh
cat Larpy/Models/ProofLog.swift Tests/ReceiptRulesChecks.swift > /tmp/larpy-rules.swift
swift /tmp/larpy-rules.swift
```
