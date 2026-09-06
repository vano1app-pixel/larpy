# Larpy — what changed

## The design direction, built — 6 September 2026

Everything in DESIGN.md's "Do first" list plus the buildable parts of each section. No onboarding. The first receipt is the setup.

### Today
- Header is one mono line, `SUN 6 SEP · NOTHING IN`, with the moon, share and gear on the right. Share appears only once something is in. The tokens block and the slogan are gone; tokens live in the Learnt row's subtitle.
- The headline is the voice line, 26pt serif, left. The first three receipts get their own lines keyed to the count. Then, in order: yesterday's receipt expiring, tomorrow's one thing after 18:00 with no Work, Monday's line, week two said once, then the bank.
- Seven-segment week strip: gold where Work landed, dashed where the day has not come. `N out this week`, `NEXT AT n` or `EARNED`, the level title, and `LAST WORK · TUE · HOST`.
- Level zero is `larping`. Day zero hides the strip and the Body and Learnt rows, shows `BARE. ZERO RECEIPTS.`, `Show me the thing.`, `LARPING · FIRST PROOF AT 1`, and one muted line that opens the other rows.
- Return door after three empty days: `N DAYS. 0 RECEIPTS.`, `Sofa era. One thing and it ends.`, the Work row full, Body and Learnt collapsed to one 40pt row.
- Tomorrow's one thing: one inline serif field with a hand-drawn gold underline, offered at 3/3 or after 20:00. Next day it sits under the caption with a gold dot, strikes through after any receipt, opens Work with the text as the note, clears at midnight.
- Rows state the gate: `Photo, or a 60-second timer.` · `Token count, or a link and what it's for.` · `A live link or a screenshot.`
- After the first receipt: an inline gold pill, `Screenshot this. Send it to one person.`, until the share sheet opens once. The widget offer is an inline card with `Later`. No popups after a receipt; the invite and icon sheets no longer fire.

### Work sheet
- A sentence in the link field shows, 700 ms after the last keystroke, `A sentence isn't a receipt. Paste the link or attach a screenshot.` on a gold-wash capsule, and the small egg in the header slumps until the text validates.
- A copied link shows a gold `Use copied link` chip. Reading the clipboard happens only on that tap.
- The same site as an earlier Work receipt changes the button to `Already counted. New link?`. Still allowed.

### Character
- The four life-engine fields that were computed and never drawn now draw: upright posture stops the sway and widens the feet, sofa posture drops the egg and turns the feet out, body tone thickens the arms, grow scale scales from the feet, and the bubble draws as a small capsule.
- Four near-identical greys re-keyed so no two adjacent looks share a kit and a colour.

### Scenes
- Ten new rooms: pool at six, the pitch under lights, stairwell floor nine, bridge at dawn, lamp on the shelf, tape on the whiteboard, server hum at 2am, loading dock, the demo table, launch pad. Twenty-four rooms total, one reward.
- The room is seeded by how many completed receipts that lane has this week, light rooms first. Each receipt stores its `sceneID` at write; old receipts fall back to the lane's first room. Day detail shows the room under the date.
- One daypart tint over every room: dawn, dusk, night.

### Week, People, wardrobe
- `Ask an agent` is gone from Week. One sentence from counts replaces it. The agent key stays in Settings with a disclosure line.
- The characters card is gone; a gold `Looks` link sits beside `Share today`. Achievements are three gold pins in one row.
- Day detail lost its card backgrounds: a 3pt lane rule, the receipt, the note, the time.
- The wardrobe is a three-column contact sheet: character on a ground strip in its look colour, no labels, locked looks faint, the next look ringed in dashed gold with `NEXT`. Header `12 OF 54 LOOKS`.

### Payment, built small and switched off by the store
- One non-consumable, `com.larpy.app.larp`, fallback price €2.99 once. Thirty days free from the first eligible receipt. After that the wardrobe pauses: the next look holds, rooms fall back to the kit's room, orbit stays locked, extra icons hide. Logging, history, the week, the widget, the share card and the friend never change.
- The ask is a half-sheet: the character, `N days. N receipts.`, the level line, the person's own receipt strip, one gold button `Keep the wardrobe · price once`, `Not now. Receipts still count.`, `Restore purchase`. Reached from the paused wardrobe card and Settings only. Never automatic.
- Until a product exists in App Store Connect the button is disabled and reads `Not on sale yet. Nothing is paused until it is.` The purchase path was not exercised.

### Feedback
- Two Settings rows, hidden until the first completed Work: `Rate Larpy` (hidden until an App Store ID is set in `Feedback.appStoreID`) and `Ask for something`, which opens Mail to `Feedback.address` with the build, iOS version, days used, Work count and this week prefilled. `Feedback.address` is a placeholder and must be set before TestFlight.
- `Receipts live on this phone. Deleting the app deletes them.` under the rows.

### Removed
- OnboardingView, the `hasOnboarded` flag, the base colour picker and peach/mist/butter, the Next screens, WidgetCardView, IconOfferView, IconChoices, receiptLanded, every `.rounded` font.

### Checked
- Simulator build of app, widget and share extension: succeeded. 30 receipt-gate checks: pass.
- Running app: Today (light and dark, with the tail card), Week, Looks, Settings, the ask sheet, the rendered share card. Screenshots via the debug launch flags `-openWeek`, `-openWardrobe`, `-openSettings`, `-openAsk`, `-openShare`.
- Not checked: any purchase, the Body timer and camera paths, notifications, and anything on a signed device.

### Not built from DESIGN.md
- Friday Tape, Send to witness, the Week frame row, the 9:16 story card, the widget doors and Live Activity: second tier, all wait for a second phone or a signed device.
- The four new expressions and brows: held for a week of real use, per the plan.
- Notifications going quiet after three unanswered pings.

## Full-width scenes, lane-driven rooms, and a room you have to earn — 6 September 2026

- The stage is no longer a circle. Larpy stands in a **full-width rounded panel** that fills the
  content width, with the scene drawn edge to edge behind him. The panel takes whatever frame its
  parent gives it, and the ground line is derived from the actor's feet, so the character stands
  correctly at any size. Scene furniture is placed against the panel width, not the actor, so it
  spreads across the canvas instead of hiding behind him.
- **The lane you fed last picks the room.** Body earns the outdoors and the gym. Learnt earns the
  rooms full of other people's work. Work earns the rooms with an audience. Within a lane the look
  decides which of its rooms you get, so two receipts in the same lane do not look identical.
  `MovieScene.forToday` is the single place that decides, so Today and the share image never
  disagree, and the caption under Larpy always names the room actually on screen.
- **The share image is the scene.** The card carries the same full-width panel and the room's
  caption, on a taller canvas so nothing clips.
- **One room you cannot dress into.** `Somebody else's orbit` belongs to no costume. It shows in
  the characters screen from day one, greyed and locked with a running count, and unlocks at seven
  completed Work receipts. Once earned, logging Work again puts Larpy in it.
- Debug-only screenshot hooks: `simctl launch <sim> com.larpy.app -openWardrobe` opens the
  characters screen, `-openShare` renders the share card and writes it to Documents. Both are
  inside `#if DEBUG` and never ship.

### Checked

- Simulator build of app, widget and share extension: succeeded.
- 30 receipt-gate and compatibility checks: pass.
- Running app: the road scene on an empty day, the diner after a Learnt receipt, and the orbit
  after a Work receipt on a week already past seven. The characters screen showing the reward room
  as earned. The rendered share card, pulled off the simulator as a PNG.
- `strings` on the built binary still returns no real person's name.
- Not checked: the theme button under an automated tap, because the simulator stopped accepting
  synthetic clicks partway through. Both themes were verified by rendering, and the button writes
  the same preference the Settings picker has always used.
- The QA simulator's receipts were seeded to force those scenes and then restored from a backup.

## Today header, one-tap theme, and scenes instead of names — 6 September 2026

- The tokens number moved clear of the status bar and grew; the `tokens loaded · N pages · N lesson`
  line under it is gone, so the header is one label and one number.
- Today fits one screen again on a 6.3" phone: the Work row sits fully above the tab bar.
- A **moon / sun button in the header** flips light and dark in one tap. It writes the same
  `isDark` preference the Settings picker always used, so the two stay in sync.
- **No real person is named anywhere in the app.** The 54 looks keep their clothes and their
  colours, and their stored IDs, so earned history still resolves. What the UI shows is the
  clothes plus the scene: "Rollneck · One spot, one take". The alternate app icon is "Rollneck".
  Settings costumes are Hoodie / Rollneck / Gym tee / Collar. `strings` on the built binary
  returns no founder name.
- **Fourteen original scene backdrops** replace the flat cream disc behind Larpy: a road at dusk,
  a rain-lit street, a late booth, a rooftop, a field, a gym, a trading floor, a server aisle,
  an orbit, a summit, a spotlit stage, a platform, a snowed-in window, an open sea. They are drawn
  from scratch with the app's own shapes — no film is named, no still is reproduced, no character
  is depicted. One warm ground and one saturated accent each, so the set reads as one system.
- The stage geometry is now adaptive. `stageRatio` decides how much wider the scene circle is than
  the actor, and the ground line is derived from the actor's feet, so Today can give the scene room
  while the smaller stages in Week, Settings, onboarding and the share card keep their old framing.

### Checked

- Simulator build of app, widget and share extension: succeeded.
- 30 receipt-gate and compatibility checks: pass.
- Running app on the Larpy QA simulator: Today in light and dark, Week, and the characters grid.
- Not checked: the widget and share extension on a signed device, and any cross-phone sync.

## Direction

Larpy is the character you put on, backed by receipts. Cream paper, a living cream egg, a sharp line, three simple actions. The latest names are **Body / Learnt / Work**. “Ship” remains a verb in the voice; Work is the lane for something that left the building.

## Today

- Tokens sit above Larpy at the top left. Large, readable numbers; pages and lessons stay separate units underneath.
- Larger primary type, readable row subtitles, a serif headline, and a quieter layout.
- Work is the gold action. All three rows have large touch targets.
- Share is available at the top. The share image includes the character, tokens, all three lanes (including holes), and completed Work this week.
- First install opens Today immediately. Profile setup waits until the first receipt.
- One progress bar. Body and Learnt change the character; only evidence-backed Work changes the weekly level.

## Character and motion

- One egg-shaped cream body from the first launch: two open eyes, peach cheeks, stubby limbs. No faceless hatching stage.
- Clothing remains below the chin. Jobs' mock neck never crosses the eyes.
- Breathing, slow sway, a 400 ms blink, a small touch reaction, and a squash when a receipt lands.
- Jobs walks; Hormozi has a tally board; Belfort has a desk and phone; Cursor kid has a hoodie and laptop.
- New receipts persist a founder look ID. History remembers the look worn on that receipt.
- **54 original founder-inspired looks** are bundled in code. These are costume interpretations, not downloaded portraits, official likenesses, or endorsements.
- The collection lives in Week. Logging automatically changes the look; picking through a catalogue is never required to log.
- Motion pauses in the background and respects Reduce Motion. Still images keep both eyes open.

## The 54 looks

Steve Jobs, Alex Hormozi, Cursor kid, Jordan Belfort, Mark Zuckerberg, Jensen Huang, Sara Blakely, Sam Altman, Melanie Perkins, Patrick Collison, John Collison, Brian Chesky, Paul Graham, Jessica Livingston, Naval Ravikant, Jack Dorsey, Elon Musk, Jeff Bezos, Bill Gates, Steve Wozniak, Larry Page, Sergey Brin, Reid Hoffman, Peter Thiel, Marc Andreessen, Ben Horowitz, Tobias Lütke, Dylan Field, Ivan Zhao, Guillermo Rauch, Pieter Levels, David Heinemeier Hansson, Jason Fried, Drew Houston, Dustin Moskovitz, Stewart Butterfield, Aaron Levie, Eric Yuan, Whitney Wolfe Herd, Anne Wojcicki, Reshma Saujani, Leila Janah, Tristan Walker, Daymond John, Mark Cuban, Richard Branson, Phil Knight, Yvon Chouinard, James Dyson, Reed Hastings, Daniel Ek, Kevin Systrom, Evan Spiegel, Mike Krieger.

The details vary across garment silhouettes, muted fabric colours, glasses, stitching, collars, pockets, zips and props. Some props use simple line symbols on a held object. They are an initial illustrated wardrobe, not 54 individually animated celebrity portraits.

## Receipts

- **Body:** photo or an actual timer of at least 60 seconds. A sentence and an instant stop do not count. The active timer survives closing the sheet.
- **Learnt:** tokens, or a lesson/book/video/deck with a one-line use. Source links and annotations are both preserved.
- **Work:** a valid HTTP(S) URL or an attached image. A sentence can be explicitly saved to Learnt instead.
- Ordinary text containing a dot no longer passes as a URL. Localhost, unsupported URL schemes, and credential-bearing URLs are rejected.
- The same Work URL cannot earn another completion. Screenshot content remains self-reported; Larpy does not claim to authenticate deals or detect all duplicate images.
- Receipts append instead of overwriting the previous entry for the day. Work counts outputs, not just days with a tick.
- Saves are atomic and failures stay visible. A corrupted receipt file is protected from accidental overwrite.
- Existing Body/Learn/Work JSON names still decode. Old token-only Work records cannot give Work XP. Old Body number records without elapsed-time evidence remain stored but do not count as timer proof.

## Learning from the share sheet

Choose Larpy in another app's share sheet, then **Log learning**. A URL can be filed without opening Larpy. There is an optional “what are you using this for?” line.

The input is kept in the shared App Group and imported when Larpy opens. Images are held as drafts so the user can choose Learnt or Work. Cancelled drafts stay available. No unsupported responder-chain app-opening trick remains.

The extension was built successfully. A real YouTube-to-Larpy test on a signed physical device remains necessary; the YouTube app is not installed in the simulator.

## Week and achievements

- Today, Week and the widget use the same Monday-to-Sunday completed-Work count.
- The 0 / 1 / 3 / 7 weekly states are **all costume / first proof / repeat offender / real enough**.
- Week keeps the three lane holes and the saved founder look. Opening a day shows all receipts, their sources, images, annotations and times.
- Lifetime achievements: first proof, first completed Work, seven completed Work receipts.
- LinkedIn milestones: **1k / 10k / 100k followers**, requiring a count and screenshot. Labelled **self-reported**, not verified by LinkedIn. They add no Work XP.
- LinkedIn evidence stays on this device. No LinkedIn OAuth, scraping, or remote verification was added.

## People

- One friend, one invite button, a short explanation.
- Your two-field profile opens separately. The receiving code form appears only when asked for.
- The first receipt offers one witness. Invites are prepared with the system share sheet; no messages were sent during development.
- Unknown friend activity is displayed as unknown. It is not turned into a fake “you didn't do the Work” claim.
- **Cross-phone receipt sync is not connected.** Invite codes and profile links are local preview hooks, not a working social backend.

## Widget, icons, settings

- The widget uses a cream egg with open eyes and tiny limbs, fed/hungry state, lanes and the weekly count.
- Yesterday's lane completion clears at midnight; the weekly count clears at the next week boundary.
- Default / Hungry / Jobs alternate icons remain available. They are user-selected; the app no longer automatically swaps icons underneath a choice.
- Dark mode uses charcoal chrome and a cream spotlight around Larpy.
- API tokens for “Ask an agent” remain in Settings and are tracked separately from human tokens. Unclassified old totals aren't claimed as model spend.
- No Screen Time APIs, surveillance, fourth lane, leaderboard, or multi-friend feed.

## New voice lines

1. Your ambition called. It wants evidence.
2. Main character. Missing scene.
3. The idea can't screenshot itself.
4. Dress the part. Then do the part.
5. Your launch is still a rumour.
6. Homework has a receipt. Your product doesn't.
7. Inputs are full. The exit is empty.
8. Nice load. Where's the payload.
9. You fed the brain. Feed the market.
10. The research phase has a door. Use it.
11. It exists. Now make it matter.
12. One less thing trapped in your head.
13. A receipt looks good on you.
14. You earned the screenshot.
15. The costume finally has a witness.

These rotate within receipt-appropriate states. No app usage or watch history is inferred.

## Validation

- Full Xcode simulator build: app, widget extension, share extension.
- 30 executable checks for URL gates, proof eligibility, old JSON compatibility, annotation persistence and LinkedIn thresholds.
- Separate “Larpy QA” simulator used for sample receipts. The original simulator's existing receipts were preserved.
- Running-app check: a Work URL increased the weekly count from 7 to 8 and changed the character to Patrick Collison.
- Running-app check: logging 1k tokens changed the character to John Collison and the token total from 184k to 185k; completed Work stayed at 8.
- Running-app check: `Worked on it.` in the URL field left Work saving disabled.
- Screenshots in `QA/` are labelled sample states; they are not claims about Ayush's real activity.

## Still to connect / verify on device

1. One-friend cross-device sync and a real universal-link domain.
2. Apple developer team, App Group capabilities and signing for all three targets.
3. Real YouTube share-sheet round trip; physical camera, photo picker, Home Screen widget and alternate-icon behaviour.
4. No App Store, TestFlight or production release was made in this session.
