# Living companion QA — 30 September 2026

All phone data is on the isolated Larpy Milestones QA simulator, not Ayush's original Larpy QA device. The friend and follower examples are labelled QA samples. Do not use their counts as product traction or real audience evidence.

## Visual evidence

- `iphone-home.png`: large character, visible limb/pose variation, earned Training club outfit, one primary action, pinned Work goal.
- `iphone-days.png`: final recent-first scrapbook with actual saved receipt outfits, missed-day marks and dated entries.
- `iphone-seasonal.png`: Pumpkin shift plus Night shift and Spell check, honest unavailable-product preview; no fabricated price or active checkout.
- `iphone-comparison.png`: exact imported QA sample counts; source/window/date; missing Codex usage displayed as a dash instead of zero.
- `ipad-home.png`: final iPad render with constrained main content width and usable main action.
- `mac-pet-1.png` / `mac-pet-2.png`: real NSHostingView captures from the running floating panel at distinct animation frames. No other app or screen content captured.
- `mac-controls-1.png` / `mac-controls-2.png`: real control-window render.

## Interaction evidence

- Earlier integrated pass: 9 unique sample Body dates plus a real photo-picker save earned Training club at 10; Wear it and the chosen next goal survived relaunch. See `../2026-09-30-finish/`.
- Native iOS EventKit editor presented without prior calendar access. Confirmed Save for a 25-minute local QA event. Larpy reported successful addition. Connected calendar then displayed that exact title/start time. Activity counts remained Body 10 / Work 1 / Learnt 1.
- Halloween selector renders all three distinctive outfit previews. Product unavailable state is shown. Actual purchase, pending approval, restore/refund and App Store product configuration are NOT verified.
- Imported `QA-friend-snapshot.json` through the native Files picker. Exact 3/2 Body, 0/4 Learnt and 0/3 Work-day comparisons. Opting in displayed 9,999/3,000 LinkedIn followers and unknown/50,000,000 Codex tokens, labelled QA data.
- Native export saved `Larpy-snapshot.json` locally. Parsed result matched expected activity totals, selected follower count and absent token data. No notes, links, photos or calendar events were present. See `export-check.txt`. No share was sent to another person.
- Mac focus timer started at 25:00 and counted down; End focus block stopped it. Tapping the actual floating pet changed its greeting; its button opened controls. App monitoring and notifications remain off on this host. Automatic nudge delivery is implemented but not exercised against a real distracting app.

## Build and automated verification

Debug and Release simulator builds passed for app/widget/share targets. Native arm64 macOS build passed and launched. 36 receipt checks, 33 progression checks, 15 calendar checks, 13 friend-snapshot checks and 5 Python usage tests passed: **102 total**. The first new 100-day test used an invalid photo fixture without a photo filename; correcting it to valid workout fixtures passed. `git diff --check` is clean.

- Final comparison screen checked at maximum Dynamic Type. Long token numbers initially split; accessibility rows now stack You and Friend separately. Re-rendered full 50,000,000 value without splitting (`iphone-large-text.png`). Normal QA text size restored.

## Remaining QA

Broader Dynamic Type/VoiceOver of the remaining expanded screens; fresh permission denial/revocation on signed physical devices; calendar changes while backgrounded; iCloud Mac-to-phone delivery; actual StoreKit transactions; live provider connections. Earlier accessibility and workflow screenshots are evidence only for their earlier version. No Apple review, TestFlight upload or release occurred.
