# Larpy — what changed

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
