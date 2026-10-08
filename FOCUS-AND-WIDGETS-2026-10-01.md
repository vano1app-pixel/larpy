# Larpy: focus, quick proof and widgets

Local implementation, 1 October 2026. Not an App Store or TestFlight release.

## Product brief

Someone doing a workout, finishing a project or learning something should be able to add the evidence immediately. The character remains the first thing they see; Body / Work / Learnt are the three direct actions beneath him. Warm paper, ink, gold and the original egg remain the visual language. Voice lowers typing effort without weakening the evidence requirements.

The focus loop is: name one outcome → optionally shield selected distractions → start a short block → attach the result. A countdown is a commitment, not an earned Work day. Widgets carry the same honest reminder outside the app.

## Implemented

- Home: removed the extra activity chooser. Three directly labelled proof buttons and a persistent focus entry. Existing Health / local AI usage / calendar connections are linked under Connections.
- Voice: Body and Work notes, learning takeaways and focus intentions accept optional on-device dictation. Request permissions only on tap; stop when the view closes, the app backgrounds or audio is interrupted. No audio saved, no network fallback. Users review the resulting draft. Denied/unavailable recognition leaves typing available.
- iPhone focus: 15 / 25 / 50 minutes, named outcome, persistent end time. Timer-only works without Screen Time. Protected focus requests individual authorization, presents Apple's private app/category/domain picker, schedules a Device Activity monitor, then applies a named Managed Settings shield. Early stop clears only Larpy's shield. Schedule failure applies no shield.
- Shield: original locally drawn annoyed Larpy, chosen task, end time and Back to focus button. A Shield Action extension closes the shielded app in response to that button. No screen reading, app-content capture or invented distraction counts.
- Expiry: monitor clears the shield even when Larpy isn't foregrounded. Session-specific activity names prevent an old callback from finishing a newer block. Completion is deduplicated by session ID. Work proof is still required after a timer.
- Mac: opt-in Put distracting apps away hides specifically chosen apps after 3 seconds during focus and briefly gives the pet annoyed brows. It does not terminate apps or close documents. Finder, System Settings and loginwindow are excluded. This is a voluntary guard, not a hard lock. Off at every launch. Existing nudges and local Codex / Claude Code usage sync remain.
- Widgets: small/medium Home Screen and Today View; circular/rectangular/inline Lock Screen. Saved activity checkmarks, missing-proof reminder, completed focus minutes and an active countdown. Wider widgets link separately to Body / Work / Learnt; active countdown opens focus controls. Countdowns stop at zero. Midnight resets yesterday's checkmarks. Focus minutes are explicitly timer time, not verified work.
- Settings: Home & Lock Screen guide, current-data previews using the same artwork as the real widgets, installed-widget count, updated voice/focus privacy text.

## Verification

- iOS app, widget, share extension, monitor, shield configuration and shield action: simulator builds succeeded, including locally signed builds with App Group entitlements.
- 36 existing receipt compatibility/gate checks pass.
- 15 new focus checks pass: invalid intervals, persistence, duplicate completion, early cancellation, midnight allocation, expired timer-only sessions and corrupt data.
- 10 widget checks pass: old snapshot decoding, empty arrays, midnight freshness, honest focus wording and deep-link routing.
- Real iPhone simulator: three direct proof actions; focus start; timer survives terminating/reopening app; early end opens prefilled Work draft; Save stays disabled until a link is attached; saving a clearly labelled QA link earns exactly one Work day. Speech denial shows a usable typing fallback. Screen Time simulator limitation is explicit.
- Real Home Screen widget installed in QA simulator. After locally signing the simulator build, the widget reads the app's saved Work checkmark. Tapping Body opens the Body evidence screen. Gallery small/medium previews inspected. A narrow preview label-wrap issue was corrected.
- Real iPad home inspected; all three actions, focus, calendar and progression remain visible. The saved screenshot is in the simulator's portrait-upside-down orientation.
- Mac build succeeded. Its updated pet and controls were rendered and captured; actual app hiding remains unverified because native UI automation repeatedly stalled.
- Screenshots: `QA/2026-10-01-focus/iphone-home.png`, `iphone-homescreen-widget.png`, `ipad-home.png`, `mac-pet-2.png`, `mac-controls-2.png`. Simulator activity shown is QA data.

## Remaining device/release gates

1. Enable/register the App Group and Family Controls capabilities for the actual developer account and sign a physical-device build. Request Family Controls distribution approval for `com.vano.larpy`, `com.vano.larpy.focus-monitor`, `com.vano.larpy.focus-shield`, and `com.vano.larpy.focus-action`.
2. On a physical iPhone, check individual permission granted/denied/revoked, selected apps and domains, category shields, end while app is killed/asleep, timezone/day changes and early stop. Simulator checks cannot establish these.
3. Test real microphone capture in a supported on-device language, interruption and offline recognition. Permission denial was tested; actual speech accuracy was not.
4. Install Lock Screen widgets on a physical phone, including Always On/tinted rendering. The layouts compile and share the tested snapshot/artwork; this simulator's editor did not expose a usable installation flow. Apple controls refresh timing, so no instant-refresh promise.
5. Exercise Mac hiding with a disposable selected app, re-opening, pause/end and multi-monitor behavior. Sign/notarize the Mac app before public distribution.

The unsigned simulator build does not share App Group snapshots across app and widget. Use `CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO` for this local simulator QA; it is not a substitute for physical-device signing or Apple distribution approval.

## Sources checked

- [Family Controls capability](https://developer.apple.com/documentation/familycontrols)
- [Distribution entitlement request](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement)
- [Managed Settings shields](https://developer.apple.com/documentation/managedsettings/shieldsettings)
- [Shield appearance](https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration)
- [On-device recognition](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition)
- [Widget refresh limits](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date/)
- [Adding Home and Lock Screen widgets](https://support.apple.com/en-euro/118610)
- [macOS hide operation](https://developer.apple.com/documentation/appkit/nsrunningapplication/hide%28%29)
