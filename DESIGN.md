# Current addition — Larpy Plus, 6 October 2026

Ayush requested a one-month free trial followed by 2 per week. This supersedes the old one-time-only purchase direction. Preserve the charcoal, cream companion, native type and gold action colour. Keep logging, every focus timer, app blocking, timed breaks, saved proof, reflections and earned looks free. Plus covers local week-over-week activity comparisons and next-step suggestions. Apple Guideline 4.10 prohibits monetizing Screen Time APIs; no focus or Screen Time feature may depend on Plus.

Hide an empty Mac token counter until a usage source is connected. Today gives the companion room and keeps the three proof actions visible. The paywall names the actual features, uses StoreKit's title, billing period, price and eligible trial, and places working EULA/privacy links above purchase. Restore and cancellation remain discoverable. Never use a locally timed trial or fabricated entitlement. Expiry must not prevent ending an existing focus session or accessing saved activities.

[Implementation, rendered checks and remaining release gates](PAYMENTS-2026-10-06.md). Older release and pricing statements below are historical where they conflict.

## Current direction — 1 October 2026: dark focus by default

Dark charcoal is now the app default; preserve an explicit Light choice. The cream Larpy remains the brightest visual anchor. Put the protected-focus entry directly above the proof buttons. Setup recommends TikTok, Instagram and Snapchat, but Apple requires one-time Screen Time consent and manual app selection. Never label these apps as selected without user-selected tokens.

After setup, Today starts protected focus in one tap using the saved duration and remembered next step, with an optional generic plan if none was named. Blocking is the main path. A separate, explicit timer-only option must say that apps remain available and use a timer icon.

The dark Larpy shield offers Back to focus or Ask Larpy for a break. Returning to Larpy opens a reason + 5/10/15-minute request. Schedule background re-blocking before allowing access, bound breaks to the parent session, deduct break time from recorded focus, and retain an explicit cancel-session escape. All selected distractions become available during a break; explain this scope and that the clock starts immediately. iOS 26.5+ supports opening Larpy from the shield; earlier versions need a manual return.

## Current direction — 1 October 2026: a companion that remembers

Larpy stays the main character. Add personal recognition from saved evidence, a gentle welcome after a gap, and one remembered next step that carries into focus. Competition is secondary to that relationship: a dedicated Larp area holds the friends board; Today keeps the character and the three proof actions prominent.

Lifetime levels start at 1 and advance every 100 XP. Work earns 30 XP per qualifying day; Body and Learnt earn 10 each. Extra logs cannot farm XP. Rest does not subtract XP. Existing day-based skin requirements remain intact. Weekly friend scores compare matching Monday–Sunday windows; lifetime levels show accumulated consistency. Never describe either as measured hours or objective work quality. Friends currently exchange dated files, not live authenticated scores; show this in the interface.

The next-step note is local, optional and editable. No fake friend activity, guilt, threats to the character, invented urgency or automated messages. Give people a useful reason to return: Larpy remembers the small thing they chose to do next.

# Current addition — focus and proof, 1 October 2026

Home keeps the large companion and exposes Body / Work / Learnt directly; there is no extra activity chooser. Voice edits a draft. Work still needs a link or screenshot; focus minutes are a separate timer measure. A named focus block can shield user-selected distractions through Apple's Screen Time APIs. The shield is Larpy's annoyed face and the chosen task, with a clear way back and an early stop in the app.

Home and Lock Screen widgets show recorded activity, a missing-proof reminder and local focus time. Say “No movement logged today,” never claim to know someone skipped the gym. They do not promise continuous pet animation or instant system refresh. See FOCUS-AND-WIDGETS-2026-10-01.md for the implementation and the physical-device/release gates.

# Current direction — living companion, 30 September 2026

Larpy is a pet you build a life with: large, original egg; warm paper and ink; one gold accent; visibly moving rather than trapped in a card. Today / Days / Skins. A tap brings a greeting; walking, blinking and waving stop for Reduce Motion or backgrounding. Buddy is the default; Coach and opt-in Little menace change tone without inventing facts or attacking the person.

Days is a scrapbook of dated outfit stamps, newest first, with honest missed days and cumulative progress. Calendar events are plans, never earned activity. Users confirm new focus blocks in Apple's event editor. All calendar information stays on the device.

Achievement outfits are free and earned at 10 / 25 / 50 / 100 days per lane. Social milestones require explicitly self-reported screenshot evidence in this build. Seasonal costumes are a separate optional StoreKit non-consumable; no countdown, no fabricated price and no bypass of earned skins. The three after-dark outfits are previews until an App Store product is configured.

Friend comparison uses explicitly shared, dated files and separate sources/windows, with unknown values shown as a dash. Never fabricate friends, rankings, audience growth or token counts. Usage is not quality. Trading goals reward journals and learning, not profit or risk-taking.

The Mac companion is a floating original pet with focus timer, optional local app-name nudges and a simple local-agent sync folder picker. Monitoring starts off, has no screen/content capture and runs only during an active focus block. iPhone overlay promises are forbidden; Screen Time requires Apple's entitlement and a signed-device implementation.

See COMPLETION-2026-09-30.md and QA/2026-09-30-living/REVIEW.md for evidence and open release requirements. Everything below is historical where it conflicts.

---

# Current direction — 30 September 2026

Ayush requested career setup, progression-locked skins, follower rewards for LinkedIn / Instagram / X and a simpler app. This supersedes the older exclusions of onboarding and follower tracking below. Today has three clear actions, Progress has lifetime totals, and Skins shows exact requirements. Preserve the original egg, warm surfaces and native type; platform skins are original, without endorsement claims. See COMPLETION-2026-09-30.md.

## Previous design notes — historical

# Larpy design direction

## The direction

One picture, told at every scale: a cream egg standing on a ground line inside a rounded frame. Today draws it at 252pt, Week at 100pt, the wardrobe at 60pt, the share card and widget at their own sizes. Only receipts change the picture. A receipt changes the clothes, the room, the mouth and the one gold object on screen. Absence is drawn the same way everywhere: a dashed line where a mark should be. Gold is reserved for Work. Body and Learnt tints survive only as the 1 s wash and a filled pip. Serif headlines, one sans, mono caps at 10 to 11pt, no rounded numerals. Warm cream by default. The mentor speaks in copy; the egg stays on your side. Everything below is subtraction first, then the four swings that earn their size.

## Do first

All ten are S. Do them in one sitting, screenshot Today and Week on a real 6.1 inch phone in both themes, then put the build on TestFlight for Ayush plus one named friend before 7 Sep.

| # | Item | What | Effort | Why here |
|---|---|---|---|---|
| 1 | Delete the onboarding code | Remove OnboardingView, hasOnboarded, the colour and kit picker, peach/mist/butter. One line in CHANGES.md: "No onboarding. The first receipt is the setup." | S | Pure deletion of a decision already made twice. |
| 2 | Every empty state states the gate | Row hints become the rule. 'LARPING' replaces 'all costume' under a bare egg. | S | Copy is design. Fixes the first tap being a rejection. |
| 3 | The rejection is the lesson | Warm gold-wash capsule under the field, egg slumps in the sheet header. | S | Teaches the thesis with no tutorial. |
| 4 | Today loses three things | Token block out, slogan out, 'n/3 today' out. Voice line becomes the headline. Seven-segment week strip. Share hidden at 0/3. | S | The loudest element measured the lane the app roasts. Work lands above the fold. |
| 5 | Seed rooms by lane count | Two-line change in forToday, sets reordered light first. | S | Biggest variety gain for zero drawing. Makes the room bank unnecessary. |
| 6 | First three voice lines and the midnight line | Keyed to receipt count, not day of year. | S | The only lines a person is guaranteed to read. Serves the second open. |
| 7 | The verdict replaces 'Ask an agent' | One sentence from counts under the week row. | S | Removes the only AI surface, its key and its disclosure duty. |
| 8 | Last receipt line, duplicate-URL nudge, one moment per session | 'LAST WORK · TUE · VANO.IE', 'Already counted. New link?', a session boolean before invite > icon > widget. | S | Fixes a silent rejection and a verified bug where invite and icon fire together. |
| 9 | Tomorrow's one thing | One inline serif line, stored as tomorrowIntent, also Friday's bet. | S | The investment half of the loop. One field, never a list. |
| 10 | Finish the character that is half built | Wire posture, bodyTone, growScale and bubble. Re-key the four near-identical greys. | S | Finishing the last thing before the next. |

Second tier, only after a second phone has a receipt on it: Send to witness, the Week frame row, the wardrobe contact sheet, Work-first tiles, Friday Tape, the widget doors.

## Character

Ship now. Wire the four dead LifeEngine fields exactly as emitted: posture .upright sets tilt 0 and feet 0.02w wider apart; .sofa lowers the egg 0.05h and turns feet out 25 deg; bodyTone multiplies arm width (0.14w x bodyTone); growScale scales the actor from the .bottom anchor; the bubble draws its existing lines. Re-key 0x929591, 0x9A9A8C, 0x8D9093 and 0xA09D90 so no two adjacent looks share a kit and a colour within ΔE 10. Ids unchanged. Screenshot the grid before and after. Rename every look id to a neutral kit-and-scene slug before any shared file or WidgetSnapshot carries founderID.

After one week of Ayush's own use, add four expressions, not six. Dials (eyes, brows, mouth, arms, blush, tilt), transitions 0.28 s ease-out, one accessibility label each:

| State | Trigger | Eyes | Brows | Mouth | Arms | Blush | Tilt |
|---|---|---|---|---|---|---|---|
| asleep | 0 lanes after 21:30 or emptyStreak ≥ 2 | closed CurveLines bend 0.30 | none | 0.15 | -12 | 0.46 | -4 |
| waiting | 0 lanes, daytime | scaleY 1.12, highlight raised | bend 0.45, inner ends up 12 deg | -0.05 | -12 | 0.46 | -2 |
| fed | 1 or 2 lanes (1 lane: mouth 0.12) | 1.0 | none | 0.72 | -28 | 0.72 | 0 |
| proud | Work landed or 3/3 | scaleY 0.55 | none | 0.85, 0.15w wide | -58 | 0.85 | 0, y-scale 1.03 |

Brows: one CurveLine per eye, 0.09w x 0.02w at y -0.135h, ink 0.9, stroke max(1, 0.012w), dropped below 40pt. Waiting pose, if Ayush softens the shame rule (question 1): 0.96 y-scale, -2 deg, feet up 0.035h and rotated out 30 deg. No glance idle, no new asleep trigger until he decides. Keep the shared proud stretch on a Work receipt: arms to -60 over 0.25 s, hold 0.7 s, settle 0.4 s, under the squash.

## Scenes

Ship now. forToday seeds by the count of completed receipts in that lane this week, not the look index. Sets light first: Body [summit, road, field, gym]; Learnt [cabin, racks, platform, diner]; Work [rooftop, sea, spotlight, floor, neon]. forLook stays untouched. Store sceneID on ProofLog at write time; old records fall back to forLane seed 0. DayDetail shows the room title in 10pt mono muted under the date. Week discs and the widget sky band wait for a second phone.

Later, one line only: a daypart tint over panel(), dawn #F0A46A at 0.16, dusk #C4593A at 0.20, night #101828 at 0.42 (0.22 in dark theme so stacked overlays stay under 0.5). No lane bias, no stars, no crossfade. The sun on rooms that have one sits at 0.5 with nothing logged and returns to 0.72 on the first receipt, 600 ms.

Held: the room bank. Build only if rooms still repeat after the seed fix, and then three per lane at most. Same primitives, middle 45% empty, one accent each. Shutter fill on the dock dropped to 0.30. Whiteboard white 0.55, stopped at pw*0.80. One title renamed so no film shares it.

| Room | Lane | Sky top / bottom | Land | Accent |
|---|---|---|---|---|
| Pool at six | Body | #DCEBEA / #F1E9D6 | #E6DCC6 | #35A8B5 |
| The pitch under lights | Body | #2F3546 / #4A4B55 | #4E8A5C | #F2E6A0 |
| Stairwell, floor nine | Body | #F1E4D2 / #E6CDB0 | #B9977A | #E0603A |
| Bridge at dawn | Body | #F4DDC3 / #E9B48F | #8F7A6A | #E76F3C |
| Lamp on the shelf | Learnt | #EFE6D3 / #E5D6BC | #A6845E | #3F8F6B |
| Tape on the whiteboard | Learnt | #F3EFE6 / #EAE3D5 | #C9C1B3 | #E04B4B |
| Server hum at 2am | Learnt | #1E2426 / #283033 | #1A1F21 | #7ED957 |
| Loading dock | Work | #F5DEBB / #E8BF93 | #9A7B62 | #E2582F |
| The demo table | Work | #F4EEE3 / #EADFCD | #C8B49A | #C4A35A |
| Launch pad, wind up | Work | #2B2F45 / #4C405A | #514B4A | #F0A03C |

## Today

Header, height 44: left 'SAT 6 SEP · 2/3 IN' in 11pt mono semibold tracking 2, date muted, count in text colour, 'NOTHING IN' at zero. Right: share (only when todayCount ≥ 1, 200 ms fade, none under Reduce Motion) and gear, 44x44, 17pt symbols, muted. Moon toggle is question 3.

Headline is Voice.line: 26pt serif medium, tracking -0.8, left, two lines, minHeight 60. Delete 'Keep Larpy alive.' and the centred 14pt line. Before the bank is enabled, grep every line: under 56 characters, no real person, no film.

Tokens move to the Learnt subtitle: '184k tokens' 12pt medium muted, tap still prefills. Never above the scene.

Week strip: seven segments, height 6, gap 3, corner 3, gold for completed Work, line colour otherwise, three 1pt ink notches at 1, 3 and 7 in the same [2,2] dash rhythm as the empty indicators. '3 out this week' 13pt semibold left, 'NEXT AT 7' or 'EARNED' 10pt mono muted right, level title 10pt mono tracking 1.4 muted below. Delete 'n/3 today'. No animation.

Indicators: Body and Learnt dashed ink 0.5 when empty, ink check when logged. Gold appears on the Work row and the strip only. Type: drop .rounded everywhere; one mono style, 10pt medium tracking 1.6, for every caption.

Work sheet: on appear call UIPasteboard detectPatterns for .probableWebURL; when a valid ReceiptRules.webURL is found show a 40pt gold chip 'Use copied link · site.com' above the field, never a placeholder. Sheet top rule gold on Work, line colour on Body and Learnt. No long-press, no detent change.

After a second phone: Body and Learnt as two 76pt tiles, Work as one 84pt gold row with a 36pt ink 0.12 '+' circle, page padding 24, total 642pt.

## Week, People, Wardrobe

Verdict, under the week row, 20pt serif in muted ink. Friday 12:00 to Sunday: '{daysAlive} of 7 days had receipts. {workN} shipped. {holes} still larping.' Monday to Thursday: '{daysAlive} of {daysSoFar} so far. {workN} shipped.' Delete the agent button. The agent path is deleted or lives in Settings beside its key with a disclosure line. No hidden gesture.

Dedup: gear on Today only. Remove the 'Your characters' card; a 13pt gold 'Looks' link sits beside 'Share today'. Tab label 'Witness' as one constant (question 3). Keep SF Symbols for now.

Achievements become one row of three 28pt gold pins using the exact pin path from LarpyCharacterView, earned solid, unearned line outline, 11pt mono labels FIRST PROOF, OUT THERE, REPEAT OFFENDER, wrapping on narrow phones. DayDetail receipts lose their card backgrounds: a 3pt lane-tint left rule, 12pt inset, photo max 200, link 13pt, annotation serif, time 10pt mono. LinkedIn milestones stay put.

Week row, after sceneID ships: seven plain frames of about 100pt using MovieScene.panel with the stored look and room, no paging, no sprockets, pips and initials as now. Draw at 0.6 opacity and 0.6 saturation so the row reads as one warm strip. Past empty days: kit room at saturation 0.15, opacity 0.6, 1.5pt dashed ink border, 'NO RECEIPT'. Future days: card colour with the same border.

Contact sheet, after Ayush has ten looks: three-column LazyVGrid, spacing 6, tiles 108pt, character width 60 on a 4pt ground strip in the look's land colour, no card backgrounds, no labels. Locked looks are the existing character at 0.18 opacity with no scene. The next look gets a 1.5pt dashed gold ring and 'NEXT' 9pt mono. Header: '12' 72pt serif tracking -3 beside 'OF 54 LOOKS' 11pt mono tracking 2, then 'One look per receipt, in order. Only Work changes the level.' Verify stripe and buttons read at 375pt; offset rows if not.

Story card, only after the existing card has been posted to a Story once, and then as the only format: 360 x 640 at 3x, ground line 0.62h, actor 210, 83pt clear top and bottom, 'LARPY / RECEIPT EDITION' 10pt mono at y 96, date top right, paper band from 0.70h with 28pt top corners holding '{n} out in the world this week.' 30pt serif, 8pt pips, footer '{LEVEL} · {NAME or LARP MAXING}'. Text ink or #F5F0E6 by sky luminance under 0.5. Give panel() an explicit height and ground ratio. Render on demand.

## Recurrence

Tomorrow's one thing: after the third lane lands, or from a text button after 20:00. Inline under the headline, 17pt serif, placeholder 'Tomorrow's one thing', a hand-drawn gold underline (one Path, two off control points, 1.5pt, drawn once), commit via a drawn arrow in a 32pt gold circle. 60 characters, no newlines. Next day it fills the caption slot in 12pt serif italic with a 5pt gold dot; after any receipt it becomes 10pt mono muted strikethrough; cleared at the following midnight; tap opens Work with the text as note. After 18:00 with no Work: 'You said the deck. Where's the deck.' Friday uses the same record with placeholder 'What ships by Friday?'

Last receipt: 'LAST WORK · TUE · VANO.IE' 10pt mono tracking 1.4 muted on the NEXT AT row, host in text colour. Same host typed again: button reads 'Already counted. New link?'. Monday: headline 'New week. Costume's back on.' until the first Work; the level pin fades to a 1pt gold outline and fills with the wash on the first Work; the level title reads last week's tier until Monday 00:00.

Return door, after 3 or more days with no receipt: sofa posture in the kit's room, caption '5 DAYS. 0 RECEIPTS.', voice 'Sofa era. One thing and it ends.', Work row full, Body and Learnt collapsed to one 40pt row at card colour 0.4 with no stroke reading 'Body · Learnt' with two pips, '+' still works. First receipt expands with 220 ms ease-out and the wash. Never 'Nothing logged this week.'

Friday Tape, S version, once Ayush has seen one Friday: top card on Today, corner 28, line stroke, 'FRIDAY TAPE · W36' 10pt mono tracking 2. Three 44pt numbers (Work, Body days, Learnt days) against last week, labels muted mono with a tinted pip, delta chip 11pt mono gold when up, muted when down, never red. Verdict 27pt serif: 'Up two.' / 'Same as last week.' / 'Down one.' / 'Week one. Nothing to beat yet.' Bet field is tomorrowIntent. 'Seal the tape' 44pt gold capsule, 'Skip' text. Next Friday prints 'Bet: landed' only from a manual 'That was it' tap, else 'Bet: still a thought.' Entrance 12pt slide with opacity, 260 ms, fade under Reduce Motion. Week window is question 2.

Send to witness, after the friend is named: after a Work receipt, once a day at most, and on the Tape, a 14pt gold text button 'Send to {witness}' that ShareLinks the card with '{n} out this week.' Success is three replies in seven days. No paste-their-card.

Widget, after the App Group runs on a signed device: medium shows three Link rows to larpy://log/body, /learn, /work, labels ink and muted mono, dashed ink pip when empty, filled lane tint when done, gold capsule at 0.18 on the missing lane only, bottom line 'LAST: WED · VANO.IE'. Small: face, the missing lane in 11pt mono bold ('BODY?' before 12:00, 'WORK?' after 18:00, else first empty), ships in 9pt. Timeline entries at 00:00, 12:00, 18:00 so the face slumps at 18:00 without Work. Dark variant from Palette tokens.

Notifications, two lines: skip the Work ping when Work is logged; after three unanswered pings cancel scheduling and show 'Larpy went quiet after three unanswered pings. Turn him back on.' Clamp 06:00 to 21:00.

## Payment

Nothing is built. The model goes into NEXT.md under 'Price: off until' and stays off until ten strangers who have not shipped have Larpy on TestFlight and five are still logging on day 14 without being reminded. Then the Paid Applications agreement, tax, bank and Small Business Program. TestFlight cannot measure willingness to pay; a conversation is the only instrument.

| Rule | Value |
|---|---|
| Product | One non-consumable, com.larpy.app.larp, 'The larp' |
| Price | EUR 9.99 once, USD 9.99 equalised; about EUR 6.90 net after 23% VAT and the 15% rate |
| Free period | 30 days from the first eligible receipt, stored in ProofStore JSON |
| Day 31 without entitlement | nextLook holds, forToday falls back to forKit, orbit stays locked, extra icons hidden |
| Never touched by payment | face, voice, level, WeekStats, WidgetSnapshot, badge, notification scheduler, ShareCard, InviteView, People, DayDetail |
| Level zero | No price anywhere. Caption: 'Ship one thing. Then we'll talk about costumes.' Restore stays visible |
| Notice | 'WARDROBE OPEN UNTIL 3 OCT' 11pt mono muted, one place, from day 23. A date, not a countdown |
| Subscription | Rejected: no ongoing cost, guideline 3.1.2, the paywall becomes a contract |
| Prerequisites | Hosted terms and privacy pages; look ids renamed before costumes are sold |

Ship one sentence now under Settings: 'Receipts live on this phone. Deleting the app deletes them.'

Ask screen, pushed not presented, reached only from the paused wardrobe card and Settings, never automatic:

- Headline 32pt serif: 'Thirty days. {receipts} receipts.'
- Second line 20pt serif muted, by level: 'First proof. That's rarer than you think.' / 'Repeat offender. Keep going.' / 'Real enough. Dress the part.'
- Body 14pt: 'The ledger stays free. Logging, history, the week, the widget, the share card, your witness. Forever. The costume doesn't.'
- Under the character: the user's real receipt strip, not stat tiles.
- Button, gold, 56pt: 'Keep the wardrobe · {price} once'
- Under it, 12pt: 'One payment. It never renews.'
- Link, 14pt text colour: 'Not now. Receipts still count.' After this the app never pushes the screen again.
- Footer 10pt mono, 44pt hit height: 'Restore purchase' · 'Terms' · 'Privacy'.
- Paused wardrobe card caption: 'NEXT LOOK · {price} ONCE'. Count line: '12 of 54 looks earned. Wardrobe paused.'

Do not move look earning to Work-only for the sake of a paywall that does not exist.

## Feedback

Two rows in Settings after Notifications, hidden until the first completed Work receipt. 'Rate Larpy', subtitle 'Leave a receipt on the App Store.', opens the write-review deep link; hidden until an App Store ID exists. 'Ask for something', subtitle 'One line. It gets read.', opens a prefilled Mail compose (ShareLink fallback) to a dedicated address, subject 'Larpy', body one blank line then a mono block 'v1.1 (14) · iOS 17.5 · 9 days used · 11 Work · 3/7 this week'. No Want model, no codes, no ledger. Ayush replies by mail. TestFlight testers are told in the invite message to use Send Beta Feedback.

One session boolean, momentFiredThisSession, checked before invite, icon and widget in that order, plus never on a day with zero receipts. Existing stored flags stay honoured.

Week two: on the first receipt day of the second calendar week, Voice.line reads 'Week two. Still here.' once. No stat about other people. Nothing asked.

## Onboarding

Day zero, while logs.isEmpty: hide the stats block, the bar and the Body and Learnt rows. Stage unchanged. Caption 'BARE. ZERO RECEIPTS.' Headline slot shows 'Show me the thing.' Level title 'LARPING' with 'FIRST PROOF AT 1'. One muted 12pt line under the Work row, 'Body and Learnt count too. Only Work changes the level.', toggles the rows with a plain fade. Hints, permanent: Body 'Photo, or a 60-second timer.' Learnt 'Token count, or a link and what it's for.' Work 'A live link or a screenshot. Words don't count.' (check Larger Text; fall back to 'A sentence won't count.'). People sub-line: 'For now, send them the card.'

Voice, first three receipts: one Work 'Out in the world. Now the next one.'; one Body 'Body's in. The product's still a rumour.'; one Learnt 'Loaded. Where does it go.'; two without Work 'Two receipts. Neither left the building.'; two with Work 'Second receipt. Now it's a pattern, not a mood.' First open of a new day after a receipt day with nothing yet: 'Yesterday's receipt expired at midnight.', a per-day flag stored as a date string.

Rejection: text that fails ReceiptRules.webURL shows, 700 ms after the last keystroke and never on empty, a 13pt ink line on a 0.12 gold-wash capsule directly on the sheet surface: 'A sentence isn't a receipt. Paste the link or attach a screenshot.' Then 'Save to Learnt instead' below it. The sheet-header egg takes the hungry pose over 300 ms and recovers when the text validates. Learnt with no use line: 'What is it for. One line.' Duplicate URL: 'Already counted. Ship the next thing.'

First receipt: delete the InviteView and IconOfferView triggers from receiptLanded(). After the squash and sticker, one 44pt gold pill 'Screenshot this. Send it to one person.' ShareLinks the existing card with footer 'DAY ONE · FIRST PROOF · {host}' ('SCREENSHOT' for an image). No join link, no clothing wipe, no post-share sheet. Pill stays until the share sheet has opened once or the day ends.

Tail card: delete the WidgetCardView trigger. After the first receipt, one inline card under the rows, card colour, line stroke, corner 18, padding 18: 'He's hungry again at midnight.' 18pt serif; 'Put him on the Home Screen so you see it before I say it.' 13pt muted; face and count drawn straight on the card; 'Hold the Home Screen · + · Larpy' 13pt; 'Later' once, no return. Notification toggle stays in Settings. Icon chooser moves to Settings with no gate.

## Not doing

- Hatch line on the shell: first visible pixel arrives at 10 Work; revisit when someone other than Ayush has ten.
- Per-kit idles: four idles nobody sees in a 20 s session; only the proud stretch survives.
- Three new kits and accessories: more content for a wardrobe with zero earned looks. Delete or hide the dead glasses/cap/cans cases.
- Props in hand: eleven drawings that fail at 82pt; the card stays consistent instead.
- Shared face across widget and share card: wrong order; sign the device, freeze the character, then share one file.
- Twelve rooms now: the seed fix removes the repetition; the bank above is held.
- Lit window: streak already exists in LifeState and is already said on screen.
- Lifetime reward rooms: nobody has reached orbit.
- Weather from state: a fourth signal on the hungry state; the sun rule survives as one line.
- Seasonal rooms: a calendar of receipts for an app with two days of them.
- Rooms shelf: a gallery to admire inventory.
- Sky to the edge: L effort, 14 skies by two themes, cards inside cards, no viewer yet.
- Friday two-up frame: a leaderboard with a win history and a silhouette placeholder until sync.
- Rooms as their own collection: prints a lane rule the code does not enforce.
- Receipt-timed pings: a personalisation engine that changes nothing under three receipts; two lines survive.
- Body timer Live Activity: pulls a 'later' item ahead of its prerequisite and logs Body with no proof.
- StoreKit, Ask screen, countdown, Purchase section: spec written, price off.
- Shippers don't pay: a second call to action on a one-button screen; question 4.
- Earned question, Landed ledger, replies feed, Name the next room: tools built to avoid five text messages.
- System review prompt: a popup by another name; user-initiated row instead.
- First-receipt ceremony with post-share sheet and join link: a popup by another route to an app nobody can install.
- Midnight undressing: ship the voice line first and wait for a tester to say the second morning felt flat.

## Open questions for Ayush

1. Hungry: LARPY.md says shame and visible empty days; the character angle says waiting, not punishment, plus asleep after 21:30, which NEXT.md's 'closed-eye idle' ban touches. Which one?
2. The week: LARPY.md scores Friday and calls rank a friends leaderboard; NEXT.md bans leaderboards. Is the week Monday to Friday close or Monday to Sunday, and is any two-person comparison ever allowed?
3. Three reversals of your own recent choices: the moon toggle out of the header, the People tab renamed 'Witness', and Body and Learnt tints reduced to ink except the wash and filled pips. Yes to each?
4. Money, when it exists: Family Sharing on or off (cannot be changed later), and 'larpers pay, shippers don't' as a public rule or not.
5. Who is the witness? One name, before the Send button is built.

## What the critics said was missing

- The second human. Nobody but Ayush has opened Larpy. One-friend sync has topped NEXT.md for three handovers and no angle touched it. Every share card sent this week invites someone to an app they cannot install. TestFlight to Ayush plus one friend before 7 Sep is the only test that matters.
- India, 7 to 25 Sep. Nothing built now can be tried on a signed device for three weeks, which kills the widget and any App Group work for that window.
- The pattern he asked to be named: fourth app-shaped thing in six days while the podcast pipeline sits at 0 of 5 with nobody contacted in seven days. Say it once.
- Real names live in the code as look ids and costume cases, and every receipt stores them as founderID. Rename to neutral slugs before any shared file, snapshot or sale.
- Three saturated lane colours and four type voices on one screen were inherited by every angle without being named.
- Dark theme was never rendered: ink 0.35 hairlines, silhouettes, dashed borders and stacked overlays all need a dark check at 125pt.
- Accessibility: expression labels, VoiceOver on Canvas faces and stage sequences, Dynamic Type on serif fields, 44pt hits on 10pt mono links.
- No previews. The process rule is two or three named directions with screenshots on a real device; every fit claim here is arithmetic.
- No hand-crafted detail beyond the one gold underline: no grain, no uneven stroke in the furniture. Clean geometry is the AI tell.
- No measurement. Local-only, no analytics; 'the loop works' is a claim until receipts per week and second-week return are counted by hand.
- Unsourced psychology stats in the rationales must never reach copy or the App Store listing.
- Bible conflicts were resolved quietly instead of flagged: shame versus waiting, Friday versus Sunday, 2-of-3 lanes versus one Work, Body by photo versus a 60 s timer, the money plan.
- ContentView.swift is 3,400 lines and every proposal lands in it.
