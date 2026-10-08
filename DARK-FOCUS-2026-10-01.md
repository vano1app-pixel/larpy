# Dark default and protected focus — 1 October 2026

## Shipped in local source

- Dark charcoal is the default for an unset appearance preference. Existing explicit Light choices remain respected. Body/Learnt button foregrounds now stay readable on dark surfaces.
- The focus action sits above proof logging. After Screen Time approval and app selection, it starts protected focus immediately using the saved 15/25/50-minute duration and the remembered next step. A task name is optional. Blocking is the primary path; timer-only use is an explicit secondary option with honest labels and a timer icon.
- First setup recommends TikTok, Instagram and Snapchat. The system picker requires users to select apps once; no fabricated or preselected opaque app tokens.
- Shield: dark backdrop and original annoyed Larpy. Back to focus closes the distraction. Ask Larpy for a break records a session-bound request and uses Apple's openParentalControlsApp on iOS 26.5+. Older systems explicitly direct the user to open Larpy manually. The shield action never grants access.
- Break request: reason of 3–140 trimmed characters, 5/10/15-minute choice, explicit disclosure that all selected distractions become available. The wall clock starts immediately, and a break cannot outlive focus. A new DeviceActivity monitor must schedule successfully before shields are cleared.
- DeviceActivity requires a minimum 15-minute schedule, so shorter breaks use intervalWillEndWarning; a 15-minute break uses intervalDidEnd. Both restore the saved shields only for the current session's latest matching break. App foreground refresh also restores expired breaks. A late callback cannot target a different session or break.
- Early return restores blocking immediately, shortens recorded break time and stops that break's monitor. Explicit End focus confirmation remains available. Adding proof itself no longer silently disables protection.
- Completed and expired focus totals exclude breaks, including splits across midnight. Breaks never earn XP or Work proof. Older focus-session files continue to decode. Widget timelines include break expiry and show the break countdown separately.
- Revoked authorization clears invalid app-selection tokens and ends a protected session; users must choose apps again. Privacy copy now explains local break reasons, scope and timing.

## Verification

- Final signed simulator build: **BUILD SUCCEEDED**. Log: /private/tmp/larpy-breaks-build.log. App, monitor, shield, action, widget and share extensions compile.
- **193 passing checks**: 38 focus/break/persistence/midnight checks, plus 155 existing level, receipt, skin, calendar, sharing and widget checks.
- Real iPhone Simulator render inspected: dark home with prominent focus entry and readable activity controls; dark focus setup; running timer; cancellation confirmation.
- Native UI: tapped Set up app blocking and received the truthful simulator/device limitation; explicitly chose timer-only, started without typing, opened its controls, cancelled, and received no activity/XP award. No real distracting app was blocked during simulator QA.
- git diff --check passes.
- Preview: QA/2026-10-01-dark-focus/iphone-home.png and iphone-focus-setup.png.

## Required device/release verification

Screen Time distribution entitlements/signing and a physical iPhone test remain outstanding. Do not describe simulator renders, scheduling code or pure-rule checks as proof that TikTok/Instagram/Snapchat were blocked or re-blocked. Test each selected app, the 26.5 shield-to-Larpy route, the older-OS manual route, reason validation, all three break lengths while Larpy is backgrounded/terminated, early return, session end during a break, revoked permission, and stale callbacks. Apple's callback delivery is system-managed; do not market second-perfect enforcement. No App Store/TestFlight release was performed.

## Apple references checked

- https://developer.apple.com/documentation/familycontrols/familyactivityselection
- https://developer.apple.com/documentation/familycontrols/familyactivitypicker
- https://developer.apple.com/documentation/managedsettings/shieldactionresponse/openparentalcontrolsapp
- https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule/warningtime
- https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/intervalwillendwarning(for:)

The installed iOS SDK also marks openParentalControlsApp as available starting in iOS 26.5. No private APIs or bundle-ID-to-token guessing is used.
