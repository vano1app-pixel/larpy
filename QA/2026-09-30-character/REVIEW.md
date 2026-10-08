# Character-first Larpy — native design review

30 September 2026. Local DEBUG previews, not a released redesign.

## Brief

For someone opening Larpy to record a small piece of real progress. The character should be the first thing they notice. The next action should be obvious: Log activity → Body / Work / Learnt → existing receipt form → visible reaction and updated calendar. Preserve the original cream egg, earned cosmetics, native controls, warm palette and receipt rules. Core use remains free. No new payment option is configured.

Ayush requested a bigger central character, simple friend invitations, a calendar of missed days and small emotional touches. The Brainrot reference is treated as character-led hierarchy, not permission to build app blocking: that clarification is pending. Reference: https://apps.apple.com/us/app/brainrot-screen-time-control/id6744338972. Larpy does not implement Screen Time blocking.

## Two compositions

- **A — Your companion (recommended):** unboxed 214pt character, compared with 106pt previously. Quiet wordmark, hello/wave response, one main action. Open cream background lets the costume carry the identity. `a-companion.png`.
- **B — Larpy's room:** larger 200pt character occupying a 348pt illustrated room, with Change look placed inside the scene. More environmental atmosphere; the room still competes with the character. `b-room.png`.

The existing default Today screen remains in place. Choose a direction before replacing it and extending the design through setup, Progress, Skins and Settings.

## Working preview interactions

- Tap the companion: greeting changes to “Hey. I'm glad it's you.”, raised arms and smiling eyes. Motion respects the existing reduce-motion path.
- Log activity: a three-choice sheet leads to the real receipt form. A sample learning activity was saved on the isolated iPhone QA simulator, changing today's count from 1 to 2 and updating the calendar and next skin.
- Calendar: real month navigation, selected-day detail, active/missed counts. One activity is enough for an active day; today remains open. Dates before the first qualifying log and future dates are not missed. Counts use persisted activity date identities, preserving travel history. No skin loss after gaps.
- Invite: Apple share sheet opens with an invitation and the existing custom Larpy URL. No invitation was sent. Another installed test build is required; cross-device friend activity sync and a public install link remain unimplemented. The preview discloses this.
- Costume name opens the existing wardrobe and Settings opens existing settings.

All activity shown in screenshots belongs to isolated QA simulators, not customer metrics. The iPhone contains clearly labelled test receipts and manually supplied sample follower counts from the earlier pass.

## Files and diff scope

- `Larpy/ContentView.swift`: DEBUG home routing; make existing LogSheet visible to the preview; opt-in companion expression/arm pose. Default character calls retain their previous style.
- `Larpy/JourneyViews.swift`: DEBUG-only A/B home, calendar and invitation previews, using existing forms and stores.
- `Larpy/Progression.swift`: pure calendar status rules.
- `Tests/CalendarChecks.swift`: 12 checks for calendar boundaries, duplicate activities, DST, future activity and saved date identities.

Before-edit copies of the two UI files are in this folder. The working tree was already dirty; no prior work was reverted or committed.

## Verification

- iOS simulator build passed for app, widget and share extension.
- 12 calendar checks passed; existing 29 progression checks passed again.
- iPhone A and B rendered; iPad A rendered. Calendar selection, logging, character greeting and native invitation share sheet exercised on iPhone.
- Largest Dynamic Type inspection caught oversized header icons and a cramped main action; controls corrected. This is not a complete accessibility audit.
- No physical-device run, TestFlight upload, App Store submission, social OAuth verification or live friend sync.

## Next after selection

Promote the selected home, make the full calendar easy to reach from Progress, align the wardrobe and setup with the larger companion, and remove the old guilt-oriented copy consistently across notifications, widgets and legacy screens. Before friends can use this outside the test build, choose and implement real invitation delivery/install links and cross-device sharing. Optional StoreKit support payments should remain secondary and must not buy earned progression skins.
